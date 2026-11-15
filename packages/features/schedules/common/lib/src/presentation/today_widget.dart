import 'dart:math' as math;

import 'package:home_screen/home_screen.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/src/domain/payday_settings.dart';
import 'package:schedules_common/src/domain/spending_plan.dart';
import 'package:schedules_common/src/presentation/schedules_cubit.dart';

/// The figures of [view] for the widgets of the home screen (ADR 0031):
/// today, and tomorrow as if nothing more is spent today, so that the
/// widgets turn to the next day at midnight on their own. The last day
/// before the salary leaves tomorrow to the plan that the salary starts.
/// Without a salary to count until they show what today took. With [sums]
/// off the amounts are dots before they leave the app.
WidgetSnapshot todayWidgetSnapshot(SchedulesView view, {required bool sums}) {
  final base = view.base;
  if (base == null) return WidgetSnapshot(days: const [], sums: sums);
  final zero = Money(0, base);
  final plan = view.plan;
  if (plan == null) {
    // What today took counts the same until the end of the month.
    final spent =
        SpendingPlan.of(
          today: view.today,
          until: SpendUntil.monthEnd,
          currency: base,
          schedules: view.schedules,
          counted: view.counted,
          todays: view.todays,
          aside: Money(view.settings.asideMinor, base),
          monthStart: view.monthStart,
        )?.spentToday ??
        zero;
    return WidgetSnapshot(
      sums: sums,
      days: [
        _spentDay(view.today, spent, sums: sums),
        _spentDay(view.today.addDays(1), zero, sums: sums),
      ],
    );
  }
  return WidgetSnapshot(
    sums: sums,
    days: [
      _planDay(
        plan.today,
        left: plan.leftToday,
        perDay: plan.perDay,
        spent: plan.spentToday,
        tomorrow: plan.tomorrow,
        sums: sums,
      ),
      if (plan.days > 1)
        _planDay(
          plan.today.addDays(1),
          left: plan.tomorrow,
          perDay: plan.tomorrow,
          spent: zero,
          tomorrow: plan.tomorrow,
          sums: sums,
        ),
    ],
  );
}

WidgetDay _planDay(
  CivilDate day, {
  required Money left,
  required Money perDay,
  required Money spent,
  required Money tomorrow,
  required bool sums,
}) {
  final over = left.isNegative;
  final words = t.schedules.widget;
  String shown(String text) => sums ? text : maskAmounts(text);
  final share = perDay.isPositive
      ? math.min(1, spent.minorUnits / perDay.minorUnits).toDouble()
      : (spent.isPositive ? 1.0 : 0.0);
  return WidgetDay(
    day: '$day',
    kind: over ? WidgetDayKind.over : WidgetDayKind.plan,
    label: over ? t.schedules.overToday : t.schedules.canSpend,
    labelShort: over ? words.overShort : words.canSpendShort,
    figure: shown(formatMoney(left)),
    value: sums ? _units(left) : null,
    of: shown(t.schedules.ofPerDay(amount: formatMoney(perDay))),
    ofShort: shown(words.of(amount: formatMoney(perDay))),
    spent: shown(
      over
          ? words.tomorrow(amount: formatMoney(tomorrow))
          : words.spent(amount: formatMoney(spent)),
    ),
    spentShort: shown(
      over
          ? words.tomorrowShort(amount: formatMoney(tomorrow))
          : words.spentShort(amount: formatMoney(spent)),
    ),
    share: over ? 1 : share,
  );
}

WidgetDay _spentDay(CivilDate day, Money spent, {required bool sums}) {
  final words = t.schedules.widget;
  final figure = formatMoney(spent);
  return WidgetDay(
    day: '$day',
    kind: WidgetDayKind.spent,
    label: words.spentToday,
    labelShort: words.spentTodayShort,
    figure: sums ? figure : maskAmounts(figure),
    value: sums ? _units(spent) : null,
    of: words.noPayday,
    ofShort: words.today,
    spent: '',
    spentShort: '',
    share: 0,
  );
}

/// [amount] in whole units of its currency, which a widget rolls to.
double _units(Money amount) =>
    amount.minorUnits / math.pow(10, amount.currency.decimalDigits);
