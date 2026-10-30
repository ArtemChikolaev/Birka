@TestOn('vm')
library;

import 'dart:math';

import 'package:database/database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
Money eur(int minorUnits) => Money(minorUnits, Currency.eur);

void main() {
  final today = CivilDate(2026, 10, 30);
  final at = DateTime.utc(2026, 10, 30, 12);
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late Account card;
  late Account euro;
  late Category cafe;
  late Category salary;

  Future<Money> balanceOf(Account account) =>
      ledger.watchBalance(account.id).first;

  TransactionDraft coffee(Money amount, {TransactionStatus? status}) {
    return TransactionDraft.expense(
      accountId: card.id,
      allocations: [Allocation(categoryId: cafe.id, amount: amount)],
      occurredOn: today,
      status: status ?? TransactionStatus.cleared,
    );
  }

  Future<List<String>> outbox() async {
    final changes = await (database.select(
      database.changes,
    )..orderBy([(row) => OrderingTerm(expression: row.sequence)])).get();
    return [
      for (final change in changes) '${change.operation} ${change.entity}',
    ];
  }

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database, now: () => at);
    card = await ledger.addAccount(
      name: 'Card',
      type: AccountType.debit,
      openingBalance: rub(100000),
    );
    euro = await ledger.addAccount(
      name: 'Euro',
      type: AccountType.savings,
      openingBalance: eur(0),
    );
    cafe = await ledger.addCategory(kind: CategoryKind.expense, name: 'Cafe');
    salary = await ledger.addCategory(
      kind: CategoryKind.income,
      name: 'Salary',
    );
  });

  tearDown(() => database.close());

  group('accounts', () {
    test('keep their currency and opening balance', () async {
      final bitcoin = await ledger.addAccount(
        name: 'Wallet',
        type: AccountType.crypto,
        openingBalance: Money(
          12345678,
          Currency.custom('BTC', decimalDigits: 8),
        ),
      );

      final accounts = await ledger.watchAccounts().first;
      final stored = accounts.singleWhere((a) => a.id == bitcoin.id);
      expect(stored.currency.decimalDigits, 8);
      expect(stored.openingBalance, bitcoin.openingBalance);
    });

    test('are listed in their order and without archived ones', () async {
      await ledger.updateAccount(card.id, sortOrder: 2);
      await ledger.updateAccount(euro.id, sortOrder: 1);
      expect((await ledger.watchAccounts().first).map((a) => a.name), [
        'Euro',
        'Card',
      ]);

      await ledger.updateAccount(euro.id, archived: true);
      expect((await ledger.watchAccounts().first).map((a) => a.name), ['Card']);
      expect(
        await ledger.watchAccounts(includeArchived: true).first,
        hasLength(2),
      );
    });

    test('go after the others unless told otherwise', () async {
      await ledger.addAccount(
        name: 'Another',
        type: AccountType.cash,
        openingBalance: rub(0),
      );
      await ledger.addAccount(
        name: 'First',
        type: AccountType.cash,
        openingBalance: rub(0),
        sortOrder: -1,
      );
      expect((await ledger.watchAccounts().first).map((a) => a.name), [
        'First',
        'Card',
        'Euro',
        'Another',
      ]);
    });

    test('keep their art and last digits until they change', () async {
      final savings = await ledger.addAccount(
        name: 'Savings',
        type: AccountType.savings,
        openingBalance: rub(0),
        lastDigits: '4568',
        art: AccountArt.graphite,
      );
      expect(savings.lastDigits, '4568');
      expect(savings.art, AccountArt.graphite);

      await ledger.updateAccount(savings.id, name: 'Reserve');
      expect((await ledger.account(savings.id))?.lastDigits, '4568');

      await ledger.updateAccount(savings.id, lastDigits: const Value(null));
      expect((await ledger.account(savings.id))?.lastDigits, isNull);
    });

    test('can change their opening balance within their currency', () async {
      await ledger.updateAccount(card.id, openingBalance: rub(500));
      expect(await balanceOf(card), rub(500));

      await expectLater(
        ledger.updateAccount(card.id, openingBalance: eur(500)),
        throwsA(isA<LedgerException>()),
      );
      expect(await balanceOf(card), rub(500));
    });

    test('are found by id, and an unknown one is not', () async {
      expect((await ledger.account(card.id))?.name, 'Card');
      expect(await ledger.account('nobody'), isNull);
    });

    test('an unknown account cannot be updated', () {
      expect(
        ledger.updateAccount('no such account', name: 'New'),
        throwsA(isA<LedgerException>()),
      );
    });
  });

  group('categories', () {
    test('go after the others of their kind', () async {
      await ledger.addCategory(kind: CategoryKind.expense, name: 'Taxi');
      await ledger.addCategory(kind: CategoryKind.income, name: 'Bonus');
      await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'First',
        sortOrder: -1,
      );

      final names = (await ledger.watchCategories(CategoryKind.expense).first)
          .map((category) => category.name);
      expect(names, ['First', 'Cafe', 'Taxi']);
    });

    test('change their fields and can lose their color', () async {
      await ledger.updateCategory(
        cafe.id,
        name: 'Coffee',
        icon: const Value('cup'),
        color: const Value('#fbbf24'),
      );
      var category = (await ledger.category(cafe.id))!;
      expect(category.name, 'Coffee');
      expect(category.icon, 'cup');
      expect(category.color, '#fbbf24');

      await ledger.updateCategory(cafe.id, color: const Value(null));
      category = (await ledger.category(cafe.id))!;
      expect(category.color, isNull);
      expect(category.icon, 'cup');
    });

    test('an archived one leaves the list unless asked', () async {
      await ledger.updateCategory(cafe.id, archived: true);

      expect(await ledger.watchCategories(CategoryKind.expense).first, isEmpty);
      final all = await ledger
          .watchCategories(CategoryKind.expense, includeArchived: true)
          .first;
      expect(all.single.archived, isTrue);
    });

    test('are found by id, and an unknown one is not', () async {
      expect((await ledger.category(cafe.id))?.name, 'Cafe');
      expect(await ledger.category('nobody'), isNull);
    });

    test('an unknown category cannot be updated', () {
      expect(
        ledger.updateCategory('nobody', name: 'Ghost'),
        throwsA(isA<LedgerException>()),
      );
    });

    test('a subcategory keeps to the kind of its parent', () {
      expect(
        ledger.addCategory(
          kind: CategoryKind.income,
          name: 'Tips',
          parentId: cafe.id,
        ),
        throwsA(isA<LedgerException>()),
      );
    });

    test('there are two levels and no more', () async {
      final child = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Coffee',
        parentId: cafe.id,
      );
      await expectLater(
        ledger.addCategory(
          kind: CategoryKind.expense,
          name: 'Espresso',
          parentId: child.id,
        ),
        throwsA(isA<LedgerException>()),
      );

      final other = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Taxi',
      );
      await expectLater(
        ledger.updateCategory(cafe.id, parentId: Value(other.id)),
        throwsA(isA<LedgerException>()),
      );
    });

    test('a category cannot be its own parent', () {
      expect(
        ledger.updateCategory(cafe.id, parentId: Value(cafe.id)),
        throwsA(isA<LedgerException>()),
      );
    });

    test('a subcategory can move to the top', () async {
      final child = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Coffee',
        parentId: cafe.id,
      );
      await ledger.updateCategory(child.id, parentId: const Value(null));
      expect((await ledger.category(child.id))?.parentId, isNull);
    });
  });

  group('balance', () {
    test('is the opening balance plus the entries', () async {
      await ledger.record(coffee(rub(25000)));
      await ledger.record(
        TransactionDraft.income(
          accountId: card.id,
          allocations: [Allocation(categoryId: salary.id, amount: rub(5000))],
          occurredOn: today,
        ),
      );

      expect(await balanceOf(card), rub(80000));
    });

    test('leaves out what is only planned', () async {
      await ledger.record(
        coffee(rub(25000), status: TransactionStatus.planned),
      );

      expect(await balanceOf(card), rub(100000));
    });

    test('a transfer between currencies moves both balances', () async {
      await ledger.record(
        TransactionDraft.transfer(
          fromAccountId: card.id,
          sent: rub(50000),
          toAccountId: euro.id,
          received: eur(500),
          occurredOn: today,
        ),
      );

      expect(await balanceOf(card), rub(50000));
      expect(await balanceOf(euro), eur(500));
    });

    test('an adjustment changes it without categories', () async {
      await ledger.record(
        TransactionDraft.adjustment(
          accountId: card.id,
          change: rub(-100),
          occurredOn: today,
        ),
      );

      expect(await balanceOf(card), rub(99900));
    });

    test('updates in the stream after each write', () async {
      final balances = ledger.watchBalance(card.id);
      final expectation = expectLater(
        balances,
        emitsInOrder([rub(100000), rub(90000)]),
      );
      await balanceOf(card);

      await ledger.record(coffee(rub(10000)));

      await expectation;
    });

    test('comes with each account in one stream', () async {
      await ledger.record(coffee(rub(250)));
      await ledger.record(coffee(rub(100), status: TransactionStatus.planned));
      await ledger.updateAccount(euro.id, archived: true);

      final active = await ledger.watchAccountBalances().first;
      expect(active.map((row) => row.account.name), ['Card']);
      expect(active.single.balance, await balanceOf(card));

      final all = await ledger
          .watchAccountBalances(includeArchived: true)
          .first;
      expect(all.map((row) => row.account.name), ['Card', 'Euro']);
      expect(all.last.balance, await balanceOf(euro));
    });

    test('a list of balances follows each write', () async {
      final seen = <Money>[];
      final subscription = ledger.watchAccountBalances().listen(
        (rows) => seen.add(rows.first.balance),
      );
      await pumpEventQueue();
      final opening = await balanceOf(card);

      await ledger.record(coffee(rub(250)));
      await pumpEventQueue();
      await subscription.cancel();

      expect(seen, [opening, opening - rub(250)]);
    });

    test('equals the opening balance plus every live entry', () async {
      final random = Random(20261030);
      var expected = 100000;
      final ids = <String, int>{};
      for (var i = 0; i < 200; i++) {
        final amount = 1 + random.nextInt(10000);
        switch (random.nextInt(3)) {
          case 0:
            ids[await ledger.record(coffee(rub(amount)))] = amount;
            expected -= amount;
          case 1 when ids.isNotEmpty:
            final id = ids.keys.elementAt(random.nextInt(ids.length));
            await ledger.delete(id);
            expected += ids.remove(id)!;
          case 2 when ids.isNotEmpty:
            final id = ids.keys.elementAt(random.nextInt(ids.length));
            await ledger.amend(id, coffee(rub(amount)));
            expected += ids[id]! - amount;
            ids[id] = amount;
        }
      }

      expect(await balanceOf(card), rub(expected));
    });
  });

  group('transactions', () {
    test('come back with their entries and allocations', () async {
      final id = await ledger.record(coffee(rub(25000)));

      final transaction = (await ledger.watchTransactions().first).single;
      expect(transaction.id, id);
      expect(transaction.kind, TransactionKind.expense);
      expect(transaction.occurredOn, today);
      expect(transaction.entries.single.amount, rub(-25000));
      expect(transaction.allocations.single.categoryId, cafe.id);
      expect(transaction.allocations.single.amount, rub(25000));
    });

    test('are listed by date, the latest first', () async {
      await ledger.record(
        TransactionDraft.adjustment(
          accountId: card.id,
          change: rub(1),
          occurredOn: CivilDate(2026, 10, 1),
        ),
      );
      await ledger.record(
        TransactionDraft.adjustment(
          accountId: card.id,
          change: rub(2),
          occurredOn: CivilDate(2026, 10, 20),
        ),
      );

      final dates = (await ledger.watchTransactions().first).map(
        (transaction) => transaction.occurredOn.day,
      );
      expect(dates, [20, 1]);
    });

    test('can be listed by account', () async {
      await ledger.record(coffee(rub(100)));
      await ledger.record(
        TransactionDraft.adjustment(
          accountId: euro.id,
          change: eur(1),
          occurredOn: today,
        ),
      );

      final ofEuro = await ledger.watchTransactions(accountId: euro.id).first;
      expect(ofEuro.single.entries.single.accountId, euro.id);
    });

    test('an amendment replaces the entries and allocations', () async {
      final id = await ledger.record(coffee(rub(25000)));

      await ledger.amend(id, coffee(rub(10000)));

      final transaction = (await ledger.watchTransactions().first).single;
      expect(transaction.id, id);
      expect(transaction.entries.single.amount, rub(-10000));
      expect(transaction.allocations.single.amount, rub(10000));
      expect(await balanceOf(card), rub(90000));
    });

    test('deleting leaves tombstones and returns the money', () async {
      final id = await ledger.record(coffee(rub(25000)));

      await ledger.delete(id);

      expect(await ledger.watchTransactions().first, isEmpty);
      expect(await balanceOf(card), rub(100000));
      final row = await database.select(database.transactions).getSingle();
      expect(row.deletedAt, at);
      final entry = await database.select(database.entries).getSingle();
      expect(entry.deletedAt, at);
      final allocation = await database
          .select(database.allocations)
          .getSingle();
      expect(allocation.deletedAt, at);
    });

    test('a deleted transaction cannot be amended or deleted again', () async {
      final id = await ledger.record(coffee(rub(100)));
      await ledger.delete(id);

      expect(
        ledger.amend(id, coffee(rub(200))),
        throwsA(isA<LedgerException>()),
      );
      expect(ledger.delete(id), throwsA(isA<LedgerException>()));
    });
  });

  group('rules of the database', () {
    final fails = throwsA(isA<LedgerException>());

    test('an account has to exist', () {
      expect(
        ledger.record(
          TransactionDraft.adjustment(
            accountId: 'no such account',
            change: rub(1),
            occurredOn: today,
          ),
        ),
        fails,
      );
    });

    test('an amount has to be in the currency of the account', () {
      expect(
        ledger.record(
          TransactionDraft.adjustment(
            accountId: card.id,
            change: eur(1),
            occurredOn: today,
          ),
        ),
        fails,
      );
    });

    test('a category has to exist', () {
      expect(
        ledger.record(
          TransactionDraft.expense(
            accountId: card.id,
            allocations: [
              Allocation(categoryId: 'no such category', amount: rub(1)),
            ],
            occurredOn: today,
          ),
        ),
        fails,
      );
    });

    test('a category has to fit the kind of the transaction', () {
      expect(
        ledger.record(
          TransactionDraft.expense(
            accountId: card.id,
            allocations: [Allocation(categoryId: salary.id, amount: rub(1))],
            occurredOn: today,
          ),
        ),
        fails,
      );
    });

    test('a rejected write leaves nothing behind', () async {
      final before = await outbox();

      await expectLater(
        ledger.record(
          TransactionDraft.transfer(
            fromAccountId: card.id,
            sent: rub(100),
            toAccountId: 'no such account',
            received: rub(100),
            occurredOn: today,
          ),
        ),
        fails,
      );

      expect(await database.select(database.transactions).get(), isEmpty);
      expect(await outbox(), before);
    });
  });

  group('sync readiness', () {
    test('every change lands in the outbox in order', () async {
      await database.delete(database.changes).go();

      final id = await ledger.record(coffee(rub(100)));
      await ledger.amend(id, coffee(rub(200)));
      await ledger.delete(id);

      expect(await outbox(), [
        'insert transactions',
        'insert entries',
        'insert allocations',
        'update transactions',
        'delete entries',
        'delete allocations',
        'insert entries',
        'insert allocations',
        'delete transactions',
        'delete entries',
        'delete allocations',
      ]);
    });

    test('ids are UUIDv7 strings by default', () async {
      final fresh = LedgerRepository(database);

      final account = await fresh.addAccount(
        name: 'Cash',
        type: AccountType.cash,
        openingBalance: rub(0),
      );

      expect(
        account.id,
        matches(RegExp('^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab]')),
      );
    });

    test('rows carry their timestamps in UTC', () async {
      final local = DateTime(2026, 10, 30, 15);
      final fresh = LedgerRepository(database, now: () => local);

      final id = (await fresh.addAccount(
        name: 'Cash',
        type: AccountType.cash,
        openingBalance: rub(0),
      )).id;

      final row = await (database.select(
        database.accounts,
      )..where((row) => row.id.equals(id))).getSingle();
      expect(row.createdAt, local.toUtc());
      expect(row.updatedAt, local.toUtc());
      expect(row.deletedAt, isNull);
    });
  });
}
