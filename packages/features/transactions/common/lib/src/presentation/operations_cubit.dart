import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:transactions_common/src/domain/operation.dart';
import 'package:transactions_common/src/domain/transactions_repository.dart';

/// Which operations the list shows.
enum OperationsFilter {
  /// Every one.
  all,

  /// Money spent.
  expenses,

  /// Money earned.
  income,

  /// Money moved between accounts.
  transfers
  ;

  /// Whether the filter lets [kind] through.
  bool allows(TransactionKind kind) => switch (this) {
    all => true,
    expenses => kind == TransactionKind.expense,
    income => kind == TransactionKind.income,
    transfers => kind == TransactionKind.transfer,
  };
}

/// Where the list stands.
enum OperationsStatus {
  /// The first read has not come back yet.
  loading,

  /// The operations are here.
  ready,

  /// The operations could not be read.
  failed,
}

/// What the list of operations shows.
@immutable
final class OperationsState {
  /// Creates a state.
  OperationsState({
    required this.status,
    required this.today,
    required this.month,
    this.filter = OperationsFilter.all,
    this.query = '',
    this.operations = const [],
    this.deleteFailed = false,
  });

  /// Where the list stands.
  final OperationsStatus status;

  /// The day of today.
  final CivilDate today;

  /// The first day of the month on the screen.
  final CivilDate month;

  /// Which operations the list shows.
  final OperationsFilter filter;

  /// What was typed into the search, which looks through [month].
  final String query;

  /// Every operation of [month], the latest first.
  final List<Operation> operations;

  /// Whether the last delete failed.
  final bool deleteFailed;

  /// The operations that the filter and the search let through.
  late final List<Operation> shown = [
    for (final operation in operations)
      if (filter.allows(operation.kind) && operation.matches(query)) operation,
  ];

  /// What the list shows, day by day.
  late final List<OperationDay> days = groupByDay(shown);

  /// The money spent in [shown], one amount for each currency.
  late final List<Money> expenses = _sumOf(TransactionKind.expense);

  /// The money earned in [shown], one amount for each currency.
  late final List<Money> income = _sumOf(TransactionKind.income);

  /// Whether the list shows only part of [month].
  bool get isNarrowed => filter != OperationsFilter.all || query.isNotEmpty;

  List<Money> _sumOf(TransactionKind kind) => sumByCurrency(
    shown
        .where((operation) => operation.kind == kind && operation.counts)
        .map((operation) => operation.amount),
  );

  /// A copy with the given fields changed. A new copy forgets a failed delete
  /// unless it says otherwise.
  OperationsState copyWith({
    OperationsStatus? status,
    CivilDate? today,
    CivilDate? month,
    OperationsFilter? filter,
    String? query,
    List<Operation>? operations,
    bool deleteFailed = false,
  }) {
    return OperationsState(
      status: status ?? this.status,
      today: today ?? this.today,
      month: month ?? this.month,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      operations: operations ?? this.operations,
      deleteFailed: deleteFailed,
    );
  }
}

/// Follows the operations of a month in the local database.
class OperationsCubit extends Cubit<OperationsState> {
  /// Creates the cubit on the current month. [now] tells the time in tests.
  OperationsCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(_initial((now ?? DateTime.now)())) {
    _follow();
  }

  final TransactionsRepository _repository;
  final DateTime Function() _now;
  StreamSubscription<void>? _subscription;

  static OperationsState _initial(DateTime now) {
    final today = CivilDate.of(now);
    return OperationsState(
      status: OperationsStatus.loading,
      today: today,
      month: _monthOf(today),
    );
  }

  static CivilDate _monthOf(CivilDate day) => CivilDate(day.year, day.month, 1);

  /// Shows the month that starts on [month].
  Future<void> monthChanged(CivilDate month) async {
    if (month == state.month) return;
    final cancelled = _subscription?.cancel();
    emit(
      state.copyWith(
        status: OperationsStatus.loading,
        month: month,
        operations: const [],
      ),
    );
    _follow();
    await cancelled;
  }

  /// Sets which operations the list shows.
  void filterChanged(OperationsFilter value) =>
      emit(state.copyWith(filter: value));

  /// Sets what the search looks for.
  void queryChanged(String value) => emit(state.copyWith(query: value));

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

  /// Reads the operations again after a failure.
  Future<void> retry() async {
    final cancelled = _subscription?.cancel();
    emit(state.copyWith(status: OperationsStatus.loading));
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

  /// Catches up with the calendar after a night in the background. A list on
  /// the current month moves to the new one.
  Future<void> calendarChecked() async {
    final today = CivilDate.of(_now());
    if (today == state.today) return;
    final onCurrent = state.month == _monthOf(state.today);
    emit(state.copyWith(today: today));
    if (onCurrent) await monthChanged(_monthOf(today));
  }

  void _follow() {
    _subscription = _repository
        .watchOperations(state.month)
        .listen(
          (operations) => emit(
            state.copyWith(
              status: OperationsStatus.ready,
              operations: operations,
            ),
          ),
          onError: (Object _) =>
              emit(state.copyWith(status: OperationsStatus.failed)),
        );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
