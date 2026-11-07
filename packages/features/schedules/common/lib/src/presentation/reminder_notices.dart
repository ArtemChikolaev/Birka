import 'dart:async';

import 'package:ledger/ledger.dart';
import 'package:schedules_common/src/domain/reminders.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';

/// Makes a timer that calls back once after a while.
typedef StartTimer = Timer Function(Duration after, void Function() callback);

/// Takes the reminders of the regular payments into the notices of this
/// device (ADR 0026), at their moments as the notifications of the phone come:
/// after every change of the payments or of the time of the reminders, when
/// asked, as when the app starts and comes back, and at the moment of the
/// next reminder while the app stays open. Unlike the notifications, it
/// takes them whatever the switches of the reminders say, and in the demo
/// too: the bell is the app's own.
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
  ReminderSettings? _settings;
  Timer? _next;
  Future<void> _work = Future.value();

  /// Starts to follow the payments and the settings of the reminders.
  void start() {
    _subscriptions.addAll([
      _repository.watchSchedules().listen((schedules) {
        _schedules = schedules;
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
    final settings = _settings;
    if (schedules == null || settings == null) return;
    final now = _now();
    final came = remindersCame(
      schedules,
      now: now,
      minutes: settings.minutes,
    );
    if (came.isNotEmpty) {
      try {
        await _repository.noteReminders(came);
      } on Exception {
        // The next change or the next return tries again.
      }
    }
    _next?.cancel();
    final coming = planReminders(
      schedules,
      now: now,
      minutes: settings.minutes,
      limit: 1,
      days: 2,
    );
    if (coming.isEmpty) return;
    // A second after the moment, so that the reminder has come by then.
    _next = _timer(
      coming.single.at.difference(now) + const Duration(seconds: 1),
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
