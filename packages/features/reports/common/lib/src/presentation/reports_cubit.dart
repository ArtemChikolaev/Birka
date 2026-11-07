import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:reports_common/src/domain/report.dart';
import 'package:reports_common/src/domain/reports_repository.dart';

/// Where the reports stand.
enum ReportsStatus {
  /// The first read has not come back yet.
  loading,

  /// Everything is here.
  ready,

  /// Something could not be read.
  failed,
}

/// What the reports show.
@immutable
final class ReportsState {
  /// Creates a state.
  ReportsState({
    required this.status,
    required this.today,
    required this.month,
    this.kind = CategoryKind.expense,
    this.preferred,
    this.base,
    this.rates = const RateBook.empty(),
    this.days = const [],
    this.monthStart = 1,
  });

  /// Where the reports stand.
  final ReportsStatus status;

  /// The day of today.
  final CivilDate today;

  /// The first day of the month on the screen.
  final CivilDate month;

  /// Expenses or income.
  final CategoryKind kind;

  /// The currency of the first account that counts.
  final Currency? preferred;

  /// The currency picked for totals, if one was.
  final Currency? base;

  /// The kept exchange rates.
  final RateBook rates;

  /// What went through each category on each day of the last months.
  final List<CategoryDayTotal> days;

  /// The day of the calendar that a month starts on (ADR 0024).
  final int monthStart;

  /// The first day of the month of today.
  CivilDate get current => today.monthStart(monthStart);

  /// The currency that the report follows.
  Currency? get _target => base ?? preferred;

  /// The report of [month], with each amount at the rate of its own day
  /// (ADR 0009).
  late final Report report = Report.of(
    month: month,
    rows: totalsIn(_target, _daysFrom(month, lastDayOf(month)), rates),
    previousRows: totalsIn(
      _target,
      _daysFrom(monthsBefore(month, 1), _endOfComparison),
      rates,
    ),
    monthTotals: monthTotalsIn(_target, days, rates, monthStart: monthStart),
    preferred: _target,
  );

  /// Whether a rate stands behind any amount of [month].
  bool get converted {
    final target = _target;
    return target != null &&
        _daysFrom(month, lastDayOf(month)).any(
          (row) =>
              row.total.currency != target &&
              rates.canConvert(row.total.currency, target),
        );
  }

  List<CategoryDayTotal> _daysFrom(CivilDate from, CivilDate to) => [
    for (final row in days)
      if (row.day.compareTo(from) >= 0 && row.day.compareTo(to) <= 0) row,
  ];

  /// The last day of the month before [month] to compare with. A month still
  /// under way takes as many days as it has had, or else it would always start
  /// far below the whole month before it.
  CivilDate get _endOfComparison {
    final before = monthsBefore(month, 1);
    final last = lastDayOf(before);
    if (month != current) return last;
    final same = before.addDays(month.daysUntil(today));
    return same.compareTo(last) < 0 ? same : last;
  }

  /// A copy with the given fields changed. [preferred] and [base] take a
  /// function, so they can also become `null`.
  ReportsState copyWith({
    ReportsStatus? status,
    CivilDate? today,
    CivilDate? month,
    CategoryKind? kind,
    Currency? Function()? preferred,
    Currency? Function()? base,
    RateBook? rates,
    List<CategoryDayTotal>? days,
    int? monthStart,
  }) {
    return ReportsState(
      status: status ?? this.status,
      today: today ?? this.today,
      month: month ?? this.month,
      kind: kind ?? this.kind,
      preferred: preferred == null ? this.preferred : preferred(),
      base: base == null ? this.base : base(),
      rates: rates ?? this.rates,
      days: days ?? this.days,
      monthStart: monthStart ?? this.monthStart,
    );
  }
}

/// Follows the report of a month in the local database.
class ReportsCubit extends Cubit<ReportsState> {
  /// Creates the cubit on the current month. [now] tells the time in tests.
  ReportsCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(_initial((now ?? DateTime.now)(), _repository.monthStart())) {
    _follow();
  }

  final ReportsRepository _repository;
  final DateTime Function() _now;
  List<StreamSubscription<void>> _subscriptions = const [];
  final _arrived = <Object>{};

  /// How many sources the reports wait for.
  static const _sources = 4;

  static ReportsState _initial(DateTime now, int monthStart) {
    final today = CivilDate.of(now);
    return ReportsState(
      status: ReportsStatus.loading,
      today: today,
      month: today.monthStart(monthStart),
      monthStart: monthStart,
    );
  }

  /// Shows the month that starts on [month].
  Future<void> monthChanged(CivilDate month) async {
    if (month != state.month) await _restart(month: month);
  }

  /// Shows the month before the one on screen among the months to choose
  /// from, if there is one.
  Future<void> previousMonth() => _monthMoved(earlier: true);

  /// Shows the month after the one on screen among the months to choose
  /// from, if there is one.
  Future<void> nextMonth() => _monthMoved(earlier: false);

  Future<void> _monthMoved({required bool earlier}) async {
    final month = neighbourMonth(
      await months(),
      state.month,
      earlier: earlier,
    );
    if (month != null) await monthChanged(month);
  }

  /// Shows expenses or income.
  Future<void> kindChanged(CategoryKind kind) async {
    if (kind != state.kind) await _restart(kind: kind);
  }

  /// The months to choose from: the current one, even with nothing in it, and
  /// the ones with operations, the latest first. When those cannot be read, the
  /// current one and the one on the screen still can be chosen.
  Future<List<CivilDate>> months() async {
    final current = state.current;
    try {
      final months = await _repository.months(start: state.monthStart);
      return {current, ...months}.toList()..sort((a, b) => b.compareTo(a));
    } on Exception {
      return {current, state.month}.toList();
    }
  }

  /// Reads everything again after a failure.
  Future<void> retry() => _restart();

  /// Catches up with the calendar after a night in the background. A report of
  /// the current month moves to the new one.
  Future<void> calendarChecked() async {
    final today = CivilDate.of(_now());
    if (today == state.today) return;
    final onCurrent = state.month == state.current;
    await _restart(
      today: today,
      month: onCurrent ? today.monthStart(state.monthStart) : null,
    );
  }

  Future<void> _restart({
    CivilDate? today,
    CivilDate? month,
    CategoryKind? kind,
  }) async {
    final cancelled = _cancel();
    emit(
      state.copyWith(
        status: ReportsStatus.loading,
        today: today,
        month: month,
        kind: kind,
        days: const [],
      ),
    );
    _follow();
    await cancelled;
  }

  void _follow() {
    final ReportsState(:kind, :month) = state;
    _arrived.clear();
    _subscriptions = [
      // A new day for the months opens the month of today from that day.
      _repository.watchMonthStart().listen((day) {
        if (day == state.monthStart) return;
        emit(state.copyWith(monthStart: day));
        unawaited(_restart(month: state.current));
      }),
      _listen(
        _repository.watchMainCurrency(),
        (currency) => state.copyWith(preferred: () => currency),
      ),
      _listen(
        _repository.watchBaseCurrency(),
        (base) => state.copyWith(base: () => base),
      ),
      _listen(
        _repository.watchRates(),
        (rates) => state.copyWith(rates: rates),
      ),
      _listen(
        _repository.watchDays(
          kind,
          from: monthsBefore(month, Report.monthCount - 1),
          to: lastDayOf(month),
        ),
        (days) => state.copyWith(days: days),
      ),
    ];
  }

  /// Follows [source]. The reports are ready once every source has spoken, so
  /// that they never compare a month with one that has not come yet.
  StreamSubscription<void> _listen<T>(
    Stream<T> source,
    ReportsState Function(T) update,
  ) {
    final key = Object();
    return source.listen(
      (value) {
        _arrived.add(key);
        final next = update(value);
        emit(
          _arrived.length == _sources
              ? next.copyWith(status: ReportsStatus.ready)
              : next,
        );
      },
      onError: (Object _) {
        // Stays out until it speaks again, so that the others cannot hide it.
        _arrived.remove(key);
        emit(state.copyWith(status: ReportsStatus.failed));
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
