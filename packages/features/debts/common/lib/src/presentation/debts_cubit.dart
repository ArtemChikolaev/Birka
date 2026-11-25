import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:debts_common/src/domain/debt.dart';
import 'package:debts_common/src/domain/debts_repository.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Where a list of debts stands.
enum DebtsStatus {
  /// The first read has not come back yet.
  loading,

  /// Everything is here.
  ready,

  /// Something could not be read.
  failed,
}

/// The due dates included in the debt list.
enum DebtDueFilter {
  /// Every date, including debts without a deadline.
  all,

  /// Today or earlier.
  due,

  /// Tomorrow through the seventh day from today.
  week
  ;

  bool _includes(Debt debt, CivilDate today) {
    switch (this) {
      case all:
        return true;
      case due:
        return debt.isDue(today);
      case week:
        final date = debt.dueOn;
        if (date == null) return false;
        final days = today.daysUntil(date);
        return days >= 1 && days <= 7;
    }
  }
}

/// What the list of debts shows (ADR 0029): who owes the person, whom the
/// person owes, and the debts that are settled.
@immutable
final class DebtsState {
  /// Creates a state of [today].
  const DebtsState({
    required this.status,
    required this.today,
    this.filter = DebtDueFilter.all,
    this.debts = const [],
    this.people = const [],
    this.base = Currency.rub,
    this.rates = const RateBook.empty(),
  });

  /// Where the list stands.
  final DebtsStatus status;

  /// Today on this device.
  final CivilDate today;

  /// The selected scope of the list. A debt card can open any debt by ID.
  final DebtDueFilter filter;

  /// Every debt that has anything to show.
  final List<Debt> debts;

  /// The people of the debts (ADR 0030).
  final List<Person> people;

  /// The person of [debt], once the people are read.
  Person? personOf(Debt debt) =>
      people.where((person) => person.id == debt.personId).firstOrNull;

  /// The currency of the totals.
  final Currency base;

  /// The rates that turn other currencies into [base].
  final RateBook rates;

  /// The open debts that others owe the person: the nearest day first.
  List<Debt> get owed => _open(DebtSide.lent);

  /// The open debts that the person owes: the nearest day first.
  List<Debt> get mine => _open(DebtSide.borrowed);

  /// The open debts on each side matching the selected due dates.
  List<Debt> get visibleOwed => _open(DebtSide.lent, filter: filter);

  /// The open debts the person owes within the selected dates.
  List<Debt> get visibleMine => _open(DebtSide.borrowed, filter: filter);

  /// The settled debts, the latest first.
  List<Debt> get closed => debts.where((debt) => debt.closed).toList()
    ..sort(
      (a, b) => _laterFirst(a.closedOn, b.closedOn),
    );

  /// What others owe the person in [base], or `null` while a rate is
  /// missing.
  Money? get owedTotal => totalOf(owed);

  /// What the person owes in [base], or `null` while a rate is missing.
  Money? get mineTotal => totalOf(mine);

  /// What [debt] has left in [base], when it is in another currency.
  Money? inBase(Debt debt) =>
      debt.currency == base ? null : rates.convert(debt.left, base);

  /// Whether any visible open balance needs conversion to the base currency.
  bool get hasOtherCurrencies => debts.any(
    (debt) =>
        !debt.closed && debt.currency != base && filter._includes(debt, today),
  );

  /// Whether there is no debt to show.
  bool get isEmpty => debts.isEmpty;

  /// The debt [id], when it is among [debts].
  Debt? debt(String id) => debts.where((debt) => debt.id == id).firstOrNull;

  List<Debt> _open(DebtSide side, {DebtDueFilter filter = DebtDueFilter.all}) =>
      debts
          .where(
            (debt) =>
                !debt.closed &&
                debt.side == side &&
                filter._includes(debt, today),
          )
          .toList()
        ..sort((a, b) {
          final byDay = _soonerFirst(a.dueOn, b.dueOn);
          return byDay != 0 ? byDay : _laterFirst(a.since, b.since);
        });

  /// The outstanding amount of [debts] in the base currency.
  Money? totalOf(List<Debt> debts) =>
      rates.sum(debts.map((debt) => debt.left), base);

  static int _soonerFirst(CivilDate? a, CivilDate? b) {
    if (a == null || b == null) return a == null ? (b == null ? 0 : 1) : -1;
    return a.compareTo(b);
  }

  static int _laterFirst(CivilDate? a, CivilDate? b) {
    if (a == null || b == null) return a == null ? (b == null ? 0 : 1) : -1;
    return b.compareTo(a);
  }

  @override
  bool operator ==(Object other) =>
      other is DebtsState &&
      other.status == status &&
      other.today == today &&
      other.filter == filter &&
      other.base == base &&
      identical(other.rates, rates) &&
      _same(other.debts, debts) &&
      _same(other.people, people);

  @override
  int get hashCode => Object.hash(
    status,
    today,
    filter,
    base,
    rates,
    Object.hashAll(debts),
    Object.hashAll(people),
  );
}

/// Counts a person once across currencies. A legacy debt without a person
/// counts separately, even when its account ID matches another person's ID.
int peopleInDebts(List<Debt> debts) => {
  for (final debt in debts) (debt.personId != null, debt.personId ?? debt.id),
}.length;

bool _same<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Follows the debts, the rates and the currency of the totals.
final class DebtsCubit extends Cubit<DebtsState> {
  /// Creates the cubit on [_repository].
  DebtsCubit(this._repository)
    : super(
        DebtsState(status: DebtsStatus.loading, today: _repository.today()),
      ) {
    _subscriptions.addAll([
      _repository.watchDebts().listen((debts) {
        _debts = debts;
        _update();
      }, onError: _failed),
      _repository.watchPeople().listen((people) {
        _people = people;
        _update();
      }, onError: (Object _) {}),
      _repository.watchRates().listen((rates) {
        _rates = rates;
        _update();
      }, onError: (Object _) {}),
      _repository.watchBaseCurrency().listen((base) {
        _base = base;
        _baseRead = true;
        _update();
      }, onError: (Object _) {}),
      _repository.watchMainCurrency().listen((main) {
        _main = main;
        _update();
      }, onError: (Object _) {}),
    ]);
  }

  final DebtsRepository _repository;
  Timer? _midnight;
  final _subscriptions = <StreamSubscription<Object?>>[];
  List<Debt>? _debts;
  List<Person> _people = const [];
  RateBook _rates = const RateBook.empty();
  Currency? _base;
  var _baseRead = false;
  Currency? _main;

  /// Changes the date scope without changing the ledger.
  void selectFilter(DebtDueFilter filter) {
    if (isClosed) return;
    _update(filter: filter);
    _scheduleMidnight();
  }

  /// Refreshes the civil day when the app or browser tab is shown again.
  void calendarChecked() {
    if (isClosed) return;
    if (state.today != _repository.today()) _update();
    _scheduleMidnight();
  }

  // Keep an open filtered list current overnight. On resume, recompute the
  // next local midnight in case the clock or the time zone changed.
  void _scheduleMidnight() {
    _midnight?.cancel();
    if (state.filter == DebtDueFilter.all) return;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(tomorrow.difference(now), calendarChecked);
  }

  void _failed(Object _) {
    if (isClosed) return;
    emit(
      DebtsState(
        status: DebtsStatus.failed,
        today: state.today,
        filter: state.filter,
      ),
    );
  }

  void _update({DebtDueFilter? filter}) {
    final debts = _debts;
    if (debts == null || !_baseRead || isClosed) return;
    emit(
      DebtsState(
        status: DebtsStatus.ready,
        today: _repository.today(),
        filter: filter ?? state.filter,
        debts: debts,
        people: _people,
        base: _base ?? _main ?? Currency.rub,
        rates: _rates,
      ),
    );
  }

  @override
  Future<void> close() async {
    _midnight?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
