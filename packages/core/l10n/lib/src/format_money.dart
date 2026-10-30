import 'package:l10n/src/generated/strings.g.dart';
import 'package:money/money.dart';

const _noBreakSpace = '\u00A0';
const _minus = '\u2212';

/// The currencies with a sign of their own that both fonts of the design
/// system can draw. The rest show their code.
const _symbols = {'RUB': '₽', 'USD': r'$', 'EUR': '€', 'GBP': '£', 'JPY': '¥'};

/// Formats [amount] for people in the current language, or in [locale].
///
/// Russian gives `1 284 560,50 ₽` and English `₽1,284,560.50`. A currency
/// without a sign of its own gives `1 250 AED` in both. The digits come from
/// the minor units as they are, and a fraction of zeros is left out, so
/// `412300.00` reads `412 300 ₽`.
String formatMoney(Money amount, {AppLocale? locale}) {
  final russian = (locale ?? LocaleSettings.currentLocale) == AppLocale.ru;
  final [whole, ...fraction] = amount.abs().toDecimalString().split('.');
  final digits = _group(whole, separator: russian ? _noBreakSpace : ',');
  final decimals = fraction.isEmpty || int.parse(fraction.single) == 0
      ? ''
      : '${russian ? ',' : '.'}${fraction.single}';
  final number = '$digits$decimals';
  final symbol = _symbols[amount.currency.code];
  final text = switch (symbol) {
    null => '$number$_noBreakSpace${amount.currency.code}',
    _ when russian => '$number$_noBreakSpace$symbol',
    _ => '$symbol$number',
  };
  return amount.isNegative ? '$_minus$text' : text;
}

String _group(String digits, {required String separator}) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(separator);
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
