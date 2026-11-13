import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The name of the month of [today], which heads the screen.
String monthTitle(CivilDate today) =>
    t.transactions.monthNames[today.month - 1];

/// `Капитал` for one currency and `Капитал · 3 валюты` for more.
String capitalLabel(int currencies) => currencies > 1
    ? '${t.overview.capital} · ${t.overview.currencies(n: currencies)}'
    : t.overview.capital;

/// `Курс ЦБ РФ на 31 октября`: the day of the rates behind the capital.
String rateNote(CivilDate day) => t.overview.rateOn(
  day: t.transactions.dayOfMonth(
    day: day.day,
    month: t.transactions.months[day.month - 1],
  ),
);

/// `Траты в октябре`.
String spendingTitle(CivilDate today) =>
    t.overview.spendingIn(month: t.overview.monthsIn[today.month - 1]);

/// [change] with its sign.
String changeLabel(Money change) => signedMoney(change);
