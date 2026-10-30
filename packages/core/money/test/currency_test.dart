import 'package:money/money.dart';
import 'package:test/test.dart';

void main() {
  group('Currency.iso', () {
    test('uses two minor-unit digits by default', () {
      expect(Currency.iso('RUB').decimalDigits, 2);
      expect(Currency.iso('GEL').decimalDigits, 2);
    });

    test('knows currencies without two minor-unit digits', () {
      expect(Currency.iso('JPY').decimalDigits, 0);
      expect(Currency.iso('KWD').decimalDigits, 3);
      expect(Currency.iso('CLF').decimalDigits, 4);
    });

    test('normalizes case and whitespace', () {
      expect(Currency.iso(' rub '), Currency.rub);
    });

    test('rejects malformed codes', () {
      for (final code in ['', 'RU', 'RUBL', 'R1B', 'РУБ']) {
        expect(() => Currency.iso(code), throwsFormatException, reason: code);
      }
    });
  });

  group('Currency.custom', () {
    test('keeps the declared digits', () {
      final btc = Currency.custom('BTC', decimalDigits: 8);
      expect(btc.decimalDigits, 8);
      expect(btc.minorUnitsPerMajor, 100000000);
    });

    test('rejects more digits than an amount can hold exactly', () {
      expect(
        () => Currency.custom('ETH', decimalDigits: 18),
        throwsRangeError,
      );
    });

    test('rejects malformed codes', () {
      expect(
        () => Currency.custom('btc', decimalDigits: 8),
        throwsFormatException,
      );
    });
  });

  test('equality is by code and digits', () {
    expect(Currency.iso('USD'), Currency.usd);
    expect(Currency.iso('USD').hashCode, Currency.usd.hashCode);
    expect(Currency.custom('USD', decimalDigits: 3), isNot(Currency.usd));
  });

  test('minorUnitsPerMajor matches the digits', () {
    expect(Currency.rub.minorUnitsPerMajor, 100);
    expect(Currency.iso('JPY').minorUnitsPerMajor, 1);
    expect(Currency.iso('KWD').minorUnitsPerMajor, 1000);
  });
}
