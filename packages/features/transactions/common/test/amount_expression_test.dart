import 'package:money/money.dart';
import 'package:test/test.dart';
import 'package:transactions_common/transactions_common.dart';

/// Types [keys] the way the keypad does: digits, `.`, operators and `<`.
AmountExpression typed(String keys, {int decimalDigits = 2}) {
  var expression = const AmountExpression();
  for (final key in keys.split('')) {
    expression = switch (key) {
      '.' => expression.decimalPoint(decimalDigits: decimalDigits),
      '<' => expression.backspace(),
      '+' => expression.operator_(AmountOperator.add),
      '-' => expression.operator_(AmountOperator.subtract),
      '*' => expression.operator_(AmountOperator.multiply),
      '/' => expression.operator_(AmountOperator.divide),
      _ => expression.digit(int.parse(key), decimalDigits: decimalDigits),
    };
  }
  return expression;
}

void main() {
  group('an amount', () {
    Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

    test('reads as if it was typed', () {
      expect(AmountExpression.of(rub(25000)).text(separator: ','), '250');
      expect(AmountExpression.of(rub(25050)).text(separator: ','), '250,5');
      expect(AmountExpression.of(rub(25005)).text(separator: ','), '250,05');
      expect(AmountExpression.of(rub(100000)).text(separator: ','), '1000');
    });

    test('of a currency without a fraction keeps its zeros', () {
      final yen = Money(1000, Currency.custom('JPY', decimalDigits: 0));
      expect(AmountExpression.of(yen).text(separator: ','), '1000');
    });

    test('loses its sign and keeps its value', () {
      final expression = AmountExpression.of(rub(-25050));
      expect(expression.valueIn(Currency.rub), rub(25050));
    });

    test('can be typed on', () {
      final expression = AmountExpression.of(rub(25000));
      expect(
        expression.backspace().digit(9, decimalDigits: 2).text(separator: ','),
        '259',
      );
    });
  });

  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money? value(String keys) => typed(keys).valueIn(Currency.rub);
  String text(String keys, {int decimalDigits = 2}) =>
      typed(keys, decimalDigits: decimalDigits).text(separator: ',');

  group('typing', () {
    test('shows what was typed', () {
      expect(text('250+120'), '250 + 120');
      expect(text('12.5*3'), '12,5 × 3');
      expect(text('9-1/2'), '9 − 1 ÷ 2');
      expect(typed('12.5').text(separator: '.'), '12.5');
    });

    test('a leading zero gives way to the next digit', () {
      expect(text('007'), '7');
      expect(text('0.07'), '0,07');
    });

    test('a point starts a number of its own', () {
      expect(text('.5'), '0,5');
      expect(text('2+.5'), '2 + 0,5');
    });

    test('a number has one point', () {
      expect(text('1.2.3'), '1,23');
    });

    test('stops at the digits of the currency', () {
      expect(text('1.234'), '1,23');
      expect(text('1.2', decimalDigits: 0), '12');
    });

    test('stops at the digits an amount can hold', () {
      expect(text('12345678901234567'), '1234567890123');
    });

    test('a second operator replaces the first', () {
      expect(text('5+*2'), '5 × 2');
    });

    test('an operator cannot start the expression', () {
      expect(typed('+').isEmpty, isTrue);
    });

    test('an operator drops a point that leads nowhere', () {
      expect(text('5.+2'), '5 + 2');
    });

    test('backspace takes one step back at a time', () {
      expect(text('12+34<'), '12 + 3');
      expect(text('12+3<'), '12 +');
      expect(text('12+3<<'), '12');
      expect(text('1.5<'), '1,');
      expect(text('1.5<<'), '1');
      expect(typed('1<<<').isEmpty, isTrue);
    });

    test('knows when there is something to work out', () {
      expect(typed('25').hasOperators, isFalse);
      expect(typed('25+').hasOperators, isTrue);
    });
  });

  group('the value', () {
    test('is nothing for an empty expression', () {
      expect(value(''), isNull);
    });

    test('adds up', () {
      expect(value('250+120'), rub(37000));
      expect(value('100-30.50'), rub(6950));
    });

    test('multiplies and divides before it adds', () {
      expect(value('2+3*4'), rub(1400));
      expect(value('100-20/4'), rub(9500));
      expect(value('10-2-3'), rub(500));
      expect(value('100/5/2'), rub(1000));
    });

    test('keeps decimal fractions exact', () {
      expect(value('0.1+0.2'), rub(30));
      expect(value('1.1*1.1'), rub(121));
    });

    test('rounds once, at the end, with halves away from zero', () {
      expect(value('100/3'), rub(3333));
      expect(value('200/3'), rub(6667));
      expect(value('1/8'), rub(13));
      expect(value('1-9/8'), rub(-13));
      // Each third alone would round down and lose a kopeck.
      expect(value('100/3*3'), rub(10000));
    });

    test('ignores an operator at the end', () {
      expect(value('250+'), rub(25000));
      expect(value('250*'), rub(25000));
    });

    test('can go below zero', () {
      expect(value('100-250'), rub(-15000));
    });

    test('is nothing after a division by zero', () {
      expect(value('5/0'), isNull);
      expect(value('5/0.0'), isNull);
    });

    test('is nothing when it does not fit', () {
      expect(value('9999999999999*9999'), isNull);
    });

    test('takes the digits of the currency', () {
      expect(typed('10/4').valueIn(Currency.iso('JPY')), isNotNull);
      expect(
        typed('10/4').valueIn(Currency.iso('JPY')),
        Money(3, Currency.iso('JPY')),
      );
      expect(
        typed('1/3', decimalDigits: 3).valueIn(Currency.iso('KWD')),
        Money(333, Currency.iso('KWD')),
      );
    });

    test('the largest amount still fits', () {
      final limit = Currency.custom('BIG', decimalDigits: 0);
      expect(
        typed('90071992547*100000+40991').valueIn(limit),
        Money(Money.maxMinorUnits, limit),
      );
      expect(typed('90071992547*100000+40992').valueIn(limit), isNull);
    });
  });
}
