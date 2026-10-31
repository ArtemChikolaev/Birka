import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// An operator on the keypad of an amount.
enum AmountOperator {
  /// Adds.
  add('+'),

  /// Subtracts.
  subtract('−'),

  /// Multiplies.
  multiply('×'),

  /// Divides.
  divide('÷')
  ;

  const AmountOperator(this.symbol);

  /// How the operator reads on the screen.
  final String symbol;
}

/// What was typed on the keypad: numbers with operators between them, such as
/// `250 + 120`.
///
/// The value is exact. It goes through fractions of [BigInt], never through a
/// `double`, and is rounded once, to the minor units of a currency
/// (ADR 0003).
@immutable
final class AmountExpression {
  /// Creates an empty expression.
  const AmountExpression() : _numbers = const [], _operators = const [];

  /// Creates an expression that holds [amount] alone, as if it was typed.
  factory AmountExpression.of(Money amount) {
    final digits = amount.abs().toDecimalString();
    final number = digits.contains('.')
        ? digits.replaceFirst(RegExp(r'\.?0+$'), '')
        : digits;
    return AmountExpression._([number], const []);
  }

  const AmountExpression._(this._numbers, this._operators);

  /// The most digits a number takes before its point. An amount holds at most
  /// 2^53 − 1 minor units, so more of them could not fit anyway.
  static const maxWholeDigits = 13;

  /// The numbers as typed, with `.` for the point. There is one more of them
  /// than [_operators], or as many when the expression ends in an operator.
  final List<String> _numbers;
  final List<AmountOperator> _operators;

  /// Whether nothing is typed.
  bool get isEmpty => _numbers.isEmpty;

  /// Whether there is anything to work out.
  bool get hasOperators => _operators.isNotEmpty;

  bool get _endsInNumber => _numbers.length > _operators.length;

  /// Adds [digit], unless the number already has all the digits it can hold.
  /// [decimalDigits] is the limit after the point.
  AmountExpression digit(int digit, {required int decimalDigits}) {
    if (!_endsInNumber) return _withNew('$digit');
    final number = _numbers.last;
    if (number == '0') return _withLast('$digit');
    final [whole, ...fraction] = number.split('.');
    final full = fraction.isEmpty
        ? whole.length >= maxWholeDigits
        : fraction.single.length >= decimalDigits;
    return full ? this : _withLast('$number$digit');
  }

  /// Starts the fraction of the number, if the currency has one.
  AmountExpression decimalPoint({required int decimalDigits}) {
    if (decimalDigits == 0) return this;
    if (!_endsInNumber) return _withNew('0.');
    final number = _numbers.last;
    return number.contains('.') ? this : _withLast('$number.');
  }

  /// Adds [operator] after the number, or swaps the operator at the end.
  AmountExpression operator_(AmountOperator operator) {
    if (isEmpty) return this;
    if (!_endsInNumber) {
      return AmountExpression._(_numbers, [
        ..._operators.take(_operators.length - 1),
        operator,
      ]);
    }
    final number = _numbers.last;
    final numbers = number.endsWith('.')
        ? [
            ..._numbers.take(_numbers.length - 1),
            number.substring(0, number.length - 1),
          ]
        : _numbers;
    return AmountExpression._(numbers, [..._operators, operator]);
  }

  /// Removes the last character or operator.
  AmountExpression backspace() {
    if (isEmpty) return this;
    if (!_endsInNumber) {
      return AmountExpression._(
        _numbers,
        _operators.take(_operators.length - 1).toList(growable: false),
      );
    }
    final number = _numbers.last;
    if (number.length == 1) {
      return AmountExpression._(
        _numbers.take(_numbers.length - 1).toList(growable: false),
        _operators,
      );
    }
    return _withLast(number.substring(0, number.length - 1));
  }

  /// The expression as text, with [separator] in place of the point.
  String text({required String separator}) {
    final parts = <String>[];
    for (final (index, number) in _numbers.indexed) {
      parts.add(number.replaceFirst('.', separator));
      if (index < _operators.length) parts.add(_operators[index].symbol);
    }
    return parts.join(' ');
  }

  /// What the expression comes to in [currency], rounded to its minor units
  /// with halves away from zero. An operator at the end does not count.
  ///
  /// It is `null` for an empty expression, a division by zero and an amount
  /// too big to hold.
  Money? valueIn(Currency currency) {
    if (isEmpty) return null;
    var sum = _Fraction.zero;
    var term = _Fraction.parse(_numbers.first);
    for (final (index, number) in _numbers.skip(1).indexed) {
      final next = _Fraction.parse(number);
      switch (_operators[index]) {
        case AmountOperator.add:
          sum += term;
          term = next;
        case AmountOperator.subtract:
          sum += term;
          term = -next;
        case AmountOperator.multiply:
          term *= next;
        case AmountOperator.divide:
          if (next.isZero) return null;
          term /= next;
      }
    }
    final minorUnits = (sum + term).roundedTo(currency.decimalDigits);
    if (minorUnits.abs() > BigInt.from(Money.maxMinorUnits)) return null;
    return Money(minorUnits.toInt(), currency);
  }

  AmountExpression _withNew(String number) =>
      AmountExpression._([..._numbers, number], _operators);

  AmountExpression _withLast(String number) => AmountExpression._([
    ..._numbers.take(_numbers.length - 1),
    number,
  ], _operators);
}

/// An exact number: a quotient of [BigInt]s with a positive [_denominator].
final class _Fraction {
  const _Fraction(this._numerator, this._denominator);

  /// Reads digits with an optional `.`, which may end the text.
  factory _Fraction.parse(String number) {
    final [whole, ...fraction] = number.split('.');
    final decimals = fraction.isEmpty ? '' : fraction.single;
    return _Fraction(
      BigInt.parse('$whole$decimals'),
      BigInt.from(10).pow(decimals.length),
    );
  }

  static final zero = _Fraction(BigInt.zero, BigInt.one);

  final BigInt _numerator;
  final BigInt _denominator;

  bool get isZero => _numerator == BigInt.zero;

  _Fraction operator -() => _Fraction(-_numerator, _denominator);

  _Fraction operator +(_Fraction other) => _Fraction(
    _numerator * other._denominator + other._numerator * _denominator,
    _denominator * other._denominator,
  );

  _Fraction operator *(_Fraction other) => _Fraction(
    _numerator * other._numerator,
    _denominator * other._denominator,
  );

  /// Divides by a number that is not zero and not negative.
  _Fraction operator /(_Fraction other) => _Fraction(
    _numerator * other._denominator,
    _denominator * other._numerator,
  );

  /// The number in units of 10^-[digits], with halves away from zero.
  BigInt roundedTo(int digits) {
    final scaled = _numerator.abs() * BigInt.from(10).pow(digits);
    final rounded =
        (scaled * BigInt.two + _denominator) ~/ (_denominator * BigInt.two);
    return _numerator.isNegative ? -rounded : rounded;
  }
}
