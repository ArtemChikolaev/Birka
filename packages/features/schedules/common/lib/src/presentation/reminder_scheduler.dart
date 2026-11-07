import 'dart:async';

import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/src/domain/reminders.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';
import 'package:schedules_common/src/presentation/reminder_labels.dart';

/// Keeps the reminders of the phone in step with the regular payments and
/// the settings (ADR 0025), its notifications and the events of the calendar
/// «Birka»: it plans them again after every change of either, after a new
/// language, and when asked, as when the app comes back after a night.
final class ReminderScheduler {
  /// Creates the scheduler of [_repository] on [_channel] and [_calendar].
  /// [now] tells the time in tests.
  ReminderScheduler(
    this._repository,
    this._channel,
    this._calendar, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SchedulesRepository _repository;
  final ReminderChannel _channel;
  final ReminderCalendar _calendar;
  final DateTime Function() _now;
  final _subscriptions = <StreamSubscription<void>>[];
  List<Schedule>? _schedules;
  ReminderSettings? _settings;
  List<ReminderNote>? _shown;
  List<CalendarReminder>? _written;
  Future<void> _work = Future.value();

  /// Starts to follow the payments, the settings and the language.
  void start() {
    _subscriptions.addAll([
      _repository.watchSchedules().listen((schedules) {
        _schedules = schedules;
        unawaited(refresh());
      }),
      _repository.watchReminders().listen((settings) {
        _settings = settings;
        unawaited(refresh());
      }),
      LocaleSettings.getLocaleStream().listen((_) => unawaited(refresh())),
    ]);
  }

  /// Plans the reminders again. Plans run one after another, and a plan
  /// equal to the one the phone holds leaves it alone. The calendar is left
  /// alone while it is off: turning it off removes it.
  Future<void> refresh() => _work = _work.then((_) => _apply());

  Future<void> _apply() async {
    final schedules = _schedules;
    final settings = _settings;
    if (schedules == null || settings == null) return;
    final notes = settings.notify
        ? [
            for (final reminder in planReminders(
              schedules,
              now: _now(),
              minutes: settings.minutes,
            ))
              reminderNote(reminder, sums: settings.sums),
          ]
        : const <ReminderNote>[];
    if (!_same(_shown, notes)) {
      try {
        await _channel.show(notes);
        _shown = notes;
      } on Exception {
        // The phone refused; the next change or the next return tries again.
        _shown = null;
      }
    }
    if (!settings.calendar) {
      _written = null;
      return;
    }
    final events = calendarReminders(
      schedules,
      minutes: settings.minutes,
      sums: settings.sums,
    );
    if (_same(_written, events)) return;
    try {
      await _calendar.write(events);
      _written = events;
    } on Exception {
      // Without access to the calendar nothing is written; the row says so.
      _written = null;
    }
  }

  static bool _same<T>(List<T>? a, List<T> b) {
    if (a == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Stops following.
  Future<void> stop() async {
    await Future.wait(_subscriptions.map((it) => it.cancel()));
    _subscriptions.clear();
  }
}
