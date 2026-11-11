import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/src/domain/payday_settings.dart';
import 'package:schedules_common/src/domain/repeat_finds.dart';
import 'package:schedules_common/src/domain/rough_money.dart';
import 'package:schedules_common/src/domain/spending_plan.dart';
import 'package:schedules_common/src/domain/usual_pace.dart';
import 'package:schedules_common/src/presentation/schedule_form_cubit.dart';
import 'package:schedules_common/src/presentation/schedules_cubit.dart';

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
/// nothing was, as on the day it was made from an operation.
String? doneLine(Schedule schedule, CivilDate today) {
  final last = schedule.last;
  if (last == null || CivilDate.of(last.at.toLocal()) != today) return null;
  // The operation that the payment was made from is no post of today: the
  // new payment says how it comes instead.
  if (last.transactionId case final id? when id == schedule.madeFrom) {
    return null;
  }
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

/// `Дом · Зарплатная карта`: the category of [schedule] and its account, or
/// both accounts of a transfer.
String scheduleWhere(SchedulesView view, Schedule schedule) {
  final from = view.accountsById[schedule.accountId]?.name ?? '';
  if (schedule.kind == TransactionKind.transfer) {
    final to = view.accountsById[schedule.toAccountId]?.name ?? '';
    return '$from → $to';
  }
  final category = view.categories[schedule.categoryId]?.name;
  return category == null ? from : '$category · $from';
}

/// What a time [on] of [schedule] is called: «Аванс» for the advance of a
/// salary in halves, else the name of the payment.
String occurrenceName(Schedule schedule, CivilDate on) =>
    schedule.isAdvance(on) ? t.schedules.advance : schedule.name;

/// `−45 000 ₽` or `+40 000 ₽`: what the time [on] of [schedule] brings or
/// takes, the advance of its own included.
String occurrenceAmount(Schedule schedule, CivilDate on) =>
    scheduleAmount(schedule, amount: schedule.amountOn(on));

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
  amount: occurrenceAmount(schedule, schedule.last?.on ?? schedule.next),
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

/// When [find] comes and how many months it came: `12-го · 4 раза подряд`,
/// or `около 10-го · 3 раза` when its amount changes.
String findLine(RepeatFind find) {
  final count = find.times.length;
  return find.varies
      ? t.schedules.findLineVaries(
          n: count,
          day: find.day,
          count: formatCount(count),
        )
      : t.schedules.findLine(
          n: count,
          day: find.day,
          count: formatCount(count),
        );
}

/// The days of [find] on the card of the form made from it, with the name of
/// its [category]: `12 авг, 12 сен, 12 окт, 12 ноя · Подписки`.
String findDaysLine(RepeatFind find, {String? category}) => [
  [for (final time in find.times) shortDate(time.occurredOn)].join(', '),
  ?category,
].join(' · ');

/// What [find] takes or brings: `−449 ₽`, `+40 000 ₽`, or `≈ −6 800 ₽` when
/// its amount changes.
String findAmount(RepeatFind find) {
  final amount = switch (find.kind) {
    TransactionKind.income => '+${formatMoney(find.amount)}',
    _ => formatMoney(-find.amount),
  };
  return find.varies ? '≈\u00A0$amount' : amount;
}

/// What the list of every payment shows as the amount of [schedule]: what
/// it brings or takes in a month when it comes twice a month.
String scheduleTotal(Schedule schedule) =>
    scheduleAmount(schedule, amount: schedule.monthAmount);

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

/// What the accounts hold at the end of [plan], before everyday spending:
/// with the advances that come before it, which the line says.
String leftAfterLabel(SpendingPlan plan, CivilDate today) {
  final amount = formatMoney(plan.morning + plan.advanced - plan.paid);
  final advance = plan.advances.isNotEmpty;
  return switch (plan.payday) {
    final payday? when plan.until == SpendUntil.payday =>
      advance
          ? t.schedules.leftAfterPaydayAdvance(
              date: fullDate(payday, today),
              amount: amount,
            )
          : t.schedules.leftAfterPayday(
              date: fullDate(payday, today),
              amount: amount,
            ),
    _ =>
      advance
          ? t.schedules.leftAfterMonthAdvance(amount: amount)
          : t.schedules.leftAfterMonth(amount: amount),
  };
}

/// What the amount of a payment made from the operations that came every
/// month says while it is the last of their amounts, which changed:
/// `последняя сумма · бывало от 6 410 ₽ до 7 120 ₽`.
String? foundRangeLabel(ScheduleFormState state) {
  final found = state.found;
  if (found == null || !found.varies) return null;
  if (state.amountMinor != found.amounts.last.minorUnits) return null;
  final range = found.range;
  return t.schedules.amountRange(
    min: formatMoney(range.min),
    max: formatMoney(range.max),
  );
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

/// The day that [plan] counts to in a forecast: the payday, or the last day
/// of the month.
CivilDate _forecastDay(SpendingPlan plan) => switch (plan.payday) {
  final payday? when plan.until == SpendUntil.payday => payday,
  _ => plan.end,
};

/// Whether [plan] counts until the salary.
bool _untilPayday(SpendingPlan plan) =>
    plan.until == SpendUntil.payday && plan.payday != null;

/// What [forecast] says first: `Деньги кончатся 2 декабря`, `Хватит до
/// зарплаты` or `Денег не хватает уже сейчас`.
String forecastTitle(SpendingForecast forecast) {
  final plan = forecast.plan;
  if (forecast.none) return t.schedules.forecastNone;
  if (forecast.runsOut case final day?) {
    return t.schedules.forecastRunsOut(date: fullDate(day, plan.today));
  }
  return _untilPayday(plan)
      ? t.schedules.forecastLastsPayday
      : t.schedules.forecastLastsMonth;
}

/// The figures of [forecast]: `Обычно вы тратите ≈ 2 100 ₽ в день, а можно
/// 1 744 ₽. К 5 декабря не хватит ≈ 6 000 ₽.`
String forecastText(SpendingForecast forecast) {
  final plan = forecast.plan;
  if (forecast.none) {
    return _untilPayday(plan)
        ? t.schedules.forecastNonePayday
        : t.schedules.forecastNoneMonth;
  }
  final usual = formatMoney(roughly(forecast.usual));
  final date = fullDate(_forecastDay(plan), plan.today);
  final amount = formatMoney(roughly(forecast.left.abs()));
  return forecast.short
      ? t.schedules.forecastShortText(
          usual: usual,
          perDay: formatMoney(plan.perDay),
          date: date,
          amount: amount,
        )
      : t.schedules.forecastLeftText(usual: usual, date: date, amount: amount);
}

/// [forecast] in one line of the card of the overview: `Как обычно —
/// деньги кончатся 2 декабря`, or `null` when the payments take all the
/// money already, which the card says itself.
String? forecastLine(SpendingForecast forecast) {
  final plan = forecast.plan;
  if (forecast.none) return null;
  if (forecast.runsOut case final day?) {
    return t.schedules.forecastLineRunsOut(date: fullDate(day, plan.today));
  }
  return _untilPayday(plan)
      ? t.schedules.forecastLinePayday
      : t.schedules.forecastLineMonth;
}

/// The last day of the chart of a forecast: `5 дек · зарплата` or `30 ноя`.
String forecastEnd(SpendingPlan plan) => _untilPayday(plan)
    ? t.schedules.forecastPayday(date: shortDate(plan.payday!))
    : shortDate(plan.end);

/// What the line of the plan on the chart stands for: `по плану: 1 744 ₽ в
/// день`.
String forecastPlan(SpendingPlan plan) => plan.free.isPositive
    ? t.schedules.forecastPlan(amount: formatMoney(plan.perDay))
    : t.schedules.forecastPlanBare;
