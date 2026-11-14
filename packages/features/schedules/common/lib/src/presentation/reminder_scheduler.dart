import 'dart:async';

import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/src/domain/reminders.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';
import 'package:schedules_common/src/presentation/reminder_labels.dart';

/// Keeps the reminders of the phone in step with the regular payments, the
/// days of the debts (ADR 0029) and the settings (ADR 0025), its
/// notifications and the events of the calendar «Birka»: it plans them again
/// after every change of any of them, after a new language, and when asked,
/// as when the app comes back after a night. The calendar keeps only the
/// payments: its events repeat by a rule, and the day of a debt comes once.
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
  List<DebtDay>? _debts;
  ReminderSettings? _settings;
  List<ReminderNote>? _shown;
  List<CalendarReminder>? _written;
  Future<void> _work = Future.value();

  /// Starts to follow the payments, the debts, the settings and the
  /// language.
  void start() {
    _subscriptions.addAll([
      _repository.watchSchedules().listen((schedules) {
        _schedules = schedules;
        unawaited(refresh());
      }),
      _repository.watchDebtDays().listen((debts) {
        _debts = debts;
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
    final debts = _debts;
    final settings = _settings;
    if (schedules == null || debts == null || settings == null) return;
    final notes = settings.notify
        ? _notes(schedules, debts, now: _now(), settings: settings)
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

  /// The reminders of [schedules] and of the days of [debts] after [now],
  /// the earliest first, and the ones of the payments first on a day: no
  /// more than [limit] in all, as iOS keeps at most 64.
  static List<ReminderNote> _notes(
    List<Schedule> schedules,
    List<DebtDay> debts, {
    required DateTime now,
    required ReminderSettings settings,
    int limit = 60,
  }) {
    final minutes = settings.minutes;
    final payments = [
      for (final reminder in planReminders(
        schedules,
        now: now,
        minutes: minutes,
        limit: limit,
      ))
        reminderNote(reminder, sums: settings.sums),
    ];
    final days = [
      for (final day in debtDaysAhead(debts, now: now, minutes: minutes))
        debtReminderNote(day, minutes: minutes, sums: settings.sums),
    ];
    final notes = <ReminderNote>[];
    var (i, j) = (0, 0);
    while (notes.length < limit && (i < payments.length || j < days.length)) {
      final payment = i < payments.length ? payments[i] : null;
      final day = j < days.length ? days[j] : null;
      if (day == null ||
          (payment != null && payment.day.compareTo(day.day) <= 0)) {
        notes.add(payments[i++]);
      } else {
        notes.add(days[j++]);
      }
    }
    return notes;
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
