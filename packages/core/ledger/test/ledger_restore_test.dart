@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
Money eur(int minorUnits) => Money(minorUnits, Currency.eur);

/// What a test compares: every field of every transaction and its legs.
Future<List<String>> transactionsOf(LedgerRepository ledger) async => [
  for (final it in await ledger.watchTransactions(limit: null).first)
    [
      it.id,
      it.kind.name,
      it.occurredOn,
      it.occurredAt?.toUtc(),
      it.note,
      it.status.name,
      it.source.name,
      for (final entry in it.entries) '${entry.accountId} ${entry.amount}',
      for (final split in it.allocations) '${split.categoryId} ${split.amount}',
    ].join(' | '),
];

Future<int> rowsIn(BirkaDatabase database, TableInfo<Table, Object?> table) =>
    database.select(table).get().then((rows) => rows.length);

void main() {
  final today = CivilDate(2026, 10, 30);
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late Account card;
  late Account euro;
  late Category food;
  late Category cafe;
  late Category salary;
  late String deleted;
  late Schedule rent;

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(
      database,
      now: () => DateTime.utc(2026, 10, 30, 12),
    );
    card = await ledger.addAccount(
      name: 'Card',
      type: AccountType.debit,
      openingBalance: rub(100000),
      lastDigits: '4568',
      art: AccountArt.violet,
    );
    euro = await ledger.addAccount(
      name: 'Euro',
      type: AccountType.savings,
      openingBalance: eur(5000),
      includeInTotals: false,
    );
    food = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Food',
      icon: 'cart',
      color: '#4ade80',
    );
    cafe = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Cafe',
      parentId: food.id,
    );
    salary = await ledger.addCategory(
      kind: CategoryKind.income,
      name: 'Salary',
    );
    await ledger.record(
      TransactionDraft.expense(
        accountId: card.id,
        allocations: [
          Allocation(categoryId: cafe.id, amount: rub(30000)),
          Allocation(categoryId: food.id, amount: rub(15000)),
        ],
        occurredOn: today,
        occurredAt: DateTime.utc(2026, 10, 30, 9, 15),
        note: 'Lunch',
      ),
    );
    final pay = await ledger.record(
      TransactionDraft.income(
        accountId: card.id,
        allocations: [Allocation(categoryId: salary.id, amount: rub(800000))],
        occurredOn: today,
      ),
    );
    // An amended transaction leaves the tombstones of its old legs.
    await ledger.amend(
      pay,
      TransactionDraft.income(
        accountId: card.id,
        allocations: [Allocation(categoryId: salary.id, amount: rub(900000))],
        occurredOn: today,
        status: TransactionStatus.reconciled,
      ),
    );
    await ledger.record(
      TransactionDraft.transfer(
        fromAccountId: card.id,
        sent: rub(1000000),
        toAccountId: euro.id,
        received: eur(10000),
        occurredOn: today,
      ),
    );
    await ledger.record(
      TransactionDraft.adjustment(
        accountId: euro.id,
        change: eur(-150),
        occurredOn: today,
      ),
    );
    deleted = await ledger.record(
      TransactionDraft.expense(
        accountId: card.id,
        allocations: [Allocation(categoryId: cafe.id, amount: rub(99900))],
        occurredOn: today,
        note: 'Deleted',
      ),
    );
    await ledger.delete(deleted);
    await ledger.updateAccount(euro.id, archived: true);
    rent = await ledger.addSchedule(
      kind: TransactionKind.expense,
      name: 'Rent',
      accountId: card.id,
      categoryId: food.id,
      amount: rub(4500000),
      every: ScheduleEvery.month,
      next: CivilDate(2026, 11, 25),
      reminder: ScheduleReminder.dayBefore,
    );
    final gone = await ledger.addSchedule(
      kind: TransactionKind.income,
      name: 'Gone',
      accountId: card.id,
      amount: rub(100),
      every: ScheduleEvery.week,
      next: CivilDate(2026, 11, 2),
    );
    await ledger.deleteSchedule(gone.id);
  });

  tearDown(() => database.close());

  test('counts what the ledger holds, archived rows included', () async {
    final counts = ledger.watchCounts();

    expect(
      await counts.first,
      const LedgerCounts(accounts: 2, categories: 3, transactions: 4),
    );
    await ledger.addCategory(kind: CategoryKind.income, name: 'Gifts');
    expect(
      await counts.first,
      const LedgerCounts(accounts: 2, categories: 4, transactions: 4),
    );
  });

  group('a copy', () {
    test('holds the living rows and leaves the tombstones out', () async {
      final copy = await ledger.copy();

      expect(copy.counts, await ledger.watchCounts().first);
      expect(copy.madeAt, DateTime.utc(2026, 10, 30, 12));
      expect(
        copy.transactionRows.map((row) => row.id),
        isNot(contains(deleted)),
      );
      expect(copy.entryRows, hasLength(5));
      expect(copy.allocationRows, hasLength(3));
      expect(copy.scheduleRows.map((row) => row.id), [rent.id]);
      expect(copy.encode(), isNot(contains('Deleted')));
      expect(copy.encode(), isNot(contains('Gone')));
    });

    test('reads back from its file', () async {
      final copy = await ledger.copy();
      final read = LedgerCopy.parse(copy.encode());

      expect(read.encode(), copy.encode());
    });
  });

  group('a restore', () {
    late BirkaDatabase other;
    late LedgerRepository restored;

    setUp(() {
      other = BirkaDatabase(NativeDatabase.memory());
      restored = LedgerRepository(
        other,
        now: () => DateTime.utc(2026, 11, 2, 18),
      );
    });

    tearDown(() => other.close());

    test('brings the same ledger to another device', () async {
      final copy = LedgerCopy.parse((await ledger.copy()).encode());

      await restored.restore(copy);

      expect(await transactionsOf(restored), await transactionsOf(ledger));
      expect(
        await restored.watchBalance(card.id).first,
        await ledger.watchBalance(card.id).first,
      );
      expect(await restored.watchBalance(euro.id).first, eur(14850));
      final accounts = await restored
          .watchAccounts(includeArchived: true)
          .first;
      expect(accounts.map((it) => it.name), ['Card', 'Euro']);
      expect(accounts.first.lastDigits, '4568');
      expect(accounts.first.art, AccountArt.violet);
      expect(accounts.last.includeInTotals, isFalse);
      expect(accounts.last.archived, isTrue);
      final categories = await restored
          .watchCategories(CategoryKind.expense)
          .first;
      expect(categories.map((it) => (it.name, it.parentId)), [
        ('Food', null),
        ('Cafe', food.id),
      ]);
      expect(categories.first.icon, 'cart');
      expect(categories.first.color, '#4ade80');
      expect(await restored.watchSchedules().first, [rent]);
      final card_ = await (other.select(
        other.accounts,
      )..where((row) => row.id.equals(card.id))).getSingle();
      expect(card_.createdAt, DateTime.utc(2026, 10, 30, 12));
    });

    test('replaces what was there, tombstones included', () async {
      await restored.addAccount(
        name: 'Old',
        type: AccountType.cash,
        openingBalance: rub(0),
      );

      await restored.restore(await ledger.copy());

      final names = await restored.watchAccounts(includeArchived: true).first;
      expect(names.map((it) => it.name), ['Card', 'Euro']);
      expect(await rowsIn(other, other.accounts), 2);
      expect(await rowsIn(other, other.transactions), 4);
      expect(await rowsIn(other, other.entries), 5);
    });

    test('starts the outbox again with the restored rows', () async {
      await restored.addAccount(
        name: 'Old',
        type: AccountType.cash,
        openingBalance: rub(0),
      );

      await restored.restore(await ledger.copy());

      final changes = await other.select(other.changes).get();
      expect(changes, hasLength(2 + 3 + 4 + 5 + 3 + 1));
      expect(changes.map((it) => it.operation).toSet(), {'insert'});
      expect(changes.map((it) => it.changedAt).toSet(), {
        DateTime.utc(2026, 11, 2, 18),
      });
      expect(
        changes.where((it) => it.entity == 'accounts').map((it) => it.entityId),
        unorderedEquals([card.id, euro.id]),
      );
    });

    test('that fails leaves the ledger as it was', () async {
      final old = await restored.addAccount(
        name: 'Old',
        type: AccountType.cash,
        openingBalance: rub(0),
      );
      final copy = await ledger.copy();
      // A subcategory before its parent breaks a foreign key on the way in.
      final broken = LedgerCopy.of(
        madeAt: copy.madeAt,
        importRows: copy.importRows,
        accountRows: copy.accountRows,
        categoryRows: copy.categoryRows.reversed.toList(),
        transactionRows: copy.transactionRows,
        entryRows: copy.entryRows,
        allocationRows: copy.allocationRows,
        scheduleRows: copy.scheduleRows,
        tagRows: copy.tagRows,
        transactionTagRows: copy.transactionTagRows,
      );

      await expectLater(restored.restore(broken), throwsA(anything));

      final accounts = await restored.watchAccounts().first;
      expect(accounts.map((it) => it.id), [old.id]);
      expect(await rowsIn(other, other.changes), 1);
    });
  });

  test('a wipe leaves nothing of the ledger but keeps the rates', () async {
    await database
        .into(database.exchangeRates)
        .insert(
          ExchangeRatesCompanion.insert(
            day: '2026-10-30',
            currency: 'EUR',
            rubles: '100.5',
          ),
        );

    await ledger.wipe();

    expect(
      await ledger.watchCounts().first,
      const LedgerCounts(accounts: 0, categories: 0, transactions: 0),
    );
    for (final table in <TableInfo<Table, Object?>>[
      database.accounts,
      database.categories,
      database.transactions,
      database.entries,
      database.allocations,
      database.schedules,
      database.changes,
    ]) {
      expect(await rowsIn(database, table), 0, reason: table.actualTableName);
    }
    expect(await rowsIn(database, database.exchangeRates), 1);
  });
}
