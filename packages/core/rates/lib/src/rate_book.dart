import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart' show CategoryDayTotal, CivilDate;
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/src/rate_source.dart';
import 'package:rational/rational.dart';

/// A price in rubles and the day it was set for.
typedef _Price = (CivilDate, Decimal);

/// The rates that are known, and what an amount comes to in another currency.
///
/// Every rate is a price in rubles, so any two currencies meet through the
/// ruble (ADR 0012).
@immutable
final class RateBook {
  /// Creates a book of [days].
  factory RateBook(Iterable<DayRates> days) {
    final sorted = days.toList()..sort((a, b) => a.day.compareTo(b.day));
    final prices = <String, List<_Price>>{};
    for (final DayRates(:day, :rubles) in sorted) {
      for (final MapEntry(key: code, value: price) in rubles.entries) {
        (prices[code] ??= []).add((day, price));
      }
    }
    return RateBook._(prices, sorted.lastOrNull?.day);
  }

  const RateBook._(this._prices, this.latestDay);

  /// A book with no rates.
  const RateBook.empty() : _prices = const {}, latestDay = null;

  /// A stablecoin counts as what it is pegged to, until crypto has rates.
  static const _pegged = {'USDT': 'USD'};

  static const _ruble = 'RUB';

  /// The prices of each currency, the earliest first.
  final Map<String, List<_Price>> _prices;

  /// The day of the latest rates.
  final CivilDate? latestDay;

  /// Whether an amount in [from] can turn into [to].
  bool canConvert(Currency from, Currency to) =>
      from == to || (_rubles(from) != null && _rubles(to) != null);

  /// What [amount] comes to in [to], rounded half away from zero, or `null`
  /// when a rate is missing. It takes the rate of the day [on], and the latest
  /// one without it.
  Money? convert(Money amount, Currency to, {CivilDate? on}) {
    final exact = _exactly(amount, to, on);
    return exact == null ? null : _kept(exact.round(), to);
  }

  /// What [amounts] come to together in [to], as [convert] does. They add up
  /// exactly and round once, so that the total does not depend on how it is
  /// split. A total that took a rate is whole, since it is only as exact as the
  /// rate (ADR 0012).
  Money? sum(Iterable<Money> amounts, Currency to, {CivilDate? on}) =>
      _sum(amounts.map((amount) => (amount, on)), to);

  /// What [rows] come to together in [to], as [sum] does, each at the rate of
  /// its own day.
  Money? sumOfDays(Iterable<CategoryDayTotal> rows, Currency to) =>
      _sum(rows.map((row) => (row.total, row.day)), to);

  Money? _sum(Iterable<(Money, CivilDate?)> parts, Currency to) {
    var total = Rational.zero;
    var tookRate = false;
    for (final (amount, day) in parts) {
      final exact = _exactly(amount, to, day);
      if (exact == null) return null;
      total += exact;
      tookRate = tookRate || amount.currency != to;
    }
    return _kept(tookRate ? _whole(total, to) : total.round(), to);
  }

  /// [total] rounded to whole units of [to], in minor units. Less than one unit
  /// keeps its minor units, or else it would turn into nothing.
  static BigInt _whole(Rational total, Currency to) {
    final unit = BigInt.from(to.minorUnitsPerMajor);
    final units = total / Rational(unit);
    return units.abs() < Rational.one ? total.round() : units.round() * unit;
  }

  static Money _kept(BigInt rounded, Currency to) {
    final limit = BigInt.from(Money.maxMinorUnits);
    final kept = rounded.abs() > limit
        ? limit * BigInt.from(rounded.sign)
        : rounded;
    return Money(kept.toInt(), to);
  }

  /// [amount] in minor units of [to], before any rounding.
  Rational? _exactly(Money amount, Currency to, CivilDate? on) {
    final minorUnits = Rational(BigInt.from(amount.minorUnits));
    if (amount.currency == to) return minorUnits;
    final from = _rubles(amount.currency, on: on);
    final into = _rubles(to, on: on);
    if (from == null || into == null) return null;
    return minorUnits *
        from.toRational() /
        into.toRational() *
        _shift(to.decimalDigits - amount.currency.decimalDigits);
  }

  /// Ten to the power of [digits], which may be below zero.
  static Rational _shift(int digits) {
    final scale = BigInt.from(10).pow(digits.abs());
    return digits < 0 ? Rational(BigInt.one, scale) : Rational(scale);
  }

  /// The price of [currency] in rubles on the day [on], and the latest one
  /// without it. A day with no rate takes the last one before it, and a day
  /// before them all takes the first: a history that is still on its way must
  /// not leave a total without a value (ADR 0012).
  Decimal? _rubles(Currency currency, {CivilDate? on}) {
    final code = _pegged[currency.code] ?? currency.code;
    if (code == _ruble) return Decimal.one;
    final prices = _prices[code];
    if (prices == null) return null;
    if (on == null) return prices.last.$2;
    var low = 0;
    var high = prices.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (prices[middle].$1.compareTo(on) <= 0) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return prices[low == 0 ? 0 : low - 1].$2;
  }
}
