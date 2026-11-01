import 'package:money/src/currency.dart';

/// The currencies that Birka offers, for an account or for totals.
final List<Currency> offeredCurrencies = [
  Currency.rub,
  Currency.usd,
  Currency.eur,
  Currency.custom('USDT', decimalDigits: 6),
  Currency.iso('GEL'),
  Currency.iso('TRY'),
  Currency.iso('KZT'),
  Currency.iso('AED'),
  Currency.iso('THB'),
];
