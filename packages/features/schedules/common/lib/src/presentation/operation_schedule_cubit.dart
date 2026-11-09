import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';

/// What the card of an operation says of the regular payments (ADR 0023,
/// point 22): the payment it belongs to, or that it can become one, or
/// nothing while it is read and for what cannot repeat.
@immutable
final class OperationScheduleState {
  /// Creates the state of [today].
  const OperationScheduleState({required this.today, this.schedule, this.day});

  /// Today on this device.
  final CivilDate today;

  /// The regular payment the operation belongs to.
  final Schedule? schedule;

  /// The day of the month a payment made from the operation comes on, while
  /// it can become one.
  final int? day;

  /// Whether the operation can become a regular payment.
  bool get offers => schedule == null && day != null;

  @override
  bool operator ==(Object other) =>
      other is OperationScheduleState &&
      other.today == today &&
      other.schedule == schedule &&
      other.day == day;

  @override
  int get hashCode => Object.hash(today, schedule, day);
}

/// The regular payment that operation [made] belongs to among [schedules]:
/// the one made from it, the one whose last time it is, or, for one that a
/// payment posted, the payment of its name on its account. Older posts of a
/// renamed payment have none.
Schedule? scheduleOf(Transaction made, List<Schedule> schedules) {
  for (final schedule in schedules) {
    if (schedule.madeFrom == made.id ||
        schedule.last?.transactionId == made.id) {
      return schedule;
    }
  }
  if (made.source != TransactionSource.recurring) return null;
  final account = made.entries.first.accountId;
  final name = made.note.trim();
  for (final schedule in schedules) {
    if (schedule.kind == made.kind &&
        schedule.accountId == account &&
        schedule.name.trim() == name) {
      return schedule;
    }
  }
  return null;
}

/// Whether operation [made] can become a regular payment: an expense, an
/// income or a transfer with one category at most, which no payment posted.
/// A posted one already has its payment, and a correction is no payment.
bool canRepeat(Transaction made) {
  if (made.kind == TransactionKind.adjustment) return false;
  if (made.source == TransactionSource.recurring) return false;
  return {for (final it in made.allocations) it.categoryId}.length <= 1;
}

/// Follows operation [_id] and the regular payments for its card.
final class OperationScheduleCubit extends Cubit<OperationScheduleState> {
  /// Creates the cubit of operation [_id] on [_repository].
  OperationScheduleCubit(this._repository, this._id)
    : super(OperationScheduleState(today: _repository.today())) {
    _made = _repository.watchTransaction(_id).listen((made) {
      _transaction = made;
      _read = true;
      _update();
    }, onError: (Object _) {});
    _payments = _repository.watchSchedules().listen((schedules) {
      _schedules = schedules;
      _update();
    }, onError: (Object _) {});
  }

  final SchedulesRepository _repository;
  final String _id;
  late final StreamSubscription<Transaction?> _made;
  late final StreamSubscription<List<Schedule>> _payments;
  Transaction? _transaction;
  List<Schedule>? _schedules;
  var _read = false;

  void _update() {
    final schedules = _schedules;
    if (!_read || schedules == null || isClosed) return;
    final made = _transaction;
    final today = state.today;
    if (made == null) return emit(OperationScheduleState(today: today));
    final schedule = scheduleOf(made, schedules);
    emit(
      OperationScheduleState(
        today: today,
        schedule: schedule,
        day: schedule == null && canRepeat(made) ? made.occurredOn.day : null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _made.cancel();
    await _payments.cancel();
    return super.close();
  }
}
