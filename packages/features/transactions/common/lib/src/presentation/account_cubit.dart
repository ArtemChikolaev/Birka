import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:transactions_common/src/domain/operation.dart';
import 'package:transactions_common/src/domain/transactions_repository.dart';

/// Where the page of an account stands.
enum AccountStatus {
  /// The first read has not come back yet.
  loading,

  /// Everything is here.
  ready,

  /// There is no such account.
  gone,

  /// Something could not be read.
  failed,
}

/// What the page of an account shows.
@immutable
final class AccountState {
  /// Creates a state.
  AccountState({
    required this.status,
    required this.today,
    this.period = ChartPeriod.month,
    this.account,
    this.changes = const [],
    this.operations = const [],
    this.deleteFailed = false,
  });

  /// Where the page stands.
  final AccountStatus status;

  /// The day of today.
  final CivilDate today;

  /// How far back the chart looks.
  final ChartPeriod period;

  /// The account with what it holds.
  final AccountBalance? account;

  /// What each day of the last year changed.
  final List<DayChange> changes;

  /// The latest operations, the latest first.
  final List<Operation> operations;

  /// Whether the last delete failed.
  final bool deleteFailed;

  /// The balance at the end of each day of [period], in minor units.
  late final List<int> history = _history();

  /// How much the balance changed over [period].
  late final Money? change = _change();

  /// The operations, day by day.
  late final List<OperationDay> days = groupByDay(operations);

  List<int> _history() {
    final account = this.account;
    if (account == null) return const [];
    return balanceHistory(
      now: account.balance.minorUnits,
      changes: {
        for (final DayChange(:day, :change) in changes) day: change.minorUnits,
      },
      start: period.startFrom(today),
      today: today,
    );
  }

  Money? _change() {
    final account = this.account;
    if (account == null) return null;
    return Money(
      (history.last - history.first).clamp(
        -Money.maxMinorUnits,
        Money.maxMinorUnits,
      ),
      account.balance.currency,
    );
  }

  /// A copy with the given fields changed. A new copy forgets a failed delete
  /// unless it says otherwise.
  AccountState copyWith({
    AccountStatus? status,
    CivilDate? today,
    ChartPeriod? period,
    AccountBalance? account,
    List<DayChange>? changes,
    List<Operation>? operations,
    bool deleteFailed = false,
  }) {
    return AccountState(
      status: status ?? this.status,
      today: today ?? this.today,
      period: period ?? this.period,
      account: account ?? this.account,
      changes: changes ?? this.changes,
      operations: operations ?? this.operations,
      deleteFailed: deleteFailed,
    );
  }
}

/// Follows one account in the local database: what it holds, how that changed
/// and what happened on it.
class AccountCubit extends Cubit<AccountState> {
  /// Creates the cubit and starts to follow account [_id]. [now] tells the time
  /// in tests.
  AccountCubit(this._repository, this._id, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(
        AccountState(
          status: AccountStatus.loading,
          today: CivilDate.of((now ?? DateTime.now)()),
        ),
      ) {
    _follow();
  }

  final TransactionsRepository _repository;
  final String _id;
  final DateTime Function() _now;
  List<StreamSubscription<void>> _subscriptions = const [];
  final _arrived = <Object>{};

  /// How many sources the page waits for.
  static const _sources = 3;

  /// Sets how far back the chart looks.
  void periodChanged(ChartPeriod value) => emit(state.copyWith(period: value));

  /// Reads everything again after a failure.
  Future<void> retry() async {
    final cancelled = _cancel();
    emit(state.copyWith(status: AccountStatus.loading));
    _follow();
    await cancelled;
  }

  /// Catches up with the calendar after a night in the background, since the
  /// chart ends today.
  Future<void> calendarChecked() async {
    final today = CivilDate.of(_now());
    if (today == state.today) return;
    final cancelled = _cancel();
    emit(state.copyWith(today: today));
    _follow();
    await cancelled;
  }

  /// Deletes operation [id].
  Future<void> delete(String id) async {
    try {
      await _repository.delete(id);
    } on Exception {
      if (!isClosed) emit(state.copyWith(deleteFailed: true));
    }
  }

  void _follow() {
    _arrived.clear();
    _subscriptions = [
      _listen<AccountBalance?>(
        _repository.watchAccount(_id),
        (account) => account == null
            ? state.copyWith(status: AccountStatus.gone)
            : state.copyWith(account: account),
      ),
      _listen(
        _repository.watchAccountChanges(
          _id,
          from: ChartPeriod.earliest(state.today),
        ),
        (changes) => state.copyWith(changes: changes),
      ),
      _listen(
        _repository.watchAccountOperations(_id),
        (operations) => state.copyWith(operations: operations),
      ),
    ];
  }

  /// Follows [source]. The page is ready once every source has spoken, so that
  /// it never shows a balance without its history.
  StreamSubscription<void> _listen<T>(
    Stream<T> source,
    AccountState Function(T) update,
  ) {
    final key = Object();
    return source.listen(
      (value) {
        _arrived.add(key);
        final next = update(value);
        emit(
          _arrived.length == _sources && next.status != AccountStatus.gone
              ? next.copyWith(status: AccountStatus.ready)
              : next,
        );
      },
      onError: (Object _) {
        // Stays out until it speaks again, so that the others cannot hide it.
        _arrived.remove(key);
        emit(state.copyWith(status: AccountStatus.failed));
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
