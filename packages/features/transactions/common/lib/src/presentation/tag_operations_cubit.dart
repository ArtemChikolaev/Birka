import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:transactions_common/src/domain/operation.dart';
import 'package:transactions_common/src/domain/transactions_repository.dart';

/// What the report of a метка lists of its operations (ADR 0027).
@immutable
final class TagOperationsState {
  /// Creates a state of [today].
  TagOperationsState({
    required this.today,
    this.read = false,
    this.operations = const [],
    this.all = false,
    this.deleteFailed = false,
  });

  /// Today on this device.
  final CivilDate today;

  /// Whether the operations are read.
  final bool read;

  /// The operations that wear the метка, the latest first.
  final List<Operation> operations;

  /// Whether every day is shown, not only the latest ones.
  final bool all;

  /// Whether the last delete failed.
  final bool deleteFailed;

  /// The operations, day by day.
  late final List<OperationDay> days = groupByDay(operations);

  /// The days that are shown: the [TagOperationsCubit.latest] latest until
  /// every day is asked for.
  List<OperationDay> get shown =>
      all ? days : days.take(TagOperationsCubit.latest).toList();

  /// Whether some days wait behind «all».
  bool get hasMore => !all && days.length > TagOperationsCubit.latest;

  /// A copy with the given fields changed. A new copy forgets a failed delete
  /// unless it says otherwise.
  TagOperationsState copyWith({
    bool? read,
    List<Operation>? operations,
    bool? all,
    bool deleteFailed = false,
  }) => TagOperationsState(
    today: today,
    read: read ?? this.read,
    operations: operations ?? this.operations,
    all: all ?? this.all,
    deleteFailed: deleteFailed,
  );
}

/// Follows the operations that wear метка [_id].
final class TagOperationsCubit extends Cubit<TagOperationsState> {
  /// Creates the cubit of метка [_id] on [_repository]. [now] tells the time
  /// in tests.
  TagOperationsCubit(
    this._repository,
    this._id, {
    DateTime Function()? now,
  }) : super(TagOperationsState(today: CivilDate.of((now ?? DateTime.now)()))) {
    _operations = _repository.watchTagOperations(_id).listen((operations) {
      if (!isClosed) emit(state.copyWith(read: true, operations: operations));
    }, onError: (Object _) {});
  }

  /// How many of the latest days come before «all».
  static const latest = 3;

  final TransactionsRepository _repository;
  final String _id;
  late final StreamSubscription<List<Operation>> _operations;

  /// Shows every day.
  void showAll() => emit(state.copyWith(all: true));

  /// Deletes operation [id].
  Future<void> delete(String id) async {
    try {
      await _repository.delete(id);
    } on Exception {
      if (!isClosed) emit(state.copyWith(deleteFailed: true));
    }
  }

  @override
  Future<void> close() async {
    await _operations.cancel();
    return super.close();
  }
}
