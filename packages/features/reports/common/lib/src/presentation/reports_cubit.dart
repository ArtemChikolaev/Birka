import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
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
    this.rows = const [],
    this.previousRows = const [],
    this.monthTotals = const [],
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

  /// What went through each category of [month].
  final List<CategoryTotal> rows;

  /// What went through each category of the month before, up to the same day
  /// when [month] is still under way.
  final List<CategoryTotal> previousRows;

  /// What went through the last months.
  final List<MonthTotal> monthTotals;

  /// The report of [month].
  late final Report report = Report.of(
    month: month,
    rows: rows,
    previousRows: previousRows,
    monthTotals: monthTotals,
    preferred: preferred,
  );

  /// A copy with the given fields changed. [preferred] takes a function, so it
  /// can also become `null`.
  ReportsState copyWith({
    ReportsStatus? status,
    CivilDate? today,
    CivilDate? month,
    CategoryKind? kind,
    Currency? Function()? preferred,
    List<CategoryTotal>? rows,
    List<CategoryTotal>? previousRows,
    List<MonthTotal>? monthTotals,
  }) {
    return ReportsState(
      status: status ?? this.status,
      today: today ?? this.today,
      month: month ?? this.month,
      kind: kind ?? this.kind,
      preferred: preferred == null ? this.preferred : preferred(),
      rows: rows ?? this.rows,
      previousRows: previousRows ?? this.previousRows,
      monthTotals: monthTotals ?? this.monthTotals,
    );
  }
}

/// Follows the report of a month in the local database.
class ReportsCubit extends Cubit<ReportsState> {
  /// Creates the cubit on the current month. [now] tells the time in tests.
  ReportsCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(_initial((now ?? DateTime.now)())) {
    _follow();
  }

  final ReportsRepository _repository;
  final DateTime Function() _now;
  List<StreamSubscription<void>> _subscriptions = const [];
  final _arrived = <Object>{};

  /// How many sources the reports wait for.
  static const _sources = 4;

  static ReportsState _initial(DateTime now) {
    final today = CivilDate.of(now);
    return ReportsState(
      status: ReportsStatus.loading,
      today: today,
      month: _monthOf(today),
    );
  }

  static CivilDate _monthOf(CivilDate day) => CivilDate(day.year, day.month, 1);

  /// Shows the month that starts on [month].
  Future<void> monthChanged(CivilDate month) async {
    if (month != state.month) await _restart(month: month);
  }

  /// Shows expenses or income.
  Future<void> kindChanged(CategoryKind kind) async {
    if (kind != state.kind) await _restart(kind: kind);
  }

  /// The months to choose from: the current one, even with nothing in it, and
  /// the ones with operations, the latest first. When those cannot be read, the
  /// current one and the one on the screen still can be chosen.
  Future<List<CivilDate>> months() async {
    final current = _monthOf(state.today);
    try {
      final months = await _repository.months();
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
    final onCurrent = state.month == _monthOf(state.today);
    await _restart(today: today, month: onCurrent ? _monthOf(today) : null);
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
        rows: const [],
        previousRows: const [],
        monthTotals: const [],
      ),
    );
    _follow();
    await cancelled;
  }

  void _follow() {
    final ReportsState(:kind, :month, :today) = state;
    _arrived.clear();
    _subscriptions = [
      _listen(
        _repository.watchMainCurrency(),
        (currency) => state.copyWith(preferred: () => currency),
      ),
      _listen(
        _repository.watchTotals(kind, from: month, to: lastDayOf(month)),
        (rows) => state.copyWith(rows: rows),
      ),
      _listen(
        _repository.watchTotals(
          kind,
          from: monthsBefore(month, 1),
          to: _endOfComparison(month, today: today),
        ),
        (rows) => state.copyWith(previousRows: rows),
      ),
      _listen(
        _repository.watchMonthTotals(
          kind,
          from: monthsBefore(month, Report.monthCount - 1),
          to: lastDayOf(month),
        ),
        (totals) => state.copyWith(monthTotals: totals),
      ),
    ];
  }

  /// The last day of the month before [month] to compare with. A month still
  /// under way takes as many days as it has had, or else it would always start
  /// far below the whole month before it.
  static CivilDate _endOfComparison(
    CivilDate month, {
    required CivilDate today,
  }) {
    final before = monthsBefore(month, 1);
    final last = lastDayOf(before);
    final underWay = month == _monthOf(today);
    return underWay && today.day < last.day
        ? CivilDate(before.year, before.month, today.day)
        : last;
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
