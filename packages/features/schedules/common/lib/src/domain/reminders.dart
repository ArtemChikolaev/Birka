import 'package:device_settings/device_settings.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';

/// How this device reminds of the regular payments (ADR 0025): with
/// notifications of its own, with the events of a calendar of its own, at
/// what time of the day, and whether a reminder shows the amount. It belongs
/// to the device, as the other settings do (ADR 0011).
@immutable
final class ReminderSettings {
  /// Creates the settings.
  const ReminderSettings({
    this.notify = false,
    this.calendar = false,
    this.minutes = defaultMinutes,
    this.sums = true,
  });

  /// Reads the settings from [store], with the defaults for what it lacks.
  factory ReminderSettings.read(SettingsStore store) {
    final minutes = int.tryParse(store.read(_timeKey) ?? '');
    return ReminderSettings(
      notify: store.read(_notifyKey) == _on,
      calendar: store.read(_calendarKey) == _on,
      minutes: minutes != null && minutes >= 0 && minutes < _day
          ? minutes
          : defaultMinutes,
      sums: store.read(_sumsKey) != _off,
    );
  }

  /// 9:00, when reminders come unless the person picks another time.
  static const int defaultMinutes = 9 * 60;

  static const int _day = 24 * 60;
  static const _notifyKey = 'remind-notify';
  static const _calendarKey = 'remind-calendar';
  static const _timeKey = 'remind-time';
  static const _sumsKey = 'remind-sums';
  static const _on = 'on';
  static const _off = 'off';

  /// Whether Birka shows notifications of its own.
  final bool notify;

  /// Whether Birka keeps the payments in a calendar of its own, whose events
  /// remind even without the app.
  final bool calendar;

  /// Whether anything reminds: the notifications, the calendar or both.
  bool get any => notify || calendar;

  /// When a reminder comes, in minutes after midnight on this device.
  final int minutes;

  /// Whether a reminder shows the amount of its payment.
  final bool sums;

  /// Keeps the settings in [store].
  Future<void> write(SettingsStore store) async {
    await store.write(_notifyKey, notify ? _on : _off);
    await store.write(_calendarKey, calendar ? _on : _off);
    await store.write(_timeKey, '$minutes');
    await store.write(_sumsKey, sums ? _on : _off);
  }

  /// The same settings with the given ones changed.
  ReminderSettings copyWith({
    bool? notify,
    bool? calendar,
    int? minutes,
    bool? sums,
  }) => ReminderSettings(
    notify: notify ?? this.notify,
    calendar: calendar ?? this.calendar,
    minutes: minutes ?? this.minutes,
    sums: sums ?? this.sums,
  );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.notify == notify &&
      other.calendar == calendar &&
      other.minutes == minutes &&
      other.sums == sums;

  @override
  int get hashCode => Object.hash(notify, calendar, minutes, sums);
}

/// Whether the phone lets Birka show notifications.
enum ReminderAccess {
  /// It does.
  granted,

  /// The person turned them off.
  denied,

  /// Nobody has asked yet.
  unknown,
}

/// A reminder of the time [on] of [schedule], which comes at [minutes] after
/// midnight of [day]: the day of the time, or the day before it.
@immutable
final class PlannedReminder {
  /// Creates the reminder.
  const PlannedReminder({
    required this.schedule,
    required this.on,
    required this.day,
    required this.minutes,
  });

  /// The payment it reminds of.
  final Schedule schedule;

  /// The time of the payment.
  final CivilDate on;

  /// The day it comes on.
  final CivilDate day;

  /// When it comes, in minutes after midnight of [day].
  final int minutes;

  /// Whether it comes the day before the payment.
  bool get early => day != on;
}

/// What the phone shows as a reminder: at [minutes] after midnight of [day],
/// with [title] and [body], and what a [tap] on it opens.
@immutable
final class ReminderNote {
  /// Creates the note.
  const ReminderNote({
    required this.day,
    required this.minutes,
    required this.title,
    required this.body,
    required this.tap,
  });

  /// The day it comes on.
  final CivilDate day;

  /// When it comes, in minutes after midnight of [day].
  final int minutes;

  /// The first line, the name of the payment and its amount.
  final String title;

  /// The line under it.
  final String body;

  /// What a tap on it opens.
  final ReminderTap tap;

  @override
  bool operator ==(Object other) =>
      other is ReminderNote &&
      other.day == day &&
      other.minutes == minutes &&
      other.title == title &&
      other.body == body &&
      other.tap == tap;

  @override
  int get hashCode => Object.hash(day, minutes, title, body, tap);
}

/// A tap on a reminder of payment [scheduleId] (ADR 0025). A reminder of the
/// day before, [early], opens the payment, as its line says. One of the day
/// opens the regular payments, where a time that waits is posted or skipped.
@immutable
final class ReminderTap {
  /// Creates the tap.
  const ReminderTap(this.scheduleId, {this.early = false});

  /// The tap that a reminder keeping [payload] stands for.
  factory ReminderTap.parse(String payload) => payload.startsWith(_earlyMark)
      ? ReminderTap(payload.substring(_earlyMark.length), early: true)
      : ReminderTap(payload);

  static const _earlyMark = 'early:';

  /// The payment the reminder is of.
  final String scheduleId;

  /// Whether the reminder came the day before the payment.
  final bool early;

  /// What the phone keeps with the reminder to give the tap back.
  String get payload => early ? '$_earlyMark$scheduleId' : scheduleId;

  @override
  bool operator ==(Object other) =>
      other is ReminderTap &&
      other.scheduleId == scheduleId &&
      other.early == early;

  @override
  int get hashCode => Object.hash(scheduleId, early);
}

/// The notifications of this phone (ADR 0025): the phone keeps them and shows
/// each on time, with Birka closed.
abstract interface class ReminderChannel {
  /// Whether the phone lets Birka show notifications.
  Future<ReminderAccess> access();

  /// Asks the phone to let Birka show notifications, the first time with its
  /// own question, and gives the answer.
  Future<ReminderAccess> requestAccess();

  /// Puts [notes] in place of every reminder the phone holds from Birka.
  Future<void> show(List<ReminderNote> notes);

  /// The taps on the reminders, the one that opened the app first.
  Stream<ReminderTap> get opened;
}

/// A recurring event of the calendar «Birka» (ADR 0025): [title] at
/// [minutes] after midnight of each time of a rule from [first] on, every
/// week, month or year as [every] says, on [day] of the month for a monthly
/// or a yearly one, and in the month of [first] for a yearly one. Its alarm
/// rings at its start, or a day before when [early].
@immutable
final class CalendarReminder {
  /// Creates the event.
  const CalendarReminder({
    required this.title,
    required this.first,
    required this.minutes,
    required this.every,
    required this.day,
    required this.early,
  });

  /// What the event says: the name of the time and, with the amounts, the
  /// amount.
  final String title;

  /// Its first time, which also gives the day of the week of a weekly one
  /// and the month of a yearly one.
  final CivilDate first;

  /// When it starts, in minutes after midnight.
  final int minutes;

  /// How often it comes.
  final ScheduleEvery every;

  /// The day of the month of a monthly or a yearly one, the last day of a
  /// shorter month when that month has no such day.
  final int day;

  /// Whether its alarm rings the day before.
  final bool early;

  @override
  bool operator ==(Object other) =>
      other is CalendarReminder &&
      other.title == title &&
      other.first == first &&
      other.minutes == minutes &&
      other.every == every &&
      other.day == day &&
      other.early == early;

  @override
  int get hashCode => Object.hash(title, first, minutes, every, day, early);
}

/// The calendar of this phone (ADR 0025), where Birka keeps a calendar of its
/// own, «Birka». Its events remind of the payments even when the app is gone.
abstract interface class ReminderCalendar {
  /// Whether the phone lets Birka keep its calendar.
  Future<ReminderAccess> access();

  /// Asks the phone for the full access that the calendar needs, the first
  /// time with its own question, and gives the answer.
  Future<ReminderAccess> requestAccess();

  /// Puts [events] in place of the events of the calendar «Birka», and makes
  /// the calendar when it is not there.
  Future<void> write(List<CalendarReminder> events);

  /// Removes the calendar «Birka» with its events.
  Future<void> remove();

  /// Opens the settings of Birka on the phone, where the person allows its
  /// calendar and its notifications.
  Future<void> openSettings();
}

/// The reminders of [schedules] that come after [now], at [minutes] after
/// midnight, the earliest first: no more than [limit] and no later than
/// [days] days on (ADR 0025).
///
/// A payment reminds on the day of each of its times, the day before them or
/// never, as its `reminder` says, and an advance of a salary reminds as the
/// salary does. The times come from the rule of the payment, from its next
/// one on, so that a time that was posted or skipped reminds no more.
List<PlannedReminder> planReminders(
  List<Schedule> schedules, {
  required DateTime now,
  required int minutes,
  int limit = 60,
  int days = 92,
}) {
  final today = CivilDate.of(now);
  final last = today.addDays(days);
  final passed = now.hour * 60 + now.minute;
  final planned = <PlannedReminder>[
    for (final schedule in schedules)
      if (schedule.reminder != ScheduleReminder.none)
        for (final on in schedule.timesUntil(last.addDays(1)))
          if (_dayOf(schedule, on) case final day
              when day.compareTo(last) <= 0 &&
                  (day.compareTo(today) > 0 ||
                      (day == today && minutes > passed)))
            PlannedReminder(
              schedule: schedule,
              on: on,
              day: day,
              minutes: minutes,
            ),
  ]..sort(_earliest);
  return planned.length > limit ? planned.sublist(0, limit) : planned;
}

CivilDate _dayOf(Schedule schedule, CivilDate on) =>
    schedule.reminder == ScheduleReminder.dayBefore ? on.addDays(-1) : on;

int _earliest(PlannedReminder a, PlannedReminder b) {
  final byDay = a.day.compareTo(b.day);
  if (byDay != 0) return byDay;
  final byTime = a.on.compareTo(b.on);
  return byTime != 0 ? byTime : a.schedule.name.compareTo(b.schedule.name);
}
