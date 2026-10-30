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
}
