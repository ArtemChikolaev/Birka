import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:reports_common/src/domain/report.dart';
import 'package:reports_common/src/presentation/reports_cubit.dart';

/// The name of [kind] on the switch of the reports.
String kindLabel(CategoryKind kind) => switch (kind) {
  CategoryKind.expense => t.reports.expenses,
  CategoryKind.income => t.reports.income,
};

/// A month that starts on [month]: `Октябрь` or `October`, with the year when
/// it is not the year of [today].
String reportMonthLabel(CivilDate month, {required CivilDate today}) {
  final name = t.transactions.monthNames[month.month - 1];
  return month.year == today.year ? name : '$name ${month.year}';
}

/// The way to the report of [month]: `Отчёт за октябрь`, with the year when
/// it is not the year of [today].
String monthReportLabel(CivilDate month, {required CivilDate today}) {
  final label = t.reports.monthReport[month.month - 1];
  return month.year == today.year ? label : '$label ${month.year}';
}

/// [percent] with its sign: `+35%`, `−4%` or `0%`.
String percentLabel(int percent) {
  final sign = percent > 0
      ? '+'
      : percent < 0
      ? '−'
      : '';
  return '$sign${percent.abs()}%';
}

/// The change of a whole month: `+16% к сентябрю`.
String changeAgainst(int percent, {required CivilDate month}) {
  final before = monthsBefore(month, 1);
  return '${percentLabel(percent)} ${t.reports.against[before.month - 1]}';
}

/// What a month comes to on average: `в среднем 84 тыс. ₽`.
String averageLabel(String amount) => t.reports.average(amount: amount);

/// The short name of the month that starts on [month], under its bar.
String shortMonthLabel(CivilDate month) =>
    t.reports.monthsShort[month.month - 1];

/// What says that a month has nothing of [kind].
String emptyLabel(CategoryKind kind) => switch (kind) {
  CategoryKind.expense => t.reports.noExpenses,
  CategoryKind.income => t.reports.noIncome,
};

/// Choices of the six-month chart, including the uncategorized group.
Map<String?, String> historyCategoryLabels(Map<String, Category?> categories) =>
    {
      null: t.transactions.allCategories,
      for (final entry in categories.entries)
        entry.key: entry.value?.name ?? t.app.noCategory,
    };

/// The ledger caps each daily category total at the supported money bound.
/// At the bound the actual daily total may be larger.
String reportDayAmount(Money amount, {bool hidden = false}) =>
    !hidden && amount.minorUnits == Money.maxMinorUnits
    ? '≥ ${formatMoney(amount)}'
    : formatMoney(amount);

/// A full civil date for daily totals and report comparisons.
String reportDayLabel(CivilDate date, {required CivilDate today}) => dateLabel(
  year: date.year,
  month: date.month,
  day: date.day,
  thisYear: today.year,
);

/// The date ranges behind the category changes.
String changesPeriodLabel(ReportsState state) => t.reports.comparison(
  current: _period(state.month, state.comparisonEnd, today: state.today),
  previous: _period(state.previousStart, state.previousEnd, today: state.today),
);

String _period(CivilDate first, CivilDate last, {required CivilDate today}) {
  String day(CivilDate date) => reportDayLabel(date, today: today);
  if (first == last) return day(first);
  if (first.month != last.month || first.year != last.year) {
    return '${day(first)} – ${day(last)}';
  }
  final range = t.transactions.dayOfMonth(
    day: '${first.day}–${last.day}',
    month: t.transactions.months[first.month - 1],
  );
  return first.year == today.year ? range : '$range ${first.year}';
}
