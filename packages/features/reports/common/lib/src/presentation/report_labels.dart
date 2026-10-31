import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:reports_common/src/domain/report.dart';

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
