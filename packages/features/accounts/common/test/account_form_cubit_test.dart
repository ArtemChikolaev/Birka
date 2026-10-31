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
        ..typeChanged(AccountType.credit)
        ..currencyChanged(Currency.eur)
        ..amountChanged('1 250,50')
        ..lastDigitsChanged('4568')
        ..artChanged(AccountArt.sapphire)
        ..includeInTotalsChanged(value: false);
      await form.save();

      expect(form.state.status, AccountFormStatus.saved);
      final draft = repository.added.single;
      expect(draft.name, 'Card');
      expect(draft.type, AccountType.credit);
      expect(draft.currency, Currency.eur);
      expect(draft.balance, Money(-125050, Currency.eur));
      expect(draft.lastDigits, '4568');
      expect(draft.art, AccountArt.sapphire);
      expect(draft.includeInTotals, isFalse);
    });

    test('starts from zero when the amount is empty', () async {
      final form = newForm()..nameChanged('Cash');
      await form.save();
      expect(repository.added.single.balance, rub(0));
    });

    test('turns the amount of a credit card into a debt', () async {
      final form = newForm()
        ..nameChanged('Credit')
        ..typeChanged(AccountType.credit)
        ..amountChanged('1000');
      await form.save();
      expect(repository.added.single.balance, rub(-100000));
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

    test('ignores digits that the form no longer shows', () async {
      final form = newForm()
        ..nameChanged('Savings')
        ..lastDigitsChanged('45')
        ..typeChanged(AccountType.savings);
      await form.save();

      expect(form.state.errors, isEmpty);
      expect(repository.added.single.lastDigits, isNull);
    });

    test('previews the amount, and zero until it is a number', () {
      final form = newForm()..amountChanged('1 250,50');
      expect(form.state.previewBalance, rub(125050));

      form.typeChanged(AccountType.credit);
      expect(form.state.previewBalance, rub(-125050));

      form.amountChanged('12a');
      expect(form.state.balance, isNull);
      expect(form.state.previewBalance, rub(0));
    });

    test('offers every currency', () {
      expect(newForm().state.currencies, offeredCurrencies);
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
      expect(form.state.currencies, [Currency.rub]);
    });

    test('keeps a type the form does not offer', () async {
      repository = FakeAccountsRepository([
        AccountBalance(
          account('Loan', rub(0), type: AccountType.loan),
          rub(0),
        ),
      ]);
      final form = await formOf('Loan');
      expect(form.state.types, contains(AccountType.loan));
      expect(newForm().state.types, isNot(contains(AccountType.loan)));
    });

    test('saves over itself and can drop its digits', () async {
      final form = await formOf('Credit');
      form
        ..nameChanged('Visa')
        ..lastDigitsChanged('');
      await form.save();

      final draft = repository.updated['Credit']!;
      expect(draft.name, 'Visa');
      expect(draft.balance, isNull);
      expect(draft.lastDigits, isNull);
    });

    group('with operations', () {
      setUp(() {
        repository = FakeAccountsRepository([
          AccountBalance(account('Card', rub(1500000)), rub(3376000)),
          AccountBalance(credit, rub(-250000)),
        ]);
      });

      test('shows what it holds, not what it started from', () async {
        final form = await formOf('Card');

        expect(form.state.amount, '33760.00');
        expect(form.state.previewBalance, rub(3376000));
      });

      test('shows a debt without a sign', () async {
        final form = await formOf('Credit');

        expect(form.state.amount, '2500.00');
        expect(form.state.previewBalance, rub(-250000));
      });

      test('leaves the balance alone when the amount is untouched', () async {
        final form = await formOf('Card');
        form.nameChanged('Salary');
        await form.save();

        expect(repository.updated['Card']!.balance, isNull);
      });

      test('leaves it alone when the amount comes back to the same', () async {
        final form = await formOf('Card');
        form.amountChanged('33 760');
        await form.save();

        expect(repository.updated['Card']!.balance, isNull);
      });

      test('hands over a new balance', () async {
        final form = await formOf('Card');
        form.amountChanged('40000');
        await form.save();

        expect(repository.updated['Card']!.balance, rub(4000000));
      });

      test('hands over a new debt as money below zero', () async {
        final form = await formOf('Credit');
        form.amountChanged('3000');
        await form.save();

        expect(repository.updated['Credit']!.balance, rub(-300000));
      });

      test('an empty field means nothing is left', () async {
        final form = await formOf('Card');
        form.amountChanged('');
        await form.save();

        expect(repository.updated['Card']!.balance, rub(0));
      });

      test('a new type keeps what a debt holds', () async {
        final form = await formOf('Credit');
        form.typeChanged(AccountType.savings);

        expect(form.state.amount, '-2500.00');
        expect(form.state.previewBalance, rub(-250000));

        await form.save();
        expect(repository.updated['Credit']!.balance, isNull);
      });

      test('a new type keeps what a card holds', () async {
        final form = await formOf('Card');
        form.typeChanged(AccountType.credit);

        expect(form.state.amount, '-33760.00');
        expect(form.state.previewBalance, rub(3376000));

        await form.save();
        expect(repository.updated['Card']!.balance, isNull);
      });

      test('a type of the same meaning leaves the amount as typed', () async {
        final form = await formOf('Card');
        form
          ..amountChanged('40 000')
          ..typeChanged(AccountType.savings);

        expect(form.state.amount, '40 000');
      });

      test('a new type waits for an amount that is a number', () async {
        final form = await formOf('Card');
        form
          ..amountChanged('abc')
          ..typeChanged(AccountType.credit);

        expect(form.state.amount, 'abc');
      });
    });

    test('a new account keeps its digits through a new type', () {
      final form = newForm()
        ..amountChanged('1000')
        ..typeChanged(AccountType.credit);

      expect(form.state.amount, '1000');
      expect(form.state.balance, rub(-100000));
    });

    test('drops its digits when it stops being a card', () async {
      final form = await formOf('Credit');
      form.typeChanged(AccountType.savings);
      await form.save();

      expect(repository.updated['Credit']!.lastDigits, isNull);
    });

    test('can be put away and brought back', () async {
      final form = await formOf('Credit');
      await form.toggleArchived();
      expect(form.state.status, AccountFormStatus.saved);
      expect((await repository.account('Credit'))?.account.archived, isTrue);

      final again = await formOf('Credit');
      expect(again.state.archived, isTrue);
      await again.toggleArchived();
      expect((await repository.account('Credit'))?.account.archived, isFalse);
    });

    test('reports an account that is gone', () async {
      final form = await formOf('nobody');
      expect(form.state.status, AccountFormStatus.failed);
    });
  });
}
