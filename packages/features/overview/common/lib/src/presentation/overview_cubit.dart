import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:overview_common/src/domain/capital.dart';
import 'package:overview_common/src/domain/overview_repository.dart';
import 'package:overview_common/src/domain/spending.dart';
import 'package:rates/rates.dart';

/// Where the first screen stands.
enum OverviewStatus {
  /// The first read has not come back yet.
  loading,

  /// Everything is here.
  ready,

  /// Something could not be read.
  failed,
}

/// What the first screen shows.
@immutable
final class OverviewState {
  /// Creates a state.
  OverviewState({
    required this.status,
    required this.today,
    this.period = ChartPeriod.month,
    this.accounts = const [],
    this.changes = const [],
    this.spendingRows = const [],
    this.rates = const RateBook.empty(),
    this.base,
    this.monthStart = 1,
  });

  /// Where the screen stands.
  final OverviewStatus status;

  /// The day of today.
  final CivilDate today;

  /// How far back the chart looks.
  final ChartPeriod period;

  /// The accounts in everyday use with their balances.
  final List<AccountBalance> accounts;

  /// What each day of the last year changed.
  final List<DayChange> changes;

  /// What went through each category on each day of this month.
  final List<CategoryDayTotal> spendingRows;

  /// The kept exchange rates.
  final RateBook rates;

  /// The currency picked for totals, if one was.
  final Currency? base;

  /// The day of the calendar that a month starts on (ADR 0024).
  final int monthStart;

  /// The first day of the month of today.
  CivilDate get month => today.monthStart(monthStart);

  /// What the accounts come to.
  late final Capital capital = Capital.of(accounts, rates: rates, base: base);

  /// The capital in the currency that the chart follows.
  Money? get main => capital.main;

  /// The amounts that no rate can turn into [main] yet.
  List<Money> get others => capital.others;

  /// The capital at the end of each day of [period], in minor units of [main].
  late final List<int> history = _history();

  /// How much [main] changed over [period].
  late final Money? change = _change();

  /// The spending of the month, with each amount at the rate of its own day.
  late final Spending spending = Spending.of(
    totalsIn(main?.currency, spendingRows, rates),
    preferred: main?.currency,
  );

  List<int> _history() {
    final main = this.main;
    if (main == null) return const [];
    return capitalHistory(
      now: main,
      changes: changes,
      rates: rates,
      start: period.startFrom(today, monthStart: monthStart),
      today: today,
    );
  }

  Money? _change() {
    final main = this.main;
    if (main == null) return null;
    final change = Money(
      (history.last - history.first).clamp(
        -Money.maxMinorUnits,
        Money.maxMinorUnits,
      ),
      main.currency,
    );
    return capital.converted ? change.roundedToWhole() : change;
  }

  /// A copy with the given fields changed. [base] takes a function, so it can
  /// also become `null`.
  OverviewState copyWith({
    OverviewStatus? status,
    CivilDate? today,
    ChartPeriod? period,
    List<AccountBalance>? accounts,
    List<DayChange>? changes,
    List<CategoryDayTotal>? spendingRows,
    RateBook? rates,
    Currency? Function()? base,
    int? monthStart,
  }) {
    return OverviewState(
      status: status ?? this.status,
      today: today ?? this.today,
      period: period ?? this.period,
      accounts: accounts ?? this.accounts,
      changes: changes ?? this.changes,
      spendingRows: spendingRows ?? this.spendingRows,
      rates: rates ?? this.rates,
      base: base == null ? this.base : base(),
      monthStart: monthStart ?? this.monthStart,
    );
  }
}

/// Follows what the first screen shows in the local database.
class OverviewCubit extends Cubit<OverviewState> {
  /// Creates the cubit and starts to follow. [now] tells the time in tests.
  OverviewCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(
        OverviewState(
          status: OverviewStatus.loading,
          today: CivilDate.of((now ?? DateTime.now)()),
          monthStart: _repository.monthStart(),
        ),
      ) {
    _follow();
  }

  final OverviewRepository _repository;
  final DateTime Function() _now;
  List<StreamSubscription<void>> _subscriptions = const [];
  final _arrived = <Object>{};

  /// How many sources the screen waits for.
  static const _sources = 5;

  /// Sets how far back the chart looks.
  void periodChanged(ChartPeriod value) => emit(state.copyWith(period: value));

  /// Reads everything again after a failure.
  Future<void> retry() async {
    final cancelled = _cancel();
    emit(state.copyWith(status: OverviewStatus.loading));
    _follow();
    await cancelled;
  }

  /// Catches up with the calendar after a night in the background, since the
  /// month and the history both end today.
  Future<void> calendarChecked() async {
    final today = CivilDate.of(_now());
    if (today == state.today) return;
    final cancelled = _cancel();
    emit(state.copyWith(today: today));
    _follow();
    await cancelled;
  }

  void _follow() {
    final today = state.today;
    _arrived.clear();
    _subscriptions = [
      // A new day for the months reads the month again from that day.
      _repository.watchMonthStart().listen((day) {
        if (day != state.monthStart) unawaited(_monthStartChanged(day));
      }),
      _listen(
        _repository.watchAccounts(),
        (accounts) => state.copyWith(accounts: accounts),
      ),
      _listen(
        _repository.watchDayChanges(from: ChartPeriod.earliest(today)),
        (changes) => state.copyWith(changes: changes),
      ),
      _listen(
        _repository.watchSpending(from: state.month, to: today),
        (rows) => state.copyWith(spendingRows: rows),
      ),
      _listen(
        _repository.watchRates(),
        (rates) => state.copyWith(rates: rates),
      ),
      _listen(
        _repository.watchBaseCurrency(),
        (base) => state.copyWith(base: () => base),
      ),
    ];
  }

  Future<void> _monthStartChanged(int day) async {
    final cancelled = _cancel();
    emit(state.copyWith(monthStart: day, spendingRows: const []));
    _follow();
    await cancelled;
  }

  /// Follows [source]. The screen is ready once every source has spoken, so
  /// that it never shows a capital without its history or its rates.
  StreamSubscription<void> _listen<T>(
    Stream<T> source,
    OverviewState Function(T) update,
  ) {
    final key = Object();
    return source.listen(
      (value) {
        _arrived.add(key);
        final next = update(value);
        emit(
          _arrived.length == _sources
              ? next.copyWith(status: OverviewStatus.ready)
              : next,
        );
      },
      onError: (Object _) {
        // Stays out until it speaks again, so that the others cannot hide it.
        _arrived.remove(key);
        emit(state.copyWith(status: OverviewStatus.failed));
      },
    );
  }

  Future<void> _cancel() =>
      Future.wait(_subscriptions.map((subscription) => subscription.cancel()));

  @override
  Future<void> close() async {
    await _cancel();
    return super.close();
  }
}
