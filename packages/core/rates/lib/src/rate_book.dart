import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/src/rate_source.dart';
import 'package:rational/rational.dart';

/// The rates that are known, and what an amount comes to in another currency.
///
/// Every rate is a price in rubles, so any two currencies meet through the
/// ruble (ADR 0012).
@immutable
final class RateBook {
  /// Creates a book of [days].
  RateBook(Iterable<DayRates> days)
    : _days = days.toList()..sort((a, b) => a.day.compareTo(b.day));

  /// A book with no rates.
  const RateBook.empty() : _days = const [];

  /// A stablecoin counts as what it is pegged to, until crypto has rates.
  static const _pegged = {'USDT': 'USD'};

  static const _ruble = 'RUB';

  /// The days, the earliest first.
  final List<DayRates> _days;

  /// The day of the latest rates.
  CivilDate? get latestDay => _days.lastOrNull?.day;

  /// Whether an amount in [from] can turn into [to].
  bool canConvert(Currency from, Currency to) =>
      from == to || (_rubles(from) != null && _rubles(to) != null);

  /// What [amount] comes to in [to] at the latest rate, rounded half away from
  /// zero, or `null` when a rate is missing.
  Money? convert(Money amount, Currency to) => sum([amount], to);

  /// What [amounts] come to together in [to]. They add up exactly and round
  /// once, so that the total does not depend on how it is split. Returns `null`
  /// when a rate is missing.
  Money? sum(Iterable<Money> amounts, Currency to) {
    var total = Rational.zero;
    for (final amount in amounts) {
      final exact = _exactly(amount, to);
      if (exact == null) return null;
      total += exact;
    }
    final rounded = total.round();
    final limit = BigInt.from(Money.maxMinorUnits);
    final kept = rounded.abs() > limit
        ? limit * BigInt.from(rounded.sign)
        : rounded;
    return Money(kept.toInt(), to);
  }

  /// [amount] in minor units of [to], before any rounding.
  Rational? _exactly(Money amount, Currency to) {
    final minorUnits = Rational(BigInt.from(amount.minorUnits));
    if (amount.currency == to) return minorUnits;
    final from = _rubles(amount.currency);
    final into = _rubles(to);
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

  /// The latest known price of [currency] in rubles.
  Decimal? _rubles(Currency currency) {
    final code = _pegged[currency.code] ?? currency.code;
    if (code == _ruble) return Decimal.one;
    for (final day in _days.reversed) {
      if (day.rubles[code] case final rubles?) return rubles;
    }
    return null;
  }
}
