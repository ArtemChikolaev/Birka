@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';
import 'package:transactions_common/src/data/ledger_transactions_repository.dart';
import 'package:transactions_common/transactions_common.dart';

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late TransactionsRepository repository;
  final today = CivilDate(2026, 10, 31);
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

  setUp(() {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    repository = LedgerTransactionsRepository(ledger);
  });
  tearDown(() => database.close());

  Future<Account> account(String name) => ledger.addAccount(
    name: name,
    type: AccountType.debit,
    openingBalance: rub(0),
  );

  TransactionDraft expense(Account account, Category category) =>
      TransactionDraft.expense(
        accountId: account.id,
        allocations: [Allocation(categoryId: category.id, amount: rub(100))],
        occurredOn: today,
      );

  test('the frequent categories come first', () async {
    final card = await account('Card');
    final food = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Food',
    );
    final cafe = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Cafe',
    );
    await repository.record(expense(card, cafe));
    await repository.record(expense(card, cafe));
    await repository.record(expense(card, food));

    final names = (await repository.categories(
      CategoryKind.expense,
    )).map((category) => category.name);
    expect(names, ['Cafe', 'Food']);
  });

  test('archived accounts and categories are not offered', () async {
    final old = await account('Old');
    await account('Card');
    await ledger.updateAccount(old.id, archived: true);
    final gone = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Gone',
    );
    await ledger.updateCategory(gone.id, archived: true);

    expect((await repository.accounts()).single.name, 'Card');
    expect(await repository.categories(CategoryKind.expense), isEmpty);
  });

  test('the latest transaction names the last account', () async {
    expect(await repository.lastAccountId(), isNull);

    final card = await account('Card');
    final cash = await account('Cash');
    final food = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Food',
    );
    await repository.record(expense(card, food));
    await repository.record(expense(cash, food));

    expect(await repository.lastAccountId(), cash.id);
  });

  test('what is recorded changes the balance', () async {
    final card = await account('Card');
    final food = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Food',
    );

    await repository.record(expense(card, food));

    expect(await ledger.watchBalance(card.id).first, rub(-100));
  });
}
