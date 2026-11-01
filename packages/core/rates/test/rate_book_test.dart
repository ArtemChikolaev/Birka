import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart';
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

    // 1 111,11… and 444,44… come to 1 556 whole, while each part rounds down.
    expect(
      rates.sum([rub(10000000), rub(4000000)], Currency.eur),
      eur(155600),
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

  group('a sum that took a rate', () {
    test('is whole', () {
      expect(book.sum([usd(1234)], Currency.rub), rub(98700));
      expect(book.sum([usd(1234), rub(50)], Currency.rub), rub(98800));
    });

    test('rounds the exact sum and not a sum in kopecks', () {
      final rates = RateBook([
        DayRates(day, {'USD': Decimal.parse('83.9497')}),
      ]);

      expect(rates.convert(usd(1000), Currency.rub), rub(83950));
      expect(rates.sum([usd(1000)], Currency.rub), rub(83900));
    });

    test('keeps its cents under one unit', () {
      expect(book.sum([rub(3000)], Currency.usd), usd(38));
      expect(book.sum([rub(-3000)], Currency.usd), usd(-38));
    });

    test('rounds a half away from zero', () {
      final rates = RateBook([
        DayRates(day, {'USD': Decimal.parse('1.5')}),
      ]);

      expect(rates.sum([usd(100)], Currency.rub), rub(200));
      expect(rates.sum([usd(-100)], Currency.rub), rub(-200));
    });

    test('in one currency keeps its kopecks', () {
      expect(book.sum([rub(150), rub(5)], Currency.rub), rub(155));
    });
  });

  group('on a day', () {
    CategoryDayTotal row(CivilDate day, Money total) => CategoryDayTotal(
      const Category(
        id: 'food',
        kind: CategoryKind.expense,
        name: 'Food',
        archived: false,
        sortOrder: 0,
      ),
      day,
      total,
    );

    final monday = CivilDate(2026, 10, 26);
    final wednesday = CivilDate(2026, 10, 28);
    final friday = CivilDate(2026, 10, 30);
    final history = RateBook([
      DayRates(friday, {'USD': Decimal.fromInt(90)}),
      DayRates(monday, {'USD': Decimal.fromInt(70)}),
      DayRates(wednesday, {
        'USD': Decimal.fromInt(80),
        'EUR': Decimal.fromInt(100),
      }),
    ]);

    test('takes the rate of that day', () {
      expect(history.convert(usd(100), Currency.rub, on: monday), rub(7000));
      expect(history.convert(usd(100), Currency.rub, on: friday), rub(9000));
    });

    test('takes the last rate before a day without one', () {
      expect(
        history.convert(usd(100), Currency.rub, on: CivilDate(2026, 10, 29)),
        rub(8000),
      );
      expect(
        history.convert(usd(100), Currency.rub, on: CivilDate(2026, 11, 1)),
        rub(9000),
      );
    });

    test('takes the first rate before them all', () {
      expect(
        history.convert(usd(100), Currency.rub, on: CivilDate(2025, 1, 1)),
        rub(7000),
      );
    });

    test('each currency looks for its own last rate', () {
      expect(
        history.convert(eur(100), Currency.usd, on: friday),
        usd(111),
      );
      expect(
        history.convert(eur(100), Currency.usd, on: monday),
        usd(143),
      );
    });

    test('without a day takes the latest rate', () {
      expect(history.convert(usd(100), Currency.rub), rub(9000));
      expect(history.latestDay, friday);
    });

    test('has nothing for a currency without rates', () {
      expect(history.convert(rub(100), jpy, on: friday), isNull);
    });

    test('adds up amounts of different days and rounds once', () {
      final exact = RateBook([
        DayRates(monday, {'USD': Decimal.parse('0.5')}),
      ]);

      expect(
        exact.sumOfDays([
          row(monday, usd(1)),
          row(monday, usd(1)),
          row(friday, rub(3)),
        ], Currency.rub),
        rub(4),
      );
    });

    test('adds up each amount at the rate of its day', () {
      expect(
        history.sumOfDays([
          row(monday, usd(100)),
          row(friday, usd(100)),
          row(friday, rub(5)),
        ], Currency.rub),
        rub(16000),
      );
    });

    test('adds up nothing without a rate', () {
      expect(
        history.sumOfDays([row(monday, Money(1, jpy))], Currency.rub),
        isNull,
      );
    });
  });
}
