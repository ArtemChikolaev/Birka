@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

void main() {
  final october = CivilDate(2026, 10, 1);
  final end = CivilDate(2026, 10, 31);
  var at = DateTime.utc(2026, 11, 4, 12);
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late Account card;
  late Category cafe;

  TransactionDraft spent(
    Money amount, {
    String? accountId,
    String? categoryId,
    CivilDate? day,
  }) => TransactionDraft.expense(
    accountId: accountId ?? card.id,
    allocations: [Allocation(categoryId: categoryId, amount: amount)],
    occurredOn: day ?? CivilDate(2026, 10, 3),
    source: TransactionSource.import,
  );

  Future<List<String>> outbox() async {
    final changes = await (database.select(
      database.changes,
    )..orderBy([(row) => OrderingTerm(expression: row.sequence)])).get();
    return [
      for (final change in changes) '${change.operation} ${change.entity}',
    ];
  }

  Future<String> importOf(String fileName) => ledger.addImport(
    fileName: fileName,
    format: 'alfa',
    firstDay: october,
    lastDay: end,
  );

  setUp(() async {
    at = DateTime.utc(2026, 11, 4, 12);
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database, now: () => at);
    card = await ledger.addAccount(
      name: 'Card',
      type: AccountType.debit,
      openingBalance: rub(100000),
    );
    cafe = await ledger.addCategory(kind: CategoryKind.expense, name: 'Cafe');
  });

  tearDown(() => database.close());

  group('an operation without a category', () {
    test('goes in and reads back without one', () async {
      final id = await ledger.record(spent(rub(42000)));
      final transaction = (await ledger.watchTransaction(id).first)!;
      expect(transaction.allocations.single.categoryId, isNull);
      expect(transaction.allocations.single.amount, rub(42000));
      expect(await ledger.watchBalance(card.id).first, rub(58000));
    });

    test('counts in the days of its kind without a category', () async {
      await ledger.record(spent(rub(42000)));
      await ledger.record(spent(rub(10000), categoryId: cafe.id));
      final days = await ledger
          .watchCategoryDays(CategoryKind.expense, from: october, to: end)
          .first;
      expect(
        {for (final row in days) row.category?.name: row.total},
        {null: rub(42000), 'Cafe': rub(10000)},
      );
      final income = await ledger
          .watchCategoryDays(CategoryKind.income, from: october, to: end)
          .first;
      expect(income, isEmpty);
    });

    test('takes a category later', () async {
      final id = await ledger.record(spent(rub(42000)));
      await ledger.amend(id, spent(rub(42000), categoryId: cafe.id));
      final transaction = (await ledger.watchTransaction(id).first)!;
      expect(transaction.allocations.single.categoryId, cafe.id);
    });
  });

  group('an import', () {
    test('names what it brings', () async {
      final id = await importOf('alfa-2026-10.xlsx');
      final account = await ledger.addAccount(
        name: 'Salary card',
        type: AccountType.debit,
        openingBalance: rub(0),
        importId: id,
      );
      final gifts = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Gifts',
        importId: id,
      );
      final coffee = await ledger.record(
        spent(rub(42000), accountId: account.id, categoryId: gifts.id),
        importId: id,
      );
      expect((await ledger.watchTransaction(coffee).first)!.importId, id);
      final [row] = await ledger.watchImports().first;
      expect(row.id, id);
      expect(row.fileName, 'alfa-2026-10.xlsx');
      expect(row.format, 'alfa');
      expect(row.firstDay, october);
      expect(row.lastDay, end);
      expect(row.importedAt, at);
      expect(row.transactions, 1);
      expect(row.accountIds, {account.id});
    });

    test('lists the latest first and only with operations', () async {
      final empty = await importOf('empty.csv');
      final first = await importOf('september.csv');
      await ledger.record(spent(rub(100)), importId: first);
      await ledger.record(spent(rub(200)), importId: first);
      at = at.add(const Duration(minutes: 1));
      final second = await importOf('october.csv');
      await ledger.record(spent(rub(300)), importId: second);
      final rows = await ledger.watchImports().first;
      expect(rows.map((row) => (row.id, row.transactions)), [
        (second, 1),
        (first, 2),
      ]);
      expect(rows.map((row) => row.id), isNot(contains(empty)));
    });

    test('goes out at once and leaves the rest of the ledger', () async {
      final mine = await ledger.record(spent(rub(5000), categoryId: cafe.id));
      final id = await importOf('alfa-2026-10.xlsx');
      final other = await importOf('wise.csv');
      final theirs = await ledger.record(spent(rub(700)), importId: other);
      for (final amount in [42000, 61200, 234050]) {
        await ledger.record(spent(rub(amount)), importId: id);
      }
      expect(await ledger.watchBalance(card.id).first, rub(-242950));
      await ledger.undoImport(id);
      final left = await ledger.watchTransactions(limit: null).first;
      expect(left.map((it) => it.id), unorderedEquals([mine, theirs]));
      expect(await ledger.watchBalance(card.id).first, rub(94300));
      expect(
        (await ledger.watchImports().first).map((row) => row.id),
        [other],
      );
      final deleted = await (database.select(
        database.transactions,
      )..where((row) => row.deletedAt.isNotNull())).get();
      expect(deleted, hasLength(3));
      final buried = await (database.select(
        database.entries,
      )..where((row) => row.deletedAt.isNotNull())).get();
      expect(buried, hasLength(3));
      await expectLater(
        ledger.undoImport(id),
        throwsA(isA<LedgerException>()),
      );
    });

    test('takes away what it added unless something else uses it', () async {
      final id = await importOf('zenmoney.csv');
      final cash = await ledger.addAccount(
        name: 'Cash',
        type: AccountType.cash,
        openingBalance: rub(150000),
        importId: id,
      );
      final kept = await ledger.addAccount(
        name: 'Deposit',
        type: AccountType.savings,
        openingBalance: rub(0),
        importId: id,
      );
      final travel = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Travel',
        importId: id,
      );
      final tickets = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Tickets',
        parentId: travel.id,
        importId: id,
      );
      final pets = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Pets',
        importId: id,
      );
      await ledger.record(
        spent(rub(900000), accountId: cash.id, categoryId: tickets.id),
        importId: id,
      );
      // The person used the deposit and the pets after the import.
      await ledger.record(
        spent(rub(1000), accountId: kept.id, categoryId: pets.id),
      );
      final changesBefore = (await outbox()).length;
      await ledger.undoImport(id);
      final accounts = await ledger.watchAccounts(includeArchived: true).first;
      expect(accounts.map((it) => it.name), ['Card', 'Deposit']);
      final categories = await ledger
          .watchCategories(CategoryKind.expense, includeArchived: true)
          .first;
      expect(categories.map((it) => it.name), ['Cafe', 'Pets']);
      final rows = await database.select(database.accounts).get();
      expect(
        rows.singleWhere((row) => row.id == kept.id).importId,
        isNull,
      );
      expect(
        (await database.select(database.categories).get())
            .singleWhere((row) => row.id == pets.id)
            .importId,
        isNull,
      );
      expect((await outbox()).skip(changesBefore), [
        'delete imports',
        'delete transactions',
        'delete entries',
        'delete allocations',
        'delete accounts',
        'update accounts',
        'delete categories',
        'delete categories',
        'update categories',
      ]);
    });
  });

  group('a copy', () {
    test('keeps the imports and what waits for a category', () async {
      final id = await importOf('alfa-2026-10.xlsx');
      final account = await ledger.addAccount(
        name: 'Salary card',
        type: AccountType.debit,
        openingBalance: rub(0),
        importId: id,
      );
      await ledger.record(
        spent(rub(42000), accountId: account.id),
        importId: id,
      );
      final text = (await ledger.copy()).encode();
      final copy = LedgerCopy.parse(text);
      final other = BirkaDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      final restored = LedgerRepository(other, now: () => at);
      await restored.restore(copy);
      final [row] = await restored.watchImports().first;
      expect(row.id, id);
      expect(row.accountIds, {account.id});
      final transaction =
          (await restored.watchTransactions(limit: null).first).single;
      expect(transaction.importId, id);
      expect(transaction.allocations.single.categoryId, isNull);
      await restored.undoImport(id);
      expect(await restored.watchTransactions().first, isEmpty);
      expect(
        (await restored.watchAccounts().first).map((it) => it.name),
        ['Card'],
      );
    });

    test('of an undone import keeps an account that stayed', () async {
      final id = await importOf('alfa-2026-10.xlsx');
      final account = await ledger.addAccount(
        name: 'Salary card',
        type: AccountType.debit,
        openingBalance: rub(0),
        importId: id,
      );
      await ledger.record(spent(rub(42000), accountId: account.id));
      await ledger.undoImport(id);
      final copy = LedgerCopy.parse((await ledger.copy()).encode());
      expect(copy.importRows, isEmpty);
      expect(copy.accountRows.map((row) => row.importId), [null, null]);
    });

    test('is damaged when a row names an import it lacks', () async {
      final id = await importOf('alfa-2026-10.xlsx');
      await ledger.record(spent(rub(42000)), importId: id);
      final text = (await ledger.copy()).encode().replaceFirst(
        '"fileName":"alfa-2026-10.xlsx"',
        '"fileName":"alfa-2026-10.xlsx","id":"other"',
      );
      expect(
        () => LedgerCopy.parse(text),
        throwsA(
          isA<LedgerCopyException>().having(
            (error) => error.problem,
            'problem',
            LedgerCopyProblem.damaged,
          ),
        ),
      );
    });
  });
}
