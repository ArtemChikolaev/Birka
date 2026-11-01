import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/src/rate_book.dart';

/// What went through each category of [rows], in [target] wherever a rate can
/// take it there and in its own currency where none can yet. Each day goes
/// through its own rate, and a total that took a rate is whole: it is only as
/// exact as the rate. The biggest of each currency come first, and what a rate
/// turned into nothing stays out, since a total is above zero.
List<CategoryTotal> totalsIn(
  Currency? target,
  List<CategoryDayTotal> rows,
  RateBook rates,
) {
  final groups = <(String, Currency), List<CategoryDayTotal>>{};
  for (final row in rows) {
    final currency = _shownIn(row.total.currency, target, rates);
    (groups[(row.category.id, currency)] ??= []).add(row);
  }
  return [
    for (final MapEntry(key: (_, currency), value: parts) in groups.entries)
      if (rates.sumOfDays(parts, currency) case final total?
          when total.isPositive)
        CategoryTotal(parts.first.category, total),
  ]..sort(_byCurrencyAndSize);
}

/// What went through each month of [rows], one row for each month and currency,
/// the earliest first. It adds up what [totalsIn] gives, so that the bar of a
/// month is exactly the sum of its categories.
List<MonthTotal> monthTotalsIn(
  Currency? target,
  List<CategoryDayTotal> rows,
  RateBook rates,
) {
  final months = <CivilDate, List<CategoryDayTotal>>{};
  for (final row in rows) {
    (months[CivilDate(row.day.year, row.day.month, 1)] ??= []).add(row);
  }
  return [
    for (final MapEntry(key: month, value: days) in months.entries)
      ..._totalsOf(month, totalsIn(target, days, rates)),
  ]..sort((a, b) => a.month.compareTo(b.month));
}

Iterable<MonthTotal> _totalsOf(CivilDate month, List<CategoryTotal> totals) {
  final sums = <Currency, int>{};
  for (final CategoryTotal(:total) in totals) {
    sums[total.currency] = (sums[total.currency] ?? 0) + total.minorUnits;
  }
  return [
    for (final MapEntry(key: currency, value: sum) in sums.entries)
      MonthTotal(month, Money(sum.clamp(0, Money.maxMinorUnits), currency)),
  ];
}

Currency _shownIn(Currency currency, Currency? target, RateBook rates) =>
    target != null && rates.canConvert(currency, target) ? target : currency;

int _byCurrencyAndSize(CategoryTotal a, CategoryTotal b) {
  final currency = a.total.currency.code.compareTo(b.total.currency.code);
  if (currency != 0) return currency;
  final size = b.total.minorUnits.compareTo(a.total.minorUnits);
  return size != 0
      ? size
      : a.category.sortOrder.compareTo(b.category.sortOrder);
}
