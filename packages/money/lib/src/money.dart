import 'package:meta/meta.dart';
import 'package:money/src/currency.dart';

/// An exact amount of money: a whole number of minor units of a [Currency].
///
/// 12.34 RUB is stored as 1234 kopecks. Arithmetic never uses `double`, and
/// every amount stays within ±[maxMinorUnits], the largest integer that
/// JavaScript represents exactly, so the VM, dart2js and dart2wasm builds
/// always agree. Operations that would leave that range throw a
/// [RangeError] instead of losing precision.
@immutable
final class Money implements Comparable<Money> {
  /// Creates an amount of [minorUnits] in [currency].
  ///
  /// Throws a [RangeError] if [minorUnits] is outside ±[maxMinorUnits].
  Money(this.minorUnits, this.currency) {
    _checkRange(minorUnits);
  }

  /// A zero amount in [currency].
  const Money.zero(this.currency) : minorUnits = 0;

  /// Parses a plain decimal string such as `1234.56`, `-0.5` or `100`.
  ///
  /// Accepts an optional sign and either `.` or `,` as the decimal
  /// separator. Grouping separators are not accepted, and more fraction
  /// digits than [currency] has are rejected instead of rounded. Throws a
  /// [FormatException] on invalid or out-of-range input.
  factory Money.parse(String input, Currency currency) {
    final match = _decimal.firstMatch(input.trim());
    if (match == null) {
      throw FormatException('Not a decimal amount', input);
    }
    final fraction = match.group(3) ?? '';
    if (fraction.length > currency.decimalDigits) {
      throw FormatException(
        'More fraction digits than ${currency.code} has',
        input,
      );
    }
    final digits =
        match.group(2)! + fraction.padRight(currency.decimalDigits, '0');
    var value = BigInt.parse(digits);
    if (match.group(1) == '-') value = -value;
    if (value.abs() > BigInt.from(maxMinorUnits)) {
      throw FormatException('Amount is out of range', input);
    }
    return Money(value.toInt(), currency);
  }

  /// The largest amount in minor units that every platform represents
  /// exactly: 2^53 − 1.
  static const maxMinorUnits = 9007199254740991;

  static final _decimal = RegExp(r'^([+-]?)(\d+)(?:[.,](\d+))?$');

  /// The amount in minor units, for example kopecks or cents.
  final int minorUnits;

  /// The currency of the amount.
  final Currency currency;

  /// Whether the amount is zero.
  bool get isZero => minorUnits == 0;

  /// Whether the amount is below zero.
  bool get isNegative => minorUnits < 0;

  /// Whether the amount is above zero.
  bool get isPositive => minorUnits > 0;

  /// Adds [other], which must be in the same currency.
  Money operator +(Money other) {
    _checkSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency);
  }

  /// Subtracts [other], which must be in the same currency.
  Money operator -(Money other) {
    _checkSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency);
  }

  /// The same amount with the opposite sign.
  Money operator -() => Money(-minorUnits, currency);

  /// Multiplies the amount by a whole [factor], for example a quantity.
  ///
  /// The range is checked before multiplying: on the VM a 64-bit product
  /// could wrap around silently.
  Money operator *(int factor) {
    if (factor != 0 && minorUnits.abs() > maxMinorUnits ~/ factor.abs()) {
      throw RangeError('$this * $factor is out of range');
    }
    return Money(minorUnits * factor, currency);
  }

  /// Whether this amount is less than [other], in the same currency.
  bool operator <(Money other) => compareTo(other) < 0;

  /// Whether this amount is at most [other], in the same currency.
  bool operator <=(Money other) => compareTo(other) <= 0;

  /// Whether this amount is greater than [other], in the same currency.
  bool operator >(Money other) => compareTo(other) > 0;

  /// Whether this amount is at least [other], in the same currency.
  bool operator >=(Money other) => compareTo(other) >= 0;

  /// The amount without its sign.
  Money abs() => isNegative ? -this : this;

  /// Splits the amount in proportion to [ratios] without losing a minor
  /// unit.
  ///
  /// Each part first gets its exact share rounded toward zero. The minor
  /// units left over go one by one to the parts whose shares lost the most
  /// in that rounding, earlier parts first on a tie (the largest remainder
  /// method). So every part is its exact share rounded down or up, and the
  /// parts always add up to this amount: 100.00 split by `[1, 1, 1]` gives
  /// 33.34, 33.33 and 33.33.
  ///
  /// Throws an [ArgumentError] if [ratios] is empty, contains a negative
  /// number or adds up to zero.
  List<Money> allocate(List<int> ratios) {
    if (ratios.isEmpty) {
      throw ArgumentError.value(ratios, 'ratios', 'Must not be empty');
    }
    if (ratios.any((ratio) => ratio < 0)) {
      throw ArgumentError.value(ratios, 'ratios', 'Must not be negative');
    }
    final total = ratios.fold(BigInt.zero, (sum, r) => sum + BigInt.from(r));
    if (total == BigInt.zero) {
      throw ArgumentError.value(ratios, 'ratios', 'Must not add up to zero');
    }
    // BigInt keeps `amount × ratio` exact on the web, where int is a double.
    final amount = BigInt.from(minorUnits);
    final shares = <int>[];
    final lost = <BigInt>[];
    for (final ratio in ratios) {
      final scaled = amount * BigInt.from(ratio);
      shares.add((scaled ~/ total).toInt());
      lost.add(scaled.remainder(total).abs());
    }
    final allocated = shares.fold<int>(0, (sum, share) => sum + share);
    var leftover = minorUnits - allocated;
    final byLoss = List.generate(shares.length, (i) => i)
      ..sort((a, b) {
        final order = lost[b].compareTo(lost[a]);
        return order != 0 ? order : a.compareTo(b);
      });
    for (final i in byLoss) {
      if (leftover == 0) break;
      shares[i] += leftover.sign;
      leftover -= leftover.sign;
    }
    return [for (final share in shares) Money(share, currency)];
  }

  /// Splits the amount into [parts] equal parts; see [allocate].
  List<Money> split(int parts) {
    if (parts < 1) {
      throw RangeError.value(parts, 'parts', 'Must be at least 1');
    }
    return allocate(List.filled(parts, 1));
  }

  /// The amount as a plain decimal string, for example `-1234.50`.
  ///
  /// This is a machine format for storage and tests. Formatting for people,
  /// with grouping, symbols and locales, belongs to the localization layer.
  String toDecimalString() {
    final sign = isNegative ? '-' : '';
    final absolute = minorUnits.abs();
    final digits = currency.decimalDigits;
    if (digits == 0) return '$sign$absolute';
    final perMajor = currency.minorUnitsPerMajor;
    final fraction = (absolute % perMajor).toString().padLeft(digits, '0');
    return '$sign${absolute ~/ perMajor}.$fraction';
  }

  @override
  int compareTo(Money other) {
    _checkSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => '${toDecimalString()} ${currency.code}';

  void _checkSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError.value(
        other,
        'other',
        'Expected an amount in ${currency.code}',
      );
    }
  }

  static void _checkRange(int minorUnits) {
    if (minorUnits > maxMinorUnits || minorUnits < -maxMinorUnits) {
      throw RangeError.range(
        minorUnits,
        -maxMinorUnits,
        maxMinorUnits,
        'minorUnits',
      );
    }
  }
}
