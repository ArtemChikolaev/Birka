import 'package:money/money.dart';

/// The currencies the form offers for a new account.
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
