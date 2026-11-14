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

/// What the list of debts shows (ADR 0029): who owes the person, whom the
/// person owes, and the debts that are settled.
@immutable
final class DebtsState {
  /// Creates a state of [today].
  const DebtsState({
    required this.status,
    required this.today,
    this.debts = const [],
    this.base = Currency.rub,
    this.rates = const RateBook.empty(),
  });

  /// Where the list stands.
  final DebtsStatus status;

  /// Today on this device.
  final CivilDate today;

  /// Every debt that has anything to show.
  final List<Debt> debts;

  /// The currency of the totals.
  final Currency base;

  /// The rates that turn other currencies into [base].
  final RateBook rates;

  /// The open debts that others owe the person: the nearest day first.
  List<Debt> get owed => _open(DebtSide.lent);

  /// The open debts that the person owes: the nearest day first.
  List<Debt> get mine => _open(DebtSide.borrowed);

  /// The settled debts, the latest first.
  List<Debt> get closed => debts.where((debt) => debt.closed).toList()
    ..sort(
      (a, b) => _laterFirst(a.closedOn, b.closedOn),
    );

  /// What others owe the person in [base], or `null` while a rate is
  /// missing.
  Money? get owedTotal => _sum(owed);

  /// What the person owes in [base], or `null` while a rate is missing.
  Money? get mineTotal => _sum(mine);

  /// What [debt] has left in [base], when it is in another currency.
  Money? inBase(Debt debt) =>
      debt.currency == base ? null : rates.convert(debt.left, base);

  /// Whether an open debt is in a currency other than [base].
  bool get hasOtherCurrencies =>
      [...owed, ...mine].any((debt) => debt.currency != base);

  /// Whether there is no debt to show.
  bool get isEmpty => debts.isEmpty;

  /// The debt [id], when it is among [debts].
  Debt? debt(String id) => debts.where((debt) => debt.id == id).firstOrNull;

  List<Debt> _open(DebtSide side) =>
      debts.where((debt) => !debt.closed && debt.side == side).toList()
        ..sort((a, b) {
          final byDay = _soonerFirst(a.dueOn, b.dueOn);
          return byDay != 0 ? byDay : _laterFirst(a.since, b.since);
        });

  Money? _sum(List<Debt> debts) =>
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
      other.base == base &&
      identical(other.rates, rates) &&
      _same(other.debts, debts);

  @override
  int get hashCode =>
      Object.hash(status, today, base, rates, Object.hashAll(debts));
}

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
  final _subscriptions = <StreamSubscription<Object?>>[];
  List<Debt>? _debts;
  RateBook _rates = const RateBook.empty();
  Currency? _base;
  var _baseRead = false;
  Currency? _main;

  void _failed(Object _) {
    if (isClosed) return;
    emit(DebtsState(status: DebtsStatus.failed, today: state.today));
  }

  void _update() {
    final debts = _debts;
    if (debts == null || !_baseRead || isClosed) return;
    emit(
      DebtsState(
        status: DebtsStatus.ready,
        today: _repository.today(),
        debts: debts,
        base: _base ?? _main ?? Currency.rub,
        rates: _rates,
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
