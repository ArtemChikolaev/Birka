import 'package:accounts_common/accounts_common.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

import 'fake_accounts_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  late FakeAccountsRepository repository;

  AccountFormCubit newForm() {
    final cubit = AccountFormCubit(repository);
    addTearDown(cubit.close);
    return cubit;
  }

  Future<AccountFormCubit> formOf(String id) async {
    final cubit = AccountFormCubit(repository, accountId: id);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  setUp(() => repository = FakeAccountsRepository());

  group('a new account', () {
    test('needs a name', () async {
      final form = newForm();
      await form.save();

      expect(form.state.errors, {AccountFormError.nameMissing});
      expect(repository.added, isEmpty);
    });

    test('is saved with its fields, without spaces at the ends', () async {
      final form = newForm()
        ..nameChanged('  Card ')
        ..typeChanged(AccountType.savings)
        ..currencyChanged(Currency.eur)
        ..amountChanged('1 250,50')
        ..lastDigitsChanged('4568')
        ..artChanged(AccountArt.sapphire)
        ..includeInTotalsChanged(value: false);
      await form.save();

      expect(form.state.status, AccountFormStatus.saved);
      final draft = repository.added.single;
      expect(draft.name, 'Card');
      expect(draft.type, AccountType.savings);
      expect(draft.openingBalance, Money(125050, Currency.eur));
      expect(draft.lastDigits, '4568');
      expect(draft.art, AccountArt.sapphire);
      expect(draft.includeInTotals, isFalse);
    });

    test('starts from zero when the amount is empty', () async {
      final form = newForm()..nameChanged('Cash');
      await form.save();
      expect(repository.added.single.openingBalance, rub(0));
    });

    test('turns the amount of a credit card into a debt', () async {
      final form = newForm()
        ..nameChanged('Credit')
        ..typeChanged(AccountType.credit)
        ..amountChanged('1000');
      await form.save();
      expect(repository.added.single.openingBalance, rub(-100000));
    });

    test('rejects an amount that is not a number', () async {
      final form = newForm()
        ..nameChanged('Card')
        ..amountChanged('12a');
      await form.save();
      expect(form.state.errors, {AccountFormError.amountInvalid});
    });

    test('rejects more decimals than the currency has', () async {
      final form = newForm()
        ..nameChanged('Card')
        ..amountChanged('1.234');
      await form.save();
      expect(form.state.errors, {AccountFormError.amountInvalid});
    });

    test('rejects last digits that are not four digits', () async {
      final form = newForm()
        ..nameChanged('Card')
        ..lastDigitsChanged('45');
      await form.save();
      expect(form.state.errors, {AccountFormError.lastDigitsInvalid});
    });

    test('clears an error when its field changes', () async {
      final form = newForm();
      await form.save();
      form.nameChanged('C');
      expect(form.state.errors, isEmpty);
    });

    test('reports a failed save', () async {
      repository.failure = Exception('disk full');
      final form = newForm()..nameChanged('Card');
      await form.save();
      expect(form.state.status, AccountFormStatus.failed);
    });
  });

  group('an existing account', () {
    final credit = account(
      'Credit',
      rub(-100000),
      type: AccountType.credit,
      lastDigits: '1207',
    );

    setUp(() {
      repository = FakeAccountsRepository([
        AccountBalance(credit, rub(-100000)),
      ]);
    });

    test('fills in the form', () async {
      final form = await formOf('Credit');

      expect(form.state.status, AccountFormStatus.editing);
      expect(form.state.isNew, isFalse);
      expect(form.state.name, 'Credit');
      expect(form.state.amount, '1000.00');
      expect(form.state.lastDigits, '1207');
    });

    test('keeps its currency', () async {
      final form = await formOf('Credit');
      form.currencyChanged(Currency.eur);
      expect(form.state.currency, Currency.rub);
    });

    test('saves over itself and can drop its digits', () async {
      final form = await formOf('Credit');
      form
        ..nameChanged('Visa')
        ..lastDigitsChanged('');
      await form.save();

      final draft = repository.updated['Credit']!;
      expect(draft.name, 'Visa');
      expect(draft.openingBalance, rub(-100000));
      expect(draft.lastDigits, isNull);
    });

    test('can be put away and brought back', () async {
      final form = await formOf('Credit');
      await form.toggleArchived();
      expect(form.state.status, AccountFormStatus.saved);
      expect((await repository.account('Credit'))?.archived, isTrue);

      final again = await formOf('Credit');
      expect(again.state.archived, isTrue);
      await again.toggleArchived();
      expect((await repository.account('Credit'))?.archived, isFalse);
    });

    test('reports an account that is gone', () async {
      final form = await formOf('nobody');
      expect(form.state.status, AccountFormStatus.failed);
    });
  });
}
