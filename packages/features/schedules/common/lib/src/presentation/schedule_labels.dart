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
      ScheduleEvery.month => switch (schedule.advanceDay) {
        final advance? => t.schedules.everyTwice(
          advance: advance,
          day: schedule.day,
        ),
        null => t.schedules.everyMonth(day: schedule.day),
      },
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

/// The line under a regular payment in its list on the day something was
/// done to it: `проведён сегодня · следующий 25 декабря`, or `null` when
/// nothing was.
String? doneLine(Schedule schedule, CivilDate today) {
  final last = schedule.last;
  if (last == null || CivilDate.of(last.at.toLocal()) != today) return null;
  final date = fullDate(schedule.next, today);
  // A salary in halves names the half that went and the one that comes.
  if (schedule.advanceDay != null) {
    return schedule.isAdvance(last.on)
        ? switch (last.done) {
            ScheduleDone.posted => t.schedules.advancePosted(date: date),
            ScheduleDone.skipped => t.schedules.advanceSkipped(date: date),
            ScheduleDone.found => t.schedules.advanceFound(date: date),
          }
        : switch (last.done) {
            ScheduleDone.posted => t.schedules.restPosted(date: date),
            ScheduleDone.skipped => t.schedules.restSkipped(date: date),
            ScheduleDone.found => t.schedules.restFound(date: date),
          };
  }
  return switch (last.done) {
    ScheduleDone.posted => t.schedules.donePosted(date: date),
    ScheduleDone.skipped => t.schedules.doneSkipped(date: date),
    ScheduleDone.found => t.schedules.doneFound(date: date),
  };
}

/// What the page of the money until the salary says under the month start
/// (ADR 0024): that the months can start on the day of the monthly [salary],
/// with the month of [today] they would give. `null` without such a salary,
/// when the months start on its day already, or when its day is past the
/// 28th, which not every month has.
String? monthStartHint(
  Schedule? salary, {
  required CivilDate today,
  required int monthStart,
}) {
  if (salary == null ||
      salary.every != ScheduleEvery.month ||
      salary.day > 28 ||
      salary.day == monthStart) {
    return null;
  }
  final from = today.monthStart(salary.day);
  return t.schedules.monthStartHint(
    day: salary.day,
    month: t.imports.monthsWhole[from.month - 1],
    from: fullDate(from, today),
    to: fullDate(from.addMonths(1).addDays(-1), today),
  );
}

/// What a time [on] of [schedule] is called: «Аванс» for the advance of a
/// salary in halves, else the name of the payment.
String occurrenceName(Schedule schedule, CivilDate on) =>
    schedule.isAdvance(on) ? t.schedules.advance : schedule.name;

/// `Нашли «Аренда» в выписке Альфа-Банка`: the statement of [import], or of
/// no bank that Birka knows, brought the last times of [schedule].
String foundTitle(Schedule schedule, LedgerImport? import) {
  final bank = t.imports.formatsOf[import?.format];
  final name = occurrenceName(schedule, schedule.last?.on ?? schedule.next);
  return bank == null
      ? t.schedules.found(name: name)
      : t.schedules.foundOf(name: name, bank: bank);
}

/// `25 ноября · −45 000 ₽ · отметили платёж проведённым, копии не будет`:
/// the last time of [schedule] that a statement brought.
String foundText(Schedule schedule, CivilDate today) => t.schedules.foundText(
  date: fullDate(schedule.last?.on ?? schedule.next, today),
  amount: scheduleAmount(schedule),
);

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

/// What the form of a payment made from operation [made] says of it under its
/// day: `Яндекс Плюс · −449 ₽ · Подписки`, with the name of its [category].
String madeFromLine(Transaction made, {String? category}) {
  final amount = made.entries.first.amount.abs();
  final money = switch (made.kind) {
    TransactionKind.expense => formatMoney(-amount),
    TransactionKind.income => '+${formatMoney(amount)}',
    TransactionKind.transfer || TransactionKind.adjustment => formatMoney(
      amount,
    ),
  };
  final note = made.note.trim();
  return [if (note.isNotEmpty) note, money, ?category].join(' · ');
}

/// What the list of every payment shows as the amount of [schedule]: what
/// it brings or takes in a month when it comes in halves.
String scheduleTotal(Schedule schedule) => scheduleAmount(
  schedule,
  amount: schedule.advanceDay == null ? null : schedule.amount * 2,
);

/// What a toast says once the next time of [schedule] was posted with
/// [amount].
String postedLabel(Schedule schedule, Money amount) => t.schedules.posted(
  name: occurrenceName(schedule, schedule.next),
  amount: scheduleAmount(schedule, amount: amount),
);

/// What a toast says once the next time of [schedule] was skipped: when it
/// comes next.
String skippedLabel(Schedule schedule, CivilDate today) {
  final name = occurrenceName(schedule, schedule.next);
  final next = fullDate(schedule.after(schedule.next), today);
  return schedule.onDay == ScheduleOnDay.post
      ? t.schedules.skippedPost(name: name, date: next)
      : t.schedules.skippedAsk(name: name, date: next);
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
