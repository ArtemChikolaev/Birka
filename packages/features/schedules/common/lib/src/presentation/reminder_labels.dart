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
  final name = occurrenceName(schedule, reminder.on);
  return ReminderNote(
    day: reminder.day,
    minutes: reminder.minutes,
    title: sums ? '$name · ${reminderAmount(schedule)}' : name,
    body: reminder.early
        ? t.schedules.remindTomorrow(date: fullDate(reminder.on, reminder.day))
        : schedule.onDay == ScheduleOnDay.post
        ? t.schedules.remindTodayAuto
        : t.schedules.remindToday,
    tap: ReminderTap(schedule.id, early: reminder.early),
  );
}

/// `45 000 ₽` or `+60 000 ₽`: the amount of a time of [schedule] in a
/// reminder, with a sign only for what comes in.
String reminderAmount(Schedule schedule) =>
    schedule.kind == TransactionKind.income
    ? '+${formatMoney(schedule.amount)}'
    : formatMoney(schedule.amount);

/// The line under «Напомнить» in the form (ADR 0025): `25 ноября в 9:00 ·
/// напомнит Birka` for the [next] time, or why nothing will remind.
/// [settings] are those of this device, `null` until they are read.
String reminderLine({
  required ScheduleReminder reminder,
  required ReminderSettings? settings,
  required CivilDate next,
  required CivilDate today,
}) {
  if (reminder == ScheduleReminder.none) return t.schedules.remindLineNone;
  if (settings == null || !settings.notify) return t.schedules.remindLineOff;
  final day = reminder == ScheduleReminder.dayBefore ? next.addDays(-1) : next;
  return t.schedules.remindLine(
    date: fullDate(day, today),
    time: clockLabel(settings.minutes),
  );
}
