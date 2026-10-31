import 'package:l10n/src/generated/strings.g.dart';
import 'package:money/money.dart';

const _noBreakSpace = '\u00A0';
const _minus = '\u2212';

/// The currencies with a sign of their own that both fonts of the design
/// system can draw. The rest show their code.
const _symbols = {'RUB': '₽', 'USD': r'$', 'EUR': '€', 'GBP': '£', 'JPY': '¥'};

/// The mark between the whole part and the fraction in the current language.
String get decimalSeparator =>
    LocaleSettings.currentLocale == AppLocale.ru ? ',' : '.';

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

/// Formats [amount] for a small place, without its sign and in whole units:
/// Russian gives `84 тыс. ₽` and `1,2 млн ₽`, and English `₽84k` and `₽1.2M`.
/// Below a thousand it gives the units as they are.
String formatCompactMoney(Money amount, {AppLocale? locale}) {
  final russian = (locale ?? LocaleSettings.currentLocale) == AppLocale.ru;
  final (number, unit) = _compact(amount, separator: russian ? ',' : '.');
  final figure = switch (unit) {
    null => number,
    _ when russian => '$number$_noBreakSpace${_russianUnits[unit]}',
    _ => '$number${_latinUnits[unit]}',
  };
  final symbol = _symbols[amount.currency.code];
  return switch (symbol) {
    null => '$figure$_noBreakSpace${amount.currency.code}',
    _ when russian => '$figure$_noBreakSpace$symbol',
    _ => '$symbol$figure',
  };
}

/// [amount] as a bare figure for a tight place, such as over a bar of a chart:
/// `78k` and `1.2M` in every language, with the mark of the current one.
String formatCompactFigure(Money amount) {
  final (number, unit) = _compact(amount, separator: decimalSeparator);
  return unit == null ? number : '$number${_latinUnits[unit]}';
}

const _russianUnits = ['тыс.', 'млн', 'млрд'];
const _latinUnits = ['k', 'M', 'B'];

/// The whole units of [amount] in thousands, millions or billions, with one
/// digit after the mark while the number is small, and which of them it is.
(String, int?) _compact(Money amount, {required String separator}) {
  final units = amount.abs().minorUnits ~/ amount.currency.minorUnitsPerMajor;
  if (units < 1000) return ('$units', null);
  var unit = 0;
  var scale = 1000;
  // Rounds up into the next unit before it shows as 1000 тыс.
  while (unit < _latinUnits.length - 1 && units >= scale * 999.5) {
    unit++;
    scale *= 1000;
  }
  final value = units / scale;
  final digits = value < 9.95 ? 1 : 0;
  final number = value
      .toStringAsFixed(digits)
      .replaceFirst(RegExp(r'\.0$'), '');
  return (number.replaceFirst('.', separator), unit);
}

String _group(String digits, {required String separator}) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(separator);
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
