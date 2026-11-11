import 'package:l10n/l10n.dart';
import 'package:money/money.dart';

/// [amount] as a person would type it: `45000` or `799,90`.
String typedAmount(Money amount) {
  final digits = amount.currency.decimalDigits;
  var unit = 1;
  for (var i = 0; i < digits; i++) {
    unit *= 10;
  }
  final whole = amount.minorUnits ~/ unit;
  final part = amount.minorUnits % unit;
  return part == 0
      ? '$whole'
      : '$whole$decimalSeparator${'$part'.padLeft(digits, '0')}';
}

/// What a person typed as an amount in [currency], spaces and all, or `null`
/// when it is no amount or is below zero. An empty field is zero.
Money? amountTyped(String typed, Currency currency) {
  final cleaned = typed.replaceAll(RegExp(r'\s'), '');
  if (cleaned.isEmpty) return Money(0, currency);
  try {
    final money = Money.parse(cleaned, currency);
    return money.isNegative ? null : money;
  } on FormatException {
    return null;
  }
}
