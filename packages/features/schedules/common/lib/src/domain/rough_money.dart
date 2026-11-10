import 'package:money/money.dart';

/// [exact] as a person would say it: to a hundred units from a thousand on,
/// to ten below, half up, in whole minor units, such as 6 800 ₽ for
/// 6 791,67 ₽.
Money roughly(Money exact) {
  var unit = 1;
  for (var i = 0; i < exact.currency.decimalDigits; i++) {
    unit *= 10;
  }
  final size = exact.minorUnits.abs();
  final step = size >= 1000 * unit ? 100 * unit : 10 * unit;
  final rounded = (size + step ~/ 2) ~/ step * step;
  return Money(exact.isNegative ? -rounded : rounded, exact.currency);
}
