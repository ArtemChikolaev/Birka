import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

void main() {
  const space = '\u00A0';
  const minus = '\u2212';
  final aed = Currency.iso('AED');

  String ru(int minorUnits, Currency currency) =>
      formatMoney(Money(minorUnits, currency), locale: AppLocale.ru);
  String en(int minorUnits, Currency currency) =>
      formatMoney(Money(minorUnits, currency), locale: AppLocale.en);

  group('Russian', () {
    test('puts the sign after the digits, which it groups by three', () {
      expect(ru(128456000, Currency.rub), '1${space}284${space}560$space₽');
    });

    test('keeps a fraction with a comma', () {
      expect(ru(123450, Currency.rub), '1${space}234,50$space₽');
    });

    test('leaves out a fraction of zeros', () {
      expect(ru(41230000, Currency.rub), '412${space}300$space₽');
    });

    test('marks a negative amount with a minus sign', () {
      expect(ru(-125000, Currency.eur), '${minus}1${space}250$space€');
    });
  });

  group('English', () {
    test('puts the sign before the digits, which it groups by three', () {
      expect(en(128456050, Currency.usd), r'$1,284,560.50');
    });

    test('leaves out a fraction of zeros', () {
      expect(en(214000, Currency.eur), '€2,140');
    });

    test('puts the minus before the sign', () {
      expect(en(-125000, Currency.usd), '$minus\$1,250');
    });
  });

  test('a currency without a sign shows its code after the digits', () {
    expect(ru(125000, aed), '1${space}250${space}AED');
    expect(en(125000, aed), '1,250${space}AED');
  });

  test('a currency without minor units has no fraction', () {
    expect(en(1500, Currency.iso('JPY')), '¥1,500');
  });

  test('keeps every digit of a currency with more of them', () {
    final btc = Currency.custom('BTC', decimalDigits: 8);
    expect(en(1, btc), '0.00000001${space}BTC');
  });

  test('keeps every digit of the largest amount', () {
    expect(
      en(Money.maxMinorUnits, Currency.usd),
      r'$90,071,992,547,409.91',
    );
  });

  test('follows the current language by default', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
    expect(formatMoney(Money(100, Currency.rub)), '1$space₽');
  });

  group('a compact amount', () {
    Money rub(int units) => Money(units * 100, Currency.rub);
    const space = '\u00A0';

    test('is whole units below a thousand', () {
      expect(formatCompactMoney(rub(950)), '₽950');
      expect(
        formatCompactMoney(Money(95050, Currency.rub), locale: AppLocale.ru),
        '950$space₽',
      );
    });

    test('counts thousands, millions and billions', () {
      expect(formatCompactMoney(rub(84300)), '₽84k');
      expect(formatCompactMoney(rub(1200000)), '₽1.2M');
      expect(formatCompactMoney(rub(3000000000)), '₽3B');
    });

    test('reads in Russian', () {
      expect(
        formatCompactMoney(rub(84300), locale: AppLocale.ru),
        '84$spaceтыс.$space₽',
      );
      expect(
        formatCompactMoney(rub(1200000), locale: AppLocale.ru),
        '1,2$spaceмлн$space₽',
      );
      expect(
        formatCompactMoney(rub(3000000000), locale: AppLocale.ru),
        '3$spaceмлрд$space₽',
      );
    });

    test('keeps a digit while the number is small', () {
      expect(formatCompactMoney(rub(1250)), '₽1.3k');
      expect(formatCompactMoney(rub(9900)), '₽9.9k');
      expect(formatCompactMoney(rub(9960)), '₽10k');
    });

    test('drops a digit of zero', () {
      expect(formatCompactMoney(rub(2000)), '₽2k');
    });

    test('moves to the next unit instead of a thousand of this one', () {
      expect(formatCompactMoney(rub(999400)), '₽999k');
      expect(formatCompactMoney(rub(999600)), '₽1M');
    });

    test('rounds a half up at each place', () {
      expect(formatCompactMoney(rub(1250)), '₽1.3k');
      expect(formatCompactMoney(rub(1249)), '₽1.2k');
      expect(formatCompactMoney(rub(84500)), '₽85k');
      expect(formatCompactMoney(rub(84499)), '₽84k');
    });

    test('the largest amount stays in billions on every platform', () {
      expect(
        formatCompactMoney(Money(Money.maxMinorUnits, Currency.rub)),
        '₽90072B',
      );
      expect(
        formatCompactMoney(
          Money(Money.maxMinorUnits, Currency.custom('JPY', decimalDigits: 0)),
        ),
        '¥9007199B',
      );
    });

    test('shows the code of a currency without a sign', () {
      expect(
        formatCompactMoney(Money(8400000, Currency.iso('AED'))),
        '84k${space}AED',
      );
    });

    test('loses its sign', () {
      expect(formatCompactMoney(rub(-84300)), '₽84k');
    });

    test('a figure has no currency', () {
      expect(formatCompactFigure(rub(78000)), '78k');
      expect(formatCompactFigure(rub(950)), '950');
      expect(formatCompactFigure(rub(1200000)), '1.2M');
    });

    test('a figure takes the mark of the language', () {
      LocaleSettings.setLocaleSync(AppLocale.ru);
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

      expect(formatCompactFigure(rub(1200000)), '1,2M');
      expect(formatCompactFigure(rub(78000)), '78k');
    });
  });
}
