import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/src/domain/reminders.dart';
import 'package:schedules_common/src/presentation/schedule_labels.dart';

/// `9:00`: [minutes] after midnight on a clock.
String clockLabel(int minutes) =>
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

/// The times of the day a reminder can come at: every hour from 6:00 to
/// 23:00, in minutes after midnight.
final List<int> reminderTimes = [
  for (var hour = 6; hour <= 23; hour++) hour * 60,
];

/// What the phone shows for [reminder] (ADR 0025): the name of the time and,
/// with [sums], its amount, and under it what a tap does.
ReminderNote reminderNote(PlannedReminder reminder, {required bool sums}) {
  final schedule = reminder.schedule;
  return ReminderNote(
    day: reminder.day,
    minutes: reminder.minutes,
    title: reminderTitle(schedule, reminder.on, sums: sums),
    body: reminder.early
        ? t.schedules.remindTomorrow(date: fullDate(reminder.on, reminder.day))
        : schedule.onDay == ScheduleOnDay.post
        ? t.schedules.remindTodayAuto
        : t.schedules.remindToday,
    tap: ReminderTap(schedule.id, early: reminder.early),
  );
}

/// `Аренда · 45 000 ₽`: the name of the time [on] of [schedule] and, with
/// [sums], its amount, as a reminder and an event of the calendar say it.
String reminderTitle(Schedule schedule, CivilDate on, {required bool sums}) {
  final name = occurrenceName(schedule, on);
  return sums ? '$name · ${reminderAmount(schedule)}' : name;
}

/// The events of the calendar «Birka» for [schedules] (ADR 0025): one for each
/// payment that reminds, and two for a salary in halves, the advance and the
/// rest, each on its own day of the month. They start at [minutes] after
/// midnight and say what the reminders say, with the amounts when [sums]
/// says so.
List<CalendarReminder> calendarReminders(
  List<Schedule> schedules, {
  required int minutes,
  required bool sums,
}) => [
  for (final schedule in schedules)
    if (schedule.reminder != ScheduleReminder.none)
      for (final (first, day) in _series(schedule))
        CalendarReminder(
          title: reminderTitle(schedule, first, sums: sums),
          first: first,
          minutes: minutes,
          every: schedule.every,
          day: day,
          early: schedule.reminder == ScheduleReminder.dayBefore,
        ),
];

/// The first time and the day of the month of each series of [schedule]: its
/// rule, or the advance and the rest of a salary in halves.
List<(CivilDate, int)> _series(Schedule schedule) {
  final advance = schedule.advanceDay;
  if (advance == null) return [(schedule.next, schedule.day)];
  // Its next two times are an advance and the rest, in either order.
  final next = schedule.next;
  final after = schedule.after(next);
  final (advanceOn, restOn) = schedule.isAdvance(next)
      ? (next, after)
      : (after, next);
  return [(advanceOn, advance), (restOn, schedule.day)];
}

/// `45 000 ₽` or `+60 000 ₽`: the amount of a time of [schedule] in a
/// reminder, with a sign only for what comes in.
String reminderAmount(Schedule schedule) => paymentAmount(
  schedule.amount,
  income: schedule.kind == TransactionKind.income,
);

/// The line under «Напомнить» in the form (ADR 0025): `25 ноября в 9:00 ·
/// напомнит Birka` for the first reminder of [schedule] still to come after
/// [now], with who reminds, or why nothing will remind. A time whose reminder
/// has passed, such as one of today with «За день», gives way to the next
/// time. [settings] are those of this device, `null` until they are read.
String reminderLine({
  required Schedule schedule,
  required ReminderSettings? settings,
  required DateTime now,
}) {
  final reminder = schedule.reminder;
  if (reminder == ScheduleReminder.none) return t.schedules.remindLineNone;
  if (settings == null || !settings.any) return t.schedules.remindLineOff;
  // A year and a day reach the next time of any rule.
  final first = planReminders(
    [schedule],
    now: now,
    minutes: settings.minutes,
    limit: 1,
    days: 367,
  ).firstOrNull;
  final next = schedule.next;
  final day =
      first?.day ??
      // Only a time more than a year away is left, and its day is to come.
      (reminder == ScheduleReminder.dayBefore ? next.addDays(-1) : next);
  return t.schedules.remindLine(
    date: fullDate(day, CivilDate.of(now)),
    time: clockLabel(settings.minutes),
    who: switch ((settings.notify, settings.calendar)) {
      (true, true) => t.schedules.remindByBoth,
      (false, true) => t.schedules.remindByCalendar,
      _ => t.schedules.remindByBirka,
    },
  );
}
