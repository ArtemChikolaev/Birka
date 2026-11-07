import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:schedules_common/src/domain/reminders.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';

/// What the reminders of «Ещё» show.
@immutable
final class RemindersState {
  /// Creates the state.
  const RemindersState({
    this.settings,
    this.access = ReminderAccess.unknown,
    this.schedules = const [],
  });

  /// How this device reminds, `null` until it is read.
  final ReminderSettings? settings;

  /// Whether the phone lets Birka show notifications.
  final ReminderAccess access;

  /// The regular payments.
  final List<Schedule> schedules;

  /// Whether the notifications of Birka are on.
  bool get notify => settings?.notify ?? false;

  /// Whether the phone keeps the notifications of Birka off.
  bool get denied => access == ReminderAccess.denied;

  /// How many payments remind of their times.
  int get reminding =>
      schedules.where((it) => it.reminder != ScheduleReminder.none).length;

  /// A copy with the given fields changed.
  RemindersState copyWith({
    ReminderSettings? settings,
    ReminderAccess? access,
    List<Schedule>? schedules,
  }) => RemindersState(
    settings: settings ?? this.settings,
    access: access ?? this.access,
    schedules: schedules ?? this.schedules,
  );
}

/// Turns the reminders of Birka on and off and sets them up (ADR 0025): the
/// group «Напоминания» of «Ещё», and the form of a payment when its
/// reminders are off.
class RemindersCubit extends Cubit<RemindersState> {
  /// Creates the cubit and starts to follow [_repository]. [now] tells the
  /// time in tests.
  RemindersCubit(
    this._repository,
    this._channel, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const RemindersState()) {
    _subscriptions = [
      _repository.watchReminders().listen(
        (settings) => emit(state.copyWith(settings: settings)),
      ),
      _repository.watchSchedules().listen(
        (schedules) => emit(state.copyWith(schedules: schedules)),
      ),
    ];
    unawaited(accessChecked());
  }

  final SchedulesRepository _repository;
  final ReminderChannel _channel;
  final DateTime Function() _now;
  late final List<StreamSubscription<void>> _subscriptions;

  /// The first reminder to come once they are on, for the question that
  /// turns them on to show, or `null` when no payment reminds.
  PlannedReminder? get nearest => planReminders(
    state.schedules,
    now: _now(),
    minutes: state.settings?.minutes ?? ReminderSettings.defaultMinutes,
    limit: 1,
  ).firstOrNull;

  /// Reads again whether the phone lets Birka show notifications, as when the
  /// person comes back from its settings.
  Future<void> accessChecked() async {
    final access = await _channel.access();
    if (!isClosed) emit(state.copyWith(access: access));
  }

  /// Turns the notifications of Birka on once the phone allows them, and
  /// says whether it did.
  Future<bool> enable() async {
    final access = await _channel.requestAccess();
    if (isClosed) return false;
    emit(state.copyWith(access: access));
    if (access != ReminderAccess.granted) return false;
    await _save((settings) => settings.copyWith(notify: true));
    return true;
  }

  /// Turns the notifications of Birka off; the phone forgets them.
  Future<void> disable() =>
      _save((settings) => settings.copyWith(notify: false));

  /// Makes reminders come at [minutes] after midnight.
  Future<void> timeChanged(int minutes) =>
      _save((settings) => settings.copyWith(minutes: minutes));

  /// Shows the amounts in reminders, or leaves them out.
  Future<void> sumsChanged({required bool sums}) =>
      _save((settings) => settings.copyWith(sums: sums));

  Future<void> _save(
    ReminderSettings Function(ReminderSettings settings) change,
  ) => _repository.saveReminders(
    change(state.settings ?? const ReminderSettings()),
  );

  @override
  Future<void> close() async {
    await Future.wait(_subscriptions.map((it) => it.cancel()));
    return super.close();
  }
}
