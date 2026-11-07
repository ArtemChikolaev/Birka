import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/src/domain/payday_settings.dart';
import 'package:schedules_common/src/domain/spending_plan.dart';

const _weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

/// `ср`: the day of the week of [day], short.
String weekdayLabel(CivilDate day) =>
    t.schedules.weekday[_weekdays[day.weekday - 1]] ?? '';

/// `25 ноя`: [day] with its month short.
String shortDate(CivilDate day) =>
    '${day.day} ${t.schedules.monthsShort[day.month - 1]}';

/// `25 ноября`, with the year when it is not the year of [today].
String fullDate(CivilDate day, CivilDate today) => dateLabel(
  year: day.year,
  month: day.month,
  day: day.day,
  thisYear: today.year,
);

/// `сегодня`, `завтра` or `25 ноября`.
String dayLabel(CivilDate day, CivilDate today) {
  if (day == today) return t.schedules.today;
  if (day == today.addDays(1)) return t.schedules.tomorrow;
  return fullDate(day, today);
}

/// How often [schedule] comes: `каждый месяц 25-го`, `каждую неделю, по
/// средам` or `раз в год, 12 марта`.
String everyLabel(Schedule schedule, CivilDate today) =>
    switch (schedule.every) {
      ScheduleEvery.month => t.schedules.everyMonth(day: schedule.day),
      ScheduleEvery.week => t.schedules.everyWeek(
        weekday: t.schedules.on[_weekdays[schedule.next.weekday - 1]] ?? '',
      ),
      ScheduleEvery.year => t.schedules.everyYear(
        date: dateLabel(
          year: today.year,
          month: schedule.next.month,
          day: schedule.day,
          thisYear: today.year,
        ),
      ),
    };

/// The line under a regular payment in its list: `каждый месяц 25-го ·
/// спросить`.
String scheduleLine(Schedule schedule, CivilDate today) {
  final posts = schedule.onDay == ScheduleOnDay.post;
  return '${everyLabel(schedule, today)} · '
      '${posts ? t.schedules.posts : t.schedules.asks}';
}

/// The amount of [schedule] as its transactions show it: `−45 000 ₽`,
/// `+120 000 ₽`, or `10 000 ₽` for a transfer.
String scheduleAmount(Schedule schedule, {Money? amount}) {
  final money = amount ?? schedule.amount;
  return switch (schedule.kind) {
    TransactionKind.expense => formatMoney(-money),
    TransactionKind.income => '+${formatMoney(money)}',
    TransactionKind.transfer || TransactionKind.adjustment => formatMoney(
      money,
    ),
  };
}

/// What a toast says once [schedule] was posted with [amount].
String postedLabel(Schedule schedule, Money amount) => t.schedules.posted(
  name: schedule.name,
  amount: scheduleAmount(schedule, amount: amount),
);

/// What a toast says once [schedule] was skipped: when it comes next.
String skippedLabel(Schedule schedule, CivilDate today) {
  final next = fullDate(schedule.after(schedule.next), today);
  return schedule.onDay == ScheduleOnDay.post
      ? t.schedules.skippedPost(name: schedule.name, date: next)
      : t.schedules.skippedAsk(name: schedule.name, date: next);
}

/// The days of [plan] for people: `до зарплаты 5 декабря · 17 дней` or
/// `до 30 ноября · 13 дней`.
String planPeriodLabel(SpendingPlan plan) {
  final days = t.schedules.days(n: plan.days);
  final payday = plan.payday;
  return plan.until == SpendUntil.payday && payday != null
      ? t.schedules.untilPayday(date: fullDate(payday, plan.today), days: days)
      : t.schedules.untilDate(date: fullDate(plan.end, plan.today), days: days);
}

/// What the card of the money of the day says under its bar: `Потратили
/// 620 ₽ · до зарплаты 17 дней`, or what tomorrow allows once today took
/// more than its share.
String spentLabel(SpendingPlan plan) {
  final spent = formatMoney(plan.spentToday);
  if (plan.over) {
    return t.schedules.spentOver(
      amount: spent,
      tomorrow: formatMoney(plan.tomorrow),
    );
  }
  final days = t.schedules.days(n: plan.today.daysUntil(plan.end) + 1);
  return plan.until == SpendUntil.payday
      ? t.schedules.spentUntilPayday(amount: spent, days: days)
      : t.schedules.spentUntilMonth(amount: spent, days: days);
}
