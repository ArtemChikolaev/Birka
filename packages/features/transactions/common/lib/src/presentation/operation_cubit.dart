import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:transactions_common/src/domain/operation.dart';
import 'package:transactions_common/src/domain/transactions_repository.dart';

/// Where the card of an operation stands.
enum OperationStatus {
  /// The first read has not come back yet.
  loading,

  /// The operation is here.
  ready,

  /// The operation could not be read.
  failed,

  /// The operation is not in the ledger any more.
  gone,
}

/// What the card of an operation shows.
@immutable
final class OperationState {
  /// Creates a state.
  const OperationState({
    required this.status,
    required this.today,
    this.operation,
    this.deleteFailed = false,
  });

  /// Where the card stands.
  final OperationStatus status;

  /// The day of today.
  final CivilDate today;

  /// The operation.
  final Operation? operation;

  /// Whether the last delete failed.
  final bool deleteFailed;
}

/// Follows one operation in the local database.
class OperationCubit extends Cubit<OperationState> {
  /// Creates the cubit and starts to follow operation [_id]. [now] tells the
  /// time in tests.
  OperationCubit(this._repository, this._id, {DateTime Function()? now})
    : super(
        OperationState(
          status: OperationStatus.loading,
          today: CivilDate.of((now ?? DateTime.now)()),
        ),
      ) {
    _follow();
  }

  final TransactionsRepository _repository;
  final String _id;
  StreamSubscription<void>? _subscription;

  /// Reads the operation again after a failure.
  Future<void> retry() async {
    final cancelled = _subscription?.cancel();
    emit(_with(OperationStatus.loading));
    _follow();
    await cancelled;
  }

  /// Deletes the operation. The ledger then reports that it is gone.
  Future<void> delete() async {
    try {
      await _repository.delete(_id);
    } on Exception {
      if (isClosed) return;
      emit(
        _with(
          state.status,
          operation: state.operation,
          deleteFailed: true,
        ),
      );
    }
  }

  OperationState _with(
    OperationStatus status, {
    Operation? operation,
    bool deleteFailed = false,
  }) => OperationState(
    status: status,
    today: state.today,
    operation: operation,
    deleteFailed: deleteFailed,
  );

  void _follow() {
    _subscription = _repository
        .watchOperation(_id)
        .listen(
          (operation) => emit(
            operation == null
                ? _with(OperationStatus.gone)
                : _with(OperationStatus.ready, operation: operation),
          ),
          onError: (Object _) => emit(_with(OperationStatus.failed)),
        );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
