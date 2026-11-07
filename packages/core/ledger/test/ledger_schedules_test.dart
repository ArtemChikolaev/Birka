@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
Money eur(int minorUnits) => Money(minorUnits, Currency.eur);

Matcher throwsLedger() => throwsA(isA<LedgerException>());

/// The clock of the ledger.
final now = DateTime.utc(2026, 11, 18, 12);

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late Account card;
  late Account cash;
  late Account euro;
  late Category home;
  late Category salary;

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database, now: () => now);
    card = await ledger.addAccount(
      name: 'Card',
      type: AccountType.debit,
      openingBalance: rub(8640000),
    );
    cash = await ledger.addAccount(
      name: 'Cash',
      type: AccountType.cash,
      openingBalance: rub(320000),
    );
    euro = await ledger.addAccount(
      name: 'Euro',
      type: AccountType.savings,
      openingBalance: eur(10000),
    );
    home = await ledger.addCategory(kind: CategoryKind.expense, name: 'Home');
    salary = await ledger.addCategory(
      kind: CategoryKind.income,
      name: 'Salary',
    );
  });

  tearDown(() => database.close());

  Future<Schedule> addRent({
    ScheduleOnDay onDay = ScheduleOnDay.ask,
    CivilDate? next,
    String? categoryId,
    bool withCategory = true,
  }) => ledger.addSchedule(
    kind: TransactionKind.expense,
    name: 'Rent',
    accountId: card.id,
    categoryId: withCategory ? categoryId ?? home.id : null,
    amount: rub(4500000),
    every: ScheduleEvery.month,
    next: next ?? CivilDate(2026, 11, 25),
    onDay: onDay,
  );

  group('a regular payment', () {
    test('takes the day of its first time and lists by the next', () async {
      final rent = await addRent();
      final pay = await ledger.addSchedule(
        kind: TransactionKind.income,
        name: 'Salary',
        accountId: card.id,
        categoryId: salary.id,
        amount: rub(12000000),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 12, 5),
      );
      final internet = await ledger.addSchedule(
        kind: TransactionKind.expense,
        name: 'Internet',
        accountId: card.id,
        amount: rub(65000),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 11, 28),
        reminder: ScheduleReminder.none,
      );

      final schedules = await ledger.watchSchedules().first;

      expect(schedules, [rent, internet, pay]);
      expect(rent.day, 25);
      expect(rent.onDay, ScheduleOnDay.ask);
      expect(rent.reminder, ScheduleReminder.onDay);
      expect(schedules.first.amount, rub(4500000));
      expect(internet.categoryId, isNull);
      expect(await ledger.schedule(pay.id), pay);
      expect(await ledger.schedule('none'), isNull);
    });

    test('keeps its day for the months that have it', () async {
      final schedule = await ledger.addSchedule(
        kind: TransactionKind.expense,
        name: 'Gym',
        accountId: card.id,
        amount: rub(350000),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 11, 30),
        day: 31,
      );

      expect(schedule.day, 31);
      expect(schedule.after(schedule.next), CivilDate(2026, 12, 31));
    });

    test('refuses what could not give a transaction', () async {
      Future<Schedule> add({
        TransactionKind kind = TransactionKind.expense,
        String name = 'Rent',
        String? accountId,
        String? toAccountId,
        String? categoryId,
        Money? amount,
        int? day,
      }) => ledger.addSchedule(
        kind: kind,
        name: name,
        accountId: accountId ?? card.id,
        toAccountId: toAccountId,
        categoryId: categoryId,
        amount: amount ?? rub(100),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 11, 25),
        day: day,
      );

      await expectLater(add(name: '  '), throwsLedger());
      await expectLater(add(amount: rub(0)), throwsLedger());
      await expectLater(add(amount: rub(-100)), throwsLedger());
      await expectLater(add(amount: eur(100)), throwsLedger());
      await expectLater(add(accountId: 'none'), throwsLedger());
      await expectLater(add(day: 0), throwsLedger());
      await expectLater(add(day: 32), throwsLedger());
      await expectLater(add(categoryId: salary.id), throwsLedger());
      await expectLater(add(categoryId: 'none'), throwsLedger());
      await expectLater(add(toAccountId: cash.id), throwsLedger());
      await expectLater(
        add(kind: TransactionKind.transfer),
        throwsLedger(),
      );
      await expectLater(
        add(kind: TransactionKind.transfer, toAccountId: card.id),
        throwsLedger(),
      );
      await expectLater(
        add(kind: TransactionKind.transfer, toAccountId: euro.id),
        throwsLedger(),
      );
      await expectLater(
        add(
          kind: TransactionKind.transfer,
          toAccountId: cash.id,
          categoryId: home.id,
        ),
        throwsLedger(),
      );
      await expectLater(
        add(kind: TransactionKind.adjustment),
        throwsLedger(),
      );
      expect(await ledger.watchSchedules().first, isEmpty);
    });

    test('changes in place and keeps its id', () async {
      final rent = await addRent();
      final changed = Schedule(
        id: rent.id,
        kind: TransactionKind.expense,
        name: 'Flat',
        accountId: cash.id,
        amount: rub(4800000),
        every: ScheduleEvery.month,
        day: 20,
        next: CivilDate(2026, 12, 20),
        onDay: ScheduleOnDay.post,
        reminder: ScheduleReminder.dayBefore,
      );

      await ledger.updateSchedule(changed);

      expect(await ledger.watchSchedules().first, [changed]);
      await ledger.deleteSchedule(rent.id);
      await expectLater(ledger.updateSchedule(changed), throwsLedger());
    });

    test('keeps what was done to it through a change, unless its next time '
        'moves', () async {
      final rent = await addRent();
      await ledger.skipSchedule(rent.id);
      final skipped = (await ledger.schedule(rent.id))!;

      await ledger.updateSchedule(
        Schedule(
          id: rent.id,
          kind: rent.kind,
          name: 'Flat',
          accountId: rent.accountId,
          categoryId: rent.categoryId,
          amount: rub(4700000),
          every: rent.every,
          day: rent.day,
          next: skipped.next,
          onDay: rent.onDay,
          reminder: rent.reminder,
        ),
      );
      expect((await ledger.schedule(rent.id))!.last, skipped.last);

      await ledger.updateSchedule(skipped.movedTo(CivilDate(2026, 12, 28)));
      expect((await ledger.schedule(rent.id))!.last, isNull);
    });

    test('goes and leaves the transactions it gave', () async {
      final rent = await addRent();
      await ledger.postSchedule(rent.id);

      await ledger.deleteSchedule(rent.id);

      expect(await ledger.watchSchedules().first, isEmpty);
      expect(await ledger.schedule(rent.id), isNull);
      expect(await ledger.watchTransactions().first, hasLength(1));
      await expectLater(ledger.deleteSchedule(rent.id), throwsLedger());
      await expectLater(ledger.postSchedule(rent.id), throwsLedger());
    });

    test('leaves a change in the outbox for each write', () async {
      final rent = await addRent();
      await ledger.skipSchedule(rent.id);
      await ledger.deleteSchedule(rent.id);

      final changes = await (database.select(
        database.changes,
      )..where((row) => row.entity.equals('schedules'))).get();

      expect(changes.map((it) => (it.entityId, it.operation)), [
        (rent.id, 'insert'),
        (rent.id, 'update'),
        (rent.id, 'delete'),
      ]);
    });
  });

  group('posting', () {
    test('records the next time as a transaction and moves on', () async {
      final rent = await addRent();

      final id = await ledger.postSchedule(rent.id);

      final transaction = (await ledger.watchTransaction(id).first)!;
      expect(transaction.kind, TransactionKind.expense);
      expect(transaction.occurredOn, CivilDate(2026, 11, 25));
      expect(transaction.note, 'Rent');
      expect(transaction.status, TransactionStatus.cleared);
      expect(transaction.source, TransactionSource.recurring);
      expect(transaction.entries.single.accountId, card.id);
      expect(transaction.entries.single.amount, rub(-4500000));
      expect(transaction.allocations.single.categoryId, home.id);
      expect(await ledger.balance(card.id), rub(4140000));
      expect(
        (await ledger.schedule(rent.id))!.next,
        CivilDate(2026, 12, 25),
      );
    });

    test('takes another amount or day, as for a bill that changes', () async {
      final rent = await addRent();

      final id = await ledger.postSchedule(
        rent.id,
        amount: rub(4380000),
        on: CivilDate(2026, 11, 27),
      );

      final transaction = (await ledger.watchTransaction(id).first)!;
      expect(transaction.entries.single.amount, rub(-4380000));
      expect(transaction.occurredOn, CivilDate(2026, 11, 27));
      expect(
        (await ledger.schedule(rent.id))!.next,
        CivilDate(2026, 12, 25),
      );
      expect((await ledger.schedule(rent.id))!.amount, rub(4500000));
    });

    test('of a payment without a category leaves it to the inbox', () async {
      final rent = await addRent(withCategory: false);

      final id = await ledger.postSchedule(rent.id);

      final transaction = (await ledger.watchTransaction(id).first)!;
      expect(transaction.allocations.single.categoryId, isNull);
      expect(transaction.allocations.single.amount, rub(4500000));
    });

    test('of an income and of a transfer', () async {
      final pay = await ledger.addSchedule(
        kind: TransactionKind.income,
        name: 'Salary',
        accountId: card.id,
        categoryId: salary.id,
        amount: rub(12000000),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 12, 5),
      );
      final save = await ledger.addSchedule(
        kind: TransactionKind.transfer,
        name: 'To cash',
        accountId: card.id,
        toAccountId: cash.id,
        amount: rub(1000000),
        every: ScheduleEvery.week,
        next: CivilDate(2026, 11, 20),
      );

      final income = (await ledger
          .watchTransaction(
            await ledger.postSchedule(pay.id),
          )
          .first)!;
      final transfer = (await ledger
          .watchTransaction(
            await ledger.postSchedule(save.id),
          )
          .first)!;

      expect(income.entries.single.amount, rub(12000000));
      expect(income.allocations.single.categoryId, salary.id);
      expect(transfer.kind, TransactionKind.transfer);
      expect(transfer.entries.map((it) => (it.accountId, it.amount)), [
        (card.id, rub(-1000000)),
        (cash.id, rub(1000000)),
      ]);
      expect(transfer.allocations, isEmpty);
      expect((await ledger.schedule(save.id))!.next, CivilDate(2026, 11, 27));
    });

    test('keeps what it did to the last time, as skipping does', () async {
      final rent = await addRent();

      final id = await ledger.postSchedule(rent.id);

      expect(
        (await ledger.schedule(rent.id))!.last,
        ScheduleLast(
          done: ScheduleDone.posted,
          from: CivilDate(2026, 11, 25),
          on: CivilDate(2026, 11, 25),
          at: now,
          transactionId: id,
        ),
      );
      await ledger.skipSchedule(rent.id);
      expect(
        (await ledger.schedule(rent.id))!.last,
        ScheduleLast(
          done: ScheduleDone.skipped,
          from: CivilDate(2026, 12, 25),
          on: CivilDate(2026, 12, 25),
          at: now,
        ),
      );
    });

    test('skips a time without a transaction', () async {
      final rent = await addRent();

      await ledger.skipSchedule(rent.id);

      expect(await ledger.watchTransactions().first, isEmpty);
      expect(
        (await ledger.schedule(rent.id))!.next,
        CivilDate(2026, 12, 25),
      );
      await expectLater(ledger.skipSchedule('none'), throwsLedger());
    });

    test('of the payments that post themselves takes every time that came, '
        'and leaves the others to the person', () async {
      final tv = await ledger.addSchedule(
        kind: TransactionKind.expense,
        name: 'Netflix',
        accountId: card.id,
        amount: rub(79900),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 10, 1),
        onDay: ScheduleOnDay.post,
      );
      final later = await ledger.addSchedule(
        kind: TransactionKind.expense,
        name: 'Gym',
        accountId: card.id,
        amount: rub(350000),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 12, 3),
        onDay: ScheduleOnDay.post,
      );
      final rent = await addRent(next: CivilDate(2026, 10, 25));

      final posted = await ledger.postDueSchedules(CivilDate(2026, 11, 18));

      expect(posted, hasLength(2));
      final transactions = await ledger.watchTransactions().first;
      expect(transactions.map((it) => (it.note, it.occurredOn)), [
        ('Netflix', CivilDate(2026, 11, 1)),
        ('Netflix', CivilDate(2026, 10, 1)),
      ]);
      expect((await ledger.schedule(tv.id))!.next, CivilDate(2026, 12, 1));
      expect(
        (await ledger.schedule(tv.id))!.last,
        ScheduleLast(
          done: ScheduleDone.posted,
          from: CivilDate(2026, 10, 1),
          on: CivilDate(2026, 11, 1),
          at: now,
          transactionId: posted.last,
        ),
      );
      expect(await ledger.schedule(later.id), later);
      expect(await ledger.schedule(rent.id), rent);
      expect(await ledger.postDueSchedules(CivilDate(2026, 11, 18)), isEmpty);
    });
  });

  group('a statement', () {
    Future<(String, String)> imported(CivilDate on) async {
      final importId = await ledger.addImport(
        fileName: 'alfa.csv',
        format: 'alfa',
        firstDay: CivilDate(2026, 10, 1),
        lastDay: CivilDate(2026, 11, 30),
      );
      final transactionId = await ledger.record(
        TransactionDraft.expense(
          accountId: card.id,
          allocations: [Allocation(categoryId: home.id, amount: rub(4500000))],
          occurredOn: on,
          note: 'Перевод по номеру телефона',
          source: TransactionSource.import,
        ),
        importId: importId,
      );
      return (importId, transactionId);
    }

    test('that brings the times of a payment moves it on with no '
        'transaction of its own', () async {
      final rent = await addRent(next: CivilDate(2026, 10, 25));
      final (importId, transactionId) = await imported(CivilDate(2026, 11, 25));

      await ledger.findSchedule(
        rent.id,
        through: CivilDate(2026, 11, 25),
        transactionId: transactionId,
        importId: importId,
      );

      final found = (await ledger.schedule(rent.id))!;
      expect(found.next, CivilDate(2026, 12, 25));
      expect(
        found.last,
        ScheduleLast(
          done: ScheduleDone.found,
          from: CivilDate(2026, 10, 25),
          on: CivilDate(2026, 11, 25),
          at: now,
          transactionId: transactionId,
          importId: importId,
        ),
      );
      expect(
        (await ledger.watchTransactions().first).map((it) => it.source),
        [TransactionSource.import],
      );
      await expectLater(
        ledger.findSchedule(
          rent.id,
          through: CivilDate(2026, 11, 25),
          transactionId: transactionId,
          importId: importId,
        ),
        throwsLedger(),
      );
    });

    test('that goes out leaves the payment waiting for those times again, '
        'and the others as they are', () async {
      final rent = await addRent();
      final (importId, transactionId) = await imported(CivilDate(2026, 11, 24));
      await ledger.findSchedule(
        rent.id,
        through: CivilDate(2026, 11, 25),
        transactionId: transactionId,
        importId: importId,
      );
      final tv = await ledger.addSchedule(
        kind: TransactionKind.expense,
        name: 'Netflix',
        accountId: card.id,
        amount: rub(79900),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 11, 1),
      );
      await ledger.postSchedule(tv.id);
      final posted = await ledger.schedule(tv.id);

      await ledger.undoImport(importId);

      expect(await ledger.schedule(rent.id), rent);
      expect(await ledger.schedule(tv.id), posted);
    });
  });

  test('an import that is undone keeps what a payment uses', () async {
    final importId = await ledger.addImport(
      fileName: 'statement.csv',
      firstDay: CivilDate(2026, 10, 1),
      lastDay: CivilDate(2026, 10, 31),
    );
    final bank = await ledger.addAccount(
      name: 'Bank',
      type: AccountType.debit,
      openingBalance: rub(0),
      importId: importId,
    );
    final spare = await ledger.addAccount(
      name: 'Spare',
      type: AccountType.debit,
      openingBalance: rub(0),
      importId: importId,
    );
    final subscriptions = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Subscriptions',
      importId: importId,
    );
    await ledger.addSchedule(
      kind: TransactionKind.expense,
      name: 'Netflix',
      accountId: bank.id,
      categoryId: subscriptions.id,
      amount: rub(79900),
      every: ScheduleEvery.month,
      next: CivilDate(2026, 12, 1),
    );
    await ledger.addSchedule(
      kind: TransactionKind.transfer,
      name: 'To bank',
      accountId: cash.id,
      toAccountId: bank.id,
      amount: rub(100000),
      every: ScheduleEvery.month,
      next: CivilDate(2026, 12, 1),
    );

    await ledger.undoImport(importId);

    final accounts = await ledger.watchAccounts().first;
    expect(accounts.map((it) => it.name), contains('Bank'));
    expect(accounts.map((it) => it.name), isNot(contains('Spare')));
    expect(await ledger.account(spare.id), isNull);
    final categories = await ledger.watchCategories(CategoryKind.expense).first;
    expect(categories.map((it) => it.id), contains(subscriptions.id));
    final bankRow = await (database.select(
      database.accounts,
    )..where((row) => row.id.equals(bank.id))).getSingle();
    expect(bankRow.importId, isNull);
  });
}
