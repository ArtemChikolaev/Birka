import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// How far back the chart of the capital looks.
enum OverviewPeriod {
  /// The last seven days.
  week,

  /// The month so far.
  month,

  /// The last twelve months.
  year
  ;

  /// The day whose end the chart starts from, when today is [today].
  CivilDate startFrom(CivilDate today) => switch (this) {
    week => _date(today.year, today.month, today.day - 7),
    month => _date(today.year, today.month, 0),
    year => _date(today.year - 1, today.month, today.day),
  };

  /// The earliest day any period needs, when today is [today].
  static CivilDate earliest(CivilDate today) => year.startFrom(today);
}

CivilDate _date(int year, int month, int day) =>
    CivilDate.of(DateTime.utc(year, month, day));

/// What [accounts] hold, one amount for each currency in the order of the
/// accounts. Accounts outside the totals do not count. Adding currencies up has
/// to wait for exchange rates.
List<Money> capitalOf(List<AccountBalance> accounts) {
  final sums = <Currency, int>{};
  for (final AccountBalance(:account, :balance) in accounts) {
    if (!account.includeInTotals) continue;
    sums[balance.currency] = (sums[balance.currency] ?? 0) + balance.minorUnits;
  }
  return [
    for (final MapEntry(key: currency, value: sum) in sums.entries)
      Money(sum.clamp(-Money.maxMinorUnits, Money.maxMinorUnits), currency),
  ];
}

/// What the money in the currency of [now] came to at the end of each day from
/// [start] to [today], in minor units: the capital of today, with what each day
/// changed taken back.
List<int> capitalHistory({
  required Money now,
  required List<DayChange> changes,
  required CivilDate start,
  required CivilDate today,
}) {
  final byDay = {
    for (final DayChange(:day, :change) in changes)
      if (change.currency == now.currency) day: change.minorUnits,
  };
  final first = DateTime.utc(start.year, start.month, start.day);
  final last = DateTime.utc(today.year, today.month, today.day);
  final values = List.filled(last.difference(first).inDays + 1, 0);
  var value = now.minorUnits;
  for (var index = values.length - 1; index >= 0; index--) {
    values[index] = value;
    value -= byDay[_date(start.year, start.month, start.day + index)] ?? 0;
  }
  return values;
}
