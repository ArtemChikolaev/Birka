import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('an amount reads as a person would type it', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(typedAmount(Money(4500000, Currency.rub)), '45000');
    expect(typedAmount(Money(79990, Currency.rub)), '799,90');
    expect(typedAmount(Money(12000, Currency.usd)), '120');
  });

  test('what a person typed becomes money, spaces and all', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(amountTyped('2 500', Currency.rub), Money(250000, Currency.rub));
    expect(amountTyped('799,9', Currency.rub), Money(79990, Currency.rub));
    expect(amountTyped('', Currency.rub), Money(0, Currency.rub));
    expect(amountTyped('-5', Currency.rub), isNull);
    expect(amountTyped('пять', Currency.rub), isNull);
  });
}
