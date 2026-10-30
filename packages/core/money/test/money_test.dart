import 'package:money/money.dart';
import 'package:test/test.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

void main() {
  group('range', () {
    test('accepts amounts up to 2^53 − 1 minor units', () {
      expect(rub(Money.maxMinorUnits).minorUnits, 9007199254740991);
      expect(rub(-Money.maxMinorUnits).minorUnits, -9007199254740991);
    });

    test('rejects amounts beyond 2^53 − 1 minor units', () {
      expect(() => rub(Money.maxMinorUnits + 1), throwsRangeError);
      expect(() => rub(-Money.maxMinorUnits - 1), throwsRangeError);
    });

    test('rejects a sum that leaves the range', () {
      expect(() => rub(Money.maxMinorUnits) + rub(1), throwsRangeError);
    });

    test('checks a product before multiplying', () {
      expect(() => rub(Money.maxMinorUnits ~/ 2 + 1) * 2, throwsRangeError);
      // 2^40 written out: on the web, bitwise operators work on 32 bits.
      const twoPow40 = 1099511627776;
      expect(() => rub(twoPow40) * twoPow40, throwsRangeError);
      expect(rub(Money.maxMinorUnits ~/ 2) * 2, rub(9007199254740990));
    });
  });

  group('arithmetic', () {
    test('adds, subtracts, negates and multiplies exactly', () {
      expect(rub(10) + rub(20), rub(30));
      expect(rub(10) - rub(30), rub(-20));
      expect(-rub(15), rub(-15));
      expect(rub(-15).abs(), rub(15));
      expect(rub(250) * 3, rub(750));
      expect(rub(250) * 0, rub(0));
    });

    test('0.1 + 0.2 is exactly 0.3', () {
      final sum =
          Money.parse('0.1', Currency.rub) + Money.parse('0.2', Currency.rub);
      expect(sum, Money.parse('0.3', Currency.rub));
    });

    test('refuses to mix currencies', () {
      final dollar = Money(100, Currency.usd);
      expect(() => rub(100) + dollar, throwsArgumentError);
      expect(() => rub(100) - dollar, throwsArgumentError);
      expect(() => rub(100).compareTo(dollar), throwsArgumentError);
    });

    test('compares amounts in one currency', () {
      expect(rub(1) < rub(2), isTrue);
      expect(rub(2) <= rub(2), isTrue);
      expect(rub(3) > rub(2), isTrue);
      expect(rub(2) >= rub(3), isFalse);
      expect([rub(3), rub(-1), rub(2)]..sort(), [rub(-1), rub(2), rub(3)]);
    });

    test('reports its sign', () {
      expect(const Money.zero(Currency.rub).isZero, isTrue);
      expect(rub(-1).isNegative, isTrue);
      expect(rub(1).isPositive, isTrue);
    });
  });

  group('parse', () {
    test('reads decimal strings without floating point', () {
      expect(Money.parse('1234.56', Currency.rub), rub(123456));
      expect(Money.parse('-0.5', Currency.rub), rub(-50));
      expect(Money.parse('+7', Currency.rub), rub(700));
      expect(Money.parse('1,5', Currency.rub), rub(150));
      expect(Money.parse(' 42 ', Currency.rub), rub(4200));
      expect(Money.parse('100', Currency.iso('JPY')).minorUnits, 100);
      expect(Money.parse('1.234', Currency.iso('KWD')).minorUnits, 1234);
    });

    test('reads the largest amount exactly', () {
      expect(
        Money.parse('90071992547409.91', Currency.rub),
        rub(Money.maxMinorUnits),
      );
    });

    test('rejects malformed input instead of guessing', () {
      final inputs = ['', 'abc', '1.', '.5', '1 234.56', '1.2.3', '--1', '1e3'];
      for (final input in inputs) {
        expect(
          () => Money.parse(input, Currency.rub),
          throwsFormatException,
          reason: input,
        );
      }
    });

    test('rejects extra fraction digits instead of rounding', () {
      expect(() => Money.parse('1.234', Currency.rub), throwsFormatException);
      expect(
        () => Money.parse('1.5', Currency.iso('JPY')),
        throwsFormatException,
      );
    });

    test('rejects amounts out of range', () {
      expect(
        () => Money.parse('90071992547409.92', Currency.rub),
        throwsFormatException,
      );
    });
  });

  group('toDecimalString', () {
    test('writes every minor digit', () {
      expect(rub(123456).toDecimalString(), '1234.56');
      expect(rub(-50).toDecimalString(), '-0.50');
      expect(rub(7).toDecimalString(), '0.07');
      expect(Money(5, Currency.iso('JPY')).toDecimalString(), '5');
      final btc = Currency.custom('BTC', decimalDigits: 8);
      expect(Money(1, btc).toDecimalString(), '0.00000001');
    });

    test('round-trips through parse', () {
      for (final minorUnits in [
        0,
        1,
        -1,
        99,
        -100,
        123456,
        Money.maxMinorUnits,
      ]) {
        final money = rub(minorUnits);
        expect(Money.parse(money.toDecimalString(), Currency.rub), money);
      }
    });

    test('toString adds the currency code', () {
      expect(rub(-1050).toString(), '-10.50 RUB');
    });
  });
}
