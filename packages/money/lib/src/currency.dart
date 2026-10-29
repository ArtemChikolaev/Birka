import 'package:meta/meta.dart';

/// A currency: an upper-case code and the number of digits in its minor unit.
///
/// ISO 4217 currencies come from [Currency.iso], which knows every currency
/// whose minor unit is not two digits: `JPY` has none, `KWD` has three.
/// Currencies outside ISO 4217, such as crypto assets, come from
/// [Currency.custom].
@immutable
final class Currency {
  const Currency._(this.code, this.decimalDigits);

  /// Returns the ISO 4217 currency with the three-letter [code].
  ///
  /// The code is case-insensitive. Throws a [FormatException] if [code] is
  /// not three Latin letters.
  factory Currency.iso(String code) {
    final normalized = code.trim().toUpperCase();
    if (!_isoCode.hasMatch(normalized)) {
      throw FormatException('Not an ISO 4217 currency code', code);
    }
    return Currency._(normalized, _isoExponents[normalized] ?? 2);
  }

  /// Returns a currency outside ISO 4217, for example `BTC` with 8 digits.
  ///
  /// The [code] is 2 to 10 upper-case letters or digits and should not reuse
  /// an ISO 4217 code. Throws an [ArgumentError] if [decimalDigits] is not
  /// between 0 and [maxDecimalDigits].
  factory Currency.custom(String code, {required int decimalDigits}) {
    if (!_customCode.hasMatch(code)) {
      throw FormatException('Not a currency code', code);
    }
    RangeError.checkValueInInterval(
      decimalDigits,
      0,
      maxDecimalDigits,
      'decimalDigits',
    );
    return Currency._(code, decimalDigits);
  }

  /// Russian ruble.
  static const rub = Currency._('RUB', 2);

  /// US dollar.
  static const usd = Currency._('USD', 2);

  /// Euro.
  static const eur = Currency._('EUR', 2);

  /// The most minor-unit digits a currency may have.
  ///
  /// An amount holds at most 2^53 − 1 minor units, so eight digits still
  /// allow about 90 million whole units — enough for Bitcoin.
  static const maxDecimalDigits = 8;

  static final _isoCode = RegExp(r'^[A-Z]{3}$');
  static final _customCode = RegExp(r'^[A-Z0-9]{2,10}$');

  /// ISO 4217 currencies whose minor unit is not two digits.
  static const _isoExponents = <String, int>{
    'BIF': 0,
    'CLP': 0,
    'DJF': 0,
    'GNF': 0,
    'ISK': 0,
    'JPY': 0,
    'KMF': 0,
    'KRW': 0,
    'PYG': 0,
    'RWF': 0,
    'UGX': 0,
    'UYI': 0,
    'VND': 0,
    'VUV': 0,
    'XAF': 0,
    'XOF': 0,
    'XPF': 0,
    'BHD': 3,
    'IQD': 3,
    'JOD': 3,
    'KWD': 3,
    'LYD': 3,
    'OMR': 3,
    'TND': 3,
    'CLF': 4,
    'UYW': 4,
  };

  /// The upper-case currency code, for example `RUB`.
  final String code;

  /// The number of digits after the decimal separator, for example 2 for RUB.
  final int decimalDigits;

  /// How many minor units make one major unit, for example 100 for RUB.
  int get minorUnitsPerMajor {
    var result = 1;
    for (var i = 0; i < decimalDigits; i++) {
      result *= 10;
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is Currency &&
      other.code == code &&
      other.decimalDigits == decimalDigits;

  @override
  int get hashCode => Object.hash(code, decimalDigits);

  @override
  String toString() => code;
}
