import 'dart:async';

import 'package:ledger/ledger.dart';
import 'package:schedules_common/src/domain/reminders.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';

/// Makes a timer that calls back once after a while.
typedef StartTimer = Timer Function(Duration after, void Function() callback);

/// Takes the reminders of the regular payments and of the days of the debts
/// (ADR 0029) into the notices of this device (ADR 0026), at their moments as
/// the notifications of the phone come: after every change of the payments,
/// of the debts or of the time of the reminders, when asked, as when the app
/// starts and comes back, and at the moment of the next reminder while the
/// app stays open. Unlike the notifications, it takes them whatever the
/// switches of the reminders say, and in the demo too: the bell is the app's
/// own.
final class ReminderNotices {
  /// Creates the notes of [_repository]. [now] tells the time and [timer]
  /// waits in tests.
  ReminderNotices(
    this._repository, {
    DateTime Function()? now,
    StartTimer? timer,
  }) : _now = now ?? DateTime.now,
       _timer = timer ?? Timer.new;

  final SchedulesRepository _repository;
  final DateTime Function() _now;
  final StartTimer _timer;
  final _subscriptions = <StreamSubscription<void>>[];
  List<Schedule>? _schedules;
  List<DebtDay>? _debts;
  ReminderSettings? _settings;
  Timer? _next;
  Future<void> _work = Future.value();

  /// Starts to follow the payments, the debts and the settings of the
  /// reminders.
  void start() {
    _subscriptions.addAll([
      _repository.watchSchedules().listen((schedules) {
        _schedules = schedules;
        unawaited(catchUp());
      }),
      _repository.watchDebtDays().listen((debts) {
        _debts = debts;
        unawaited(catchUp());
      }),
      _repository.watchReminders().listen((settings) {
        _settings = settings;
        unawaited(catchUp());
      }),
    ]);
  }

  /// Takes in the reminders that came and waits for the next one. Runs one
  /// after another.
  Future<void> catchUp() => _work = _work.then((_) => _note());

  Future<void> _note() async {
    final schedules = _schedules;
    final debts = _debts;
    final settings = _settings;
    if (schedules == null || debts == null || settings == null) return;
    final now = _now();
    final minutes = settings.minutes;
    final came = remindersCame(schedules, now: now, minutes: minutes);
    if (came.isNotEmpty) {
      try {
        await _repository.noteReminders(came);
      } on Exception {
        // The next change or the next return tries again.
      }
    }
    final days = debtDaysCame(debts, now: now, minutes: minutes);
    if (days.isNotEmpty) {
      try {
        await _repository.noteDebtDays(days, minutes: minutes);
      } on Exception {
        // As for the payments.
      }
    }
    _next?.cancel();
    final coming = [
      for (final reminder in planReminders(
        schedules,
        now: now,
        minutes: minutes,
        limit: 1,
        days: 2,
      ))
        reminder.at,
      for (final day in debtDaysAhead(
        debts,
        now: now,
        minutes: minutes,
        days: 2,
      ))
        day.at(minutes),
    ];
    if (coming.isEmpty) return;
    final next = coming.reduce((a, b) => a.isBefore(b) ? a : b);
    // A second after the moment, so that the reminder has come by then.
    _next = _timer(
      next.difference(now) + const Duration(seconds: 1),
      () => unawaited(catchUp()),
    );
  }

  /// Stops following and waiting.
  Future<void> stop() async {
    _next?.cancel();
    _next = null;
    await Future.wait(_subscriptions.map((it) => it.cancel()));
    _subscriptions.clear();
  }
}
