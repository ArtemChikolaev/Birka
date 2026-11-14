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

  group('an account', () {
    test('comes with what it holds', () async {
      final card = await account('Card');
      final food = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Food',
      );
      await ledger.record(expense(card, food));

      final row = await repository.watchAccount(card.id).first;

      expect(row?.account.name, 'Card');
      expect(row?.balance, rub(-100));
    });

    test('that does not exist comes as nothing', () async {
      expect(await repository.watchAccount('nothing').first, isNull);
    });

    test('that is archived still comes', () async {
      final card = await account('Card');
      await ledger.updateAccount(card.id, archived: true);

      expect(await repository.watchAccount(card.id).first, isNotNull);
    });

    test('has the changes of its own days', () async {
      final card = await account('Card');
      final cash = await account('Cash');
      final food = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Food',
      );
      await ledger.record(expense(card, food));
      await ledger.record(expense(cash, food));
      await ledger.record(expense(cash, food));

      final changes = await repository
          .watchAccountChanges(card.id, from: today)
          .first;

      expect(changes.single.change, rub(-100));
    });

    test('has its operations, a transfer from both sides', () async {
      final card = await account('Card');
      final cash = await account('Cash');
      final other = await account('Other');
      final food = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Food',
      );
      await ledger.record(expense(card, food));
      await ledger.record(expense(other, food));
      await ledger.record(
        TransactionDraft.transfer(
          fromAccountId: cash.id,
          toAccountId: card.id,
          sent: rub(300),
          received: rub(300),
          occurredOn: today,
        ),
      );

      final operations = await repository.watchAccountOperations(card.id).first;

      expect(operations, hasLength(2));
      expect(operations.first.kind, TransactionKind.transfer);
      expect(operations.first.amountOn(card.id), rub(300));
      expect(operations.last.account?.name, 'Card');
    });

    test('comes to the same on a day as its chart', () async {
      final card = await account('Card');
      final cash = await account('Cash');
      final food = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Food',
      );
      await ledger.record(expense(card, food));
      await ledger.record(
        TransactionDraft.expense(
          accountId: card.id,
          allocations: [Allocation(categoryId: food.id, amount: rub(700))],
          occurredOn: today,
          status: TransactionStatus.planned,
        ),
      );
      await ledger.record(
        TransactionDraft.transfer(
          fromAccountId: cash.id,
          toAccountId: card.id,
          sent: rub(300),
          received: rub(300),
          occurredOn: today,
        ),
      );
      await ledger.record(
        TransactionDraft.adjustment(
          accountId: card.id,
          change: rub(50),
          occurredOn: today,
        ),
      );

      final changes = await repository
          .watchAccountChanges(card.id, from: today)
          .first;
      final operations = await repository.watchAccountOperations(card.id).first;

      expect(changes.single.change, rub(250));
      expect(groupByDay(operations).single.totalOn(card.id), [rub(250)]);
    });
  });

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

  test('a debt that came back names the account of the person, and its '
      'operation names the person', () async {
    final card = await account('Card');
    final masha = await ledger.addAccount(
      name: 'Маша',
      type: AccountType.debt,
      openingBalance: const Money.zero(Currency.rub),
      debt: const DebtTerms(side: DebtSide.lent),
    );
    await repository.record(
      TransactionDraft.transfer(
        fromAccountId: masha.id,
        sent: Money(200000, Currency.rub),
        toAccountId: card.id,
        received: Money(200000, Currency.rub),
        occurredOn: CivilDate(2026, 11, 10),
      ),
    );

    expect(await repository.lastAccountId(), card.id);
    expect((await repository.accounts()).map((it) => it.name), ['Card']);
    final operation =
        (await repository.watchOperations(CivilDate(2026, 11, 1)).first).single;
    expect(operation.debt?.name, 'Маша');
    expect(operation.ownAccount?.name, 'Card');
    expect(operation.debtMove, DebtMove.returned);
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

  group('operations', () {
    late Account card;
    late Category food;

    TransactionDraft on(CivilDate day) => TransactionDraft.expense(
      accountId: card.id,
      allocations: [Allocation(categoryId: food.id, amount: rub(100))],
      occurredOn: day,
    );

    setUp(() async {
      card = await account('Card');
      food = await ledger.addCategory(kind: CategoryKind.expense, name: 'Food');
    });

    test('of a month name what they refer to, the latest first', () async {
      await repository.record(on(CivilDate(2026, 9, 30)));
      await repository.record(on(CivilDate(2026, 10, 1)));
      await repository.record(on(today));
      await repository.record(on(CivilDate(2026, 11, 1)));

      final october = await repository
          .watchOperations(CivilDate(2026, 10, 1))
          .first;

      expect(october.map((operation) => operation.day), [
        today,
        CivilDate(2026, 10, 1),
      ]);
      expect(october.first.account?.name, 'Card');
      expect(october.first.category?.name, 'Food');
    });

    test('find the end of a short month', () async {
      await repository.record(on(CivilDate(2028, 2, 29)));
      await repository.record(on(CivilDate(2028, 3, 1)));

      final february = await repository
          .watchOperations(CivilDate(2028, 2, 1))
          .first;

      expect(february.single.day, CivilDate(2028, 2, 29));
    });

    test('are not cut off by the limit of a list', () async {
      for (var i = 0; i < 201; i++) {
        await repository.record(on(today));
      }

      final october = await repository
          .watchOperations(CivilDate(2026, 10, 1))
          .first;

      expect(october, hasLength(201));
    });

    test('keep what was archived after them', () async {
      await repository.record(on(today));
      await ledger.updateAccount(card.id, archived: true);
      await ledger.updateCategory(food.id, archived: true);

      final operation =
          (await repository.watchOperations(CivilDate(2026, 10, 1)).first)
              .single;

      expect(operation.account?.name, 'Card');
      expect(operation.category?.name, 'Food');
    });

    test('of income name a category of income', () async {
      final salary = await ledger.addCategory(
        kind: CategoryKind.income,
        name: 'Salary',
      );
      await repository.record(
        TransactionDraft.income(
          accountId: card.id,
          allocations: [
            Allocation(categoryId: salary.id, amount: rub(100)),
          ],
          occurredOn: today,
        ),
      );

      final operation =
          (await repository.watchOperations(CivilDate(2026, 10, 1)).first)
              .single;

      expect(operation.category?.name, 'Salary');
      expect(operation.amount, rub(100));
    });

    test('of a transfer start with what leaves', () async {
      final euro = await ledger.addAccount(
        name: 'Euro',
        type: AccountType.savings,
        openingBalance: Money(0, Currency.eur),
      );
      await repository.record(
        TransactionDraft.transfer(
          fromAccountId: card.id,
          sent: rub(90000),
          toAccountId: euro.id,
          received: Money(1000, Currency.eur),
          occurredOn: today,
        ),
      );

      final operation =
          (await repository.watchOperations(CivilDate(2026, 10, 1)).first)
              .single;

      expect(operation.account?.name, 'Card');
      expect(operation.toAccount?.name, 'Euro');
      expect(operation.amount, rub(-90000));
      expect(operation.received, Money(1000, Currency.eur));
      expect(await repository.lastAccountId(), card.id);
    });

    test('follow a write and a new name', () async {
      final titles = repository
          .watchOperations(CivilDate(2026, 10, 1))
          .map(
            (operations) => [
              for (final operation in operations) operation.category?.name,
            ],
          );
      final seen = expectLater(
        titles,
        emitsInOrder(<Object>[
          <String?>[],
          ['Food'],
          ['Meals'],
        ]),
      );

      await pumpEventQueue();
      await repository.record(on(today));
      await pumpEventQueue();
      await ledger.updateCategory(food.id, name: 'Meals');

      await seen;
    });

    test('one can be followed until it is deleted', () async {
      await repository.record(on(today));
      final id =
          (await repository.watchOperations(CivilDate(2026, 10, 1)).first)
              .single
              .id;
      final amounts = repository
          .watchOperation(id)
          .map((operation) => operation?.amount);
      final seen = expectLater(
        amounts,
        emitsInOrder(<Object?>[rub(-100), rub(-300), isNull]),
      );

      await pumpEventQueue();
      await repository.amend(
        id,
        TransactionDraft.expense(
          accountId: card.id,
          allocations: [Allocation(categoryId: food.id, amount: rub(300))],
          occurredOn: today,
        ),
      );
      await pumpEventQueue();
      await repository.delete(id);

      await seen;
    });

    test('name their months', () async {
      await repository.record(on(today));
      await repository.record(on(CivilDate(2026, 9, 1)));

      expect(await repository.months(), [
        CivilDate(2026, 10, 1),
        CivilDate(2026, 9, 1),
      ]);
    });
  });
}
