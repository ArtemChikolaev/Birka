import 'package:accounts_common/accounts_common.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('a type has a name in the language of the user', () {
    expect(accountTypeLabel(AccountType.deposit), 'Вклад');
  });

  test('a card shows its digits and any other account its type', () {
    expect(
      accountSubtitle(
        currency: Currency.rub,
        type: AccountType.debit,
        lastDigits: '4568',
      ),
      'Рубли · •• 4568',
    );
    expect(
      accountSubtitle(currency: Currency.rub, type: AccountType.deposit),
      'Рубли · Вклад',
    );
  });

  test('a currency without a name shows its code', () {
    expect(
      accountSubtitle(
        currency: Currency.custom('ABC', decimalDigits: 2),
        type: AccountType.cash,
      ),
      startsWith('ABC · '),
    );
  });
}
