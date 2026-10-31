import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:overview_common/src/domain/capital.dart';

/// The name of [period] on its switch.
String periodLabel(OverviewPeriod period) => switch (period) {
  OverviewPeriod.week => t.overview.week,
  OverviewPeriod.month => t.overview.month,
  OverviewPeriod.year => t.overview.year,
};

/// The name of the month of [today], which heads the screen.
String monthTitle(CivilDate today) =>
    t.transactions.monthNames[today.month - 1];

/// What the change of the capital covers: `за неделю` or `за октябрь`.
String changeCaption(OverviewPeriod period, {required CivilDate today}) =>
    switch (period) {
      OverviewPeriod.week => t.overview.inWeek,
      OverviewPeriod.month => t.overview.changeIn[today.month - 1],
      OverviewPeriod.year => t.overview.inYear,
    };

/// `Капитал` for one currency and `Капитал · 3 валюты` for more.
String capitalLabel(int currencies) => currencies > 1
    ? '${t.overview.capital} · ${t.overview.currencies(n: currencies)}'
    : t.overview.capital;

/// `Траты в октябре`.
String spendingTitle(CivilDate today) =>
    t.overview.spendingIn(month: t.overview.monthsIn[today.month - 1]);

/// [change] with its sign.
String changeLabel(Money change) =>
    change.isPositive ? '+${formatMoney(change)}' : formatMoney(change);
