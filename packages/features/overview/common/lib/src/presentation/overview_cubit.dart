import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:overview_common/src/domain/capital.dart';
import 'package:overview_common/src/domain/overview_repository.dart';
import 'package:overview_common/src/domain/spending.dart';

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
    this.period = OverviewPeriod.month,
    this.accounts = const [],
    this.changes = const [],
    this.spendingRows = const [],
  });

  /// Where the screen stands.
  final OverviewStatus status;

  /// The day of today.
  final CivilDate today;

  /// How far back the chart looks.
  final OverviewPeriod period;

  /// The accounts in everyday use with their balances.
  final List<AccountBalance> accounts;

  /// What each day of the last year changed.
  final List<DayChange> changes;

  /// What went through each category this month.
  final List<CategoryTotal> spendingRows;

  /// What the accounts hold, one amount for each currency. The first one is in
  /// the currency of the first account.
  late final List<Money> capital = capitalOf(accounts);

  /// The capital in the currency that the chart follows.
  Money? get main => capital.firstOrNull;

  /// The capital in the other currencies.
  Iterable<Money> get others => capital.skip(1);

  /// The capital at the end of each day of [period], in minor units of [main].
  late final List<int> history = _history();

  /// How much [main] changed over [period].
  late final Money? change = _change();

  /// The spending of the month.
  late final Spending spending = Spending.of(
    spendingRows,
    preferred: main?.currency,
  );

  List<int> _history() {
    final main = this.main;
    if (main == null) return const [];
    return capitalHistory(
      now: main,
      changes: changes,
      start: period.startFrom(today),
      today: today,
    );
  }

  Money? _change() {
    final main = this.main;
    if (main == null) return null;
    final change = history.last - history.first;
    return Money(
      change.clamp(-Money.maxMinorUnits, Money.maxMinorUnits),
      main.currency,
    );
  }

  /// A copy with the given fields changed.
  OverviewState copyWith({
    OverviewStatus? status,
    CivilDate? today,
    OverviewPeriod? period,
    List<AccountBalance>? accounts,
    List<DayChange>? changes,
    List<CategoryTotal>? spendingRows,
  }) {
    return OverviewState(
      status: status ?? this.status,
      today: today ?? this.today,
      period: period ?? this.period,
      accounts: accounts ?? this.accounts,
      changes: changes ?? this.changes,
      spendingRows: spendingRows ?? this.spendingRows,
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
        ),
      ) {
    _follow();
  }

  final OverviewRepository _repository;
  final DateTime Function() _now;
  List<StreamSubscription<void>> _subscriptions = const [];
  final _arrived = <Object>{};

  /// Sets how far back the chart looks.
  void periodChanged(OverviewPeriod value) =>
      emit(state.copyWith(period: value));

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
      _listen(
        _repository.watchAccounts(),
        (accounts) => state.copyWith(accounts: accounts),
      ),
      _listen(
        _repository.watchDayChanges(from: OverviewPeriod.earliest(today)),
        (changes) => state.copyWith(changes: changes),
      ),
      _listen(
        _repository.watchSpending(
          from: CivilDate(today.year, today.month, 1),
          to: today,
        ),
        (rows) => state.copyWith(spendingRows: rows),
      ),
    ];
  }

  /// Follows [source]. The screen is ready once all three sources have spoken,
  /// so that it never shows a capital without its history.
  StreamSubscription<void> _listen<T extends Object>(
    Stream<T> source,
    OverviewState Function(T) update,
  ) {
    final key = Object();
    return source.listen(
      (value) {
        _arrived.add(key);
        final next = update(value);
        emit(
          _arrived.length == 3
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
