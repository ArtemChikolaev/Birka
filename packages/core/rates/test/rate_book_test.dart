import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money usd(int minorUnits) => Money(minorUnits, Currency.usd);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);
  final usdt = Currency.custom('USDT', decimalDigits: 6);
  final jpy = Currency.iso('JPY');
  final day = CivilDate(2026, 10, 31);

  final book = RateBook([
    DayRates(day, {
      'USD': Decimal.parse('80'),
      'EUR': Decimal.parse('90'),
      'JPY': Decimal.parse('0.5'),
    }),
  ]);

  test('turns a currency into rubles', () {
    expect(book.convert(usd(100), Currency.rub), rub(8000));
  });

  test('turns rubles into a currency', () {
    expect(book.convert(rub(8000), Currency.usd), usd(100));
  });

  test('two currencies meet through the ruble', () {
    expect(book.convert(eur(8000), Currency.usd), usd(9000));
  });

  test('leaves an amount in its own currency alone', () {
    expect(book.convert(rub(123), Currency.rub), rub(123));
    expect(const RateBook.empty().convert(eur(1), Currency.eur), eur(1));
  });

  test('keeps the sign', () {
    expect(book.convert(usd(-100), Currency.rub), rub(-8000));
  });

  test('rounds half away from zero', () {
    final rates = RateBook([
      DayRates(day, {'USD': Decimal.parse('0.5')}),
    ]);

    expect(rates.convert(usd(1), Currency.rub), rub(1));
    expect(rates.convert(usd(3), Currency.rub), rub(2));
    expect(rates.convert(usd(-1), Currency.rub), rub(-1));
  });

  test('minds the digits of each currency', () {
    expect(book.convert(Money(200, jpy), Currency.rub), rub(10000));
    expect(book.convert(rub(10000), jpy), Money(200, jpy));
  });

  test('USDT counts as a dollar', () {
    expect(book.convert(Money(1000000, usdt), Currency.rub), rub(8000));
    expect(book.convert(usd(100), usdt), Money(1000000, usdt));
  });

  test('a sum rounds once, whatever it is made of', () {
    final rates = RateBook([
      DayRates(day, {'EUR': Decimal.fromInt(90)}),
    ]);

    // 1 111,11… and 444,44… come to 1 555,56, while each part rounds down.
    expect(
      rates.sum([rub(10000000), rub(4000000)], Currency.eur),
      eur(155556),
    );
    expect(rates.sum(const [], Currency.eur), eur(0));
  });

  test('a sum says when a rate is missing', () {
    expect(
      book.sum([rub(100), Money(100, Currency.iso('GEL'))], Currency.usd),
      isNull,
    );
  });

  test('says when a rate is missing', () {
    final gel = Currency.iso('GEL');

    expect(book.convert(Money(100, gel), Currency.rub), isNull);
    expect(book.convert(rub(100), gel), isNull);
    expect(book.canConvert(gel, Currency.rub), isFalse);
    expect(book.canConvert(Currency.usd, Currency.eur), isTrue);
    expect(book.canConvert(gel, gel), isTrue);
  });

  test('holds at the limit of an amount', () {
    final most = usd(Money.maxMinorUnits);

    expect(
      book.convert(most, Currency.rub),
      rub(Money.maxMinorUnits),
    );
    expect(
      book.convert(-most, Currency.rub),
      rub(-Money.maxMinorUnits),
    );
  });

  test('takes the latest day that has the currency', () {
    final rates = RateBook([
      DayRates(CivilDate(2026, 10, 30), {
        'USD': Decimal.parse('70'),
        'GEL': Decimal.parse('30'),
      }),
      DayRates(day, {'USD': Decimal.parse('80')}),
    ]);

    expect(rates.latestDay, day);
    expect(rates.convert(usd(100), Currency.rub), rub(8000));
    expect(
      rates.convert(Money(100, Currency.iso('GEL')), Currency.rub),
      rub(3000),
    );
  });

  test('an empty book has no day', () {
    expect(const RateBook.empty().latestDay, isNull);
  });
}
