@TestOn('vm')
library;

import 'dart:convert';

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

CivilDate nov(int day) => CivilDate(2026, 11, day);

Matcher throwsLedger() => throwsA(isA<LedgerException>());

/// The clock of the ledger: Saturday 14 November 2026.
final now = DateTime.utc(2026, 11, 14, 12);

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late Account cash;
  late Account masha;

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database, now: () => now);
    cash = await ledger.addAccount(
      name: 'Cash',
      type: AccountType.cash,
      openingBalance: rub(650000),
    );
    masha = await ledger.addAccount(
      name: 'Маша',
      type: AccountType.debt,
      openingBalance: rub(0),
      debt: DebtTerms(side: DebtSide.lent, dueOn: nov(1).addDays(30)),
    );
  });

  tearDown(() => database.close());

  Future<String> lend(int minorUnits, CivilDate day) => ledger.record(
    TransactionDraft.transfer(
      fromAccountId: cash.id,
      sent: rub(minorUnits),
      toAccountId: masha.id,
      received: rub(minorUnits),
      occurredOn: day,
      note: 'на билеты',
    ),
  );

  group('a debt', () {
    test('keeps its terms and never counts towards the capital', () async {
      final read = (await ledger.account(masha.id))!;
      expect(read.isDebt, isTrue);
      expect(read.includeInTotals, isFalse);
      expect(
        read.debt,
        DebtTerms(side: DebtSide.lent, dueOn: CivilDate(2026, 12, 1)),
      );
      expect((await ledger.account(cash.id))!.debt, isNull);
    });

    test('needs its terms, and no other account has them', () async {
      expect(
        () => ledger.addAccount(
          name: 'Дима',
          type: AccountType.debt,
          openingBalance: rub(0),
        ),
        throwsLedger(),
      );
      expect(
        () => ledger.addAccount(
          name: 'Card',
          type: AccountType.debit,
          openingBalance: rub(0),
          debt: const DebtTerms(side: DebtSide.borrowed),
        ),
        throwsLedger(),
      );
    });

    test('takes new terms and stays a debt', () async {
      await ledger.updateAccount(
        masha.id,
        name: 'Маша К.',
        debt: const DebtTerms(side: DebtSide.lent, reminds: true),
      );
      final read = (await ledger.account(masha.id))!;
      expect(read.name, 'Маша К.');
      expect(read.debt, const DebtTerms(side: DebtSide.lent, reminds: true));

      expect(
        () => ledger.updateAccount(masha.id, type: AccountType.cash),
        throwsLedger(),
      );
      expect(
        () => ledger.updateAccount(cash.id, type: AccountType.debt),
        throwsLedger(),
      );
      expect(
        () => ledger.updateAccount(
          cash.id,
          debt: const DebtTerms(side: DebtSide.lent),
        ),
        throwsLedger(),
      );
      expect(
        () => ledger.updateAccount(masha.id, includeInTotals: true),
        throwsLedger(),
      );
    });

    test('stays out of the lists of accounts unless asked', () async {
      await lend(500000, nov(3));

      final accounts = await ledger.watchAccounts().first;
      expect(accounts.map((account) => account.name), ['Cash']);
      final balances = await ledger.watchAccountBalances().first;
      expect(balances.map((row) => row.account.name), ['Cash']);

      final all = await ledger
          .watchAccountBalances(includeArchived: true, includeDebts: true)
          .first;
      expect(
        {for (final row in all) row.account.name: row.balance},
        {'Cash': rub(150000), 'Маша': rub(500000)},
      );
      expect(
        (await ledger.watchAccounts(includeDebts: true).first).length,
        2,
      );
    });

    test('names the transactions that move it', () async {
      final lent = await lend(500000, nov(3));
      final food = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Food',
      );
      await ledger.record(
        TransactionDraft.expense(
          accountId: cash.id,
          allocations: [Allocation(categoryId: food.id, amount: rub(124000))],
          occurredOn: nov(3),
        ),
      );
      final back = await ledger.record(
        TransactionDraft.transfer(
          fromAccountId: masha.id,
          sent: rub(200000),
          toAccountId: cash.id,
          received: rub(200000),
          occurredOn: nov(10),
        ),
      );

      final debts = await ledger
          .watchTransactions(debts: true, limit: null)
          .first;
      expect(debts.map((transaction) => transaction.id), [back, lent]);
      expect(await ledger.balance(masha.id), rub(300000));
    });
  });

  group('the day of a debt', () {
    final december = CivilDate(2026, 12, 1);
    final nine = DateTime(2026, 12, 1, 9);

    Future<void> remind({CivilDate? dueOn}) => ledger.updateAccount(
      masha.id,
      debt: DebtTerms(
        side: DebtSide.lent,
        dueOn: dueOn ?? december,
        reminds: true,
      ),
    );

    Future<String> back(int minorUnits, CivilDate day) => ledger.record(
      TransactionDraft.transfer(
        fromAccountId: masha.id,
        sent: rub(minorUnits),
        toAccountId: cash.id,
        received: rub(minorUnits),
        occurredOn: day,
      ),
    );

    Future<void> noteDecember() => ledger.noteDebtDays([
      (debtId: masha.id, due: december, at: nine),
    ]);

    Future<DebtNotice> notice() async =>
        (await ledger.watchNotices().first).single as DebtNotice;

    test('comes into the notices once, with what was owed then', () async {
      await remind();
      await lend(500000, nov(1));
      await back(200000, nov(10));

      await noteDecember();
      await noteDecember();

      expect(
        await notice(),
        isA<DebtNotice>()
            .having((it) => it.name, 'name', 'Маша')
            .having((it) => it.side, 'side', DebtSide.lent)
            .having((it) => it.due, 'due', december)
            .having((it) => it.at, 'at', nine.toUtc())
            .having((it) => it.owed, 'owed', rub(300000))
            .having((it) => it.left, 'left', rub(300000))
            .having((it) => it.since, 'since', nov(1))
            .having((it) => it.note, 'note', 'на билеты')
            .having((it) => it.settledOn, 'settled', isNull)
            .having((it) => it.gone, 'gone', isFalse)
            .having((it) => it.isNew, 'new', isTrue),
      );
    });

    test('needs the reminder of that day and something owed', () async {
      await lend(500000, nov(1));
      await noteDecember();
      await remind(dueOn: CivilDate(2026, 12, 5));
      await noteDecember();
      expect(await ledger.watchNotices().first, isEmpty);

      await remind();
      await back(500000, nov(10));
      await noteDecember();
      expect(await ledger.watchNotices().first, isEmpty);
    });

    test('says the day its round came back to nought, and keeps it when the '
        'person lends again', () async {
      await remind();
      await lend(500000, nov(1));
      await noteDecember();

      await back(200000, CivilDate(2026, 12, 2));
      expect((await notice()).left, rub(300000));
      await back(300000, CivilDate(2026, 12, 3));
      expect((await notice()).settledOn, CivilDate(2026, 12, 3));
      expect((await notice()).left, isNull);

      await lend(100000, CivilDate(2026, 12, 10));
      final again = await notice();
      expect(again.settledOn, CivilDate(2026, 12, 3));
      expect(again.since, nov(1));
    });

    test('counts a return dated before the day', () async {
      await remind();
      await lend(500000, nov(1));
      await noteDecember();

      await back(500000, CivilDate(2026, 11, 30));

      expect((await notice()).settledOn, CivilDate(2026, 11, 30));
    });

    test('is gone with the transfer that started its round, and comes back '
        'open when a return goes', () async {
      await remind();
      final lent = await lend(500000, nov(1));
      final returned = await back(500000, CivilDate(2026, 12, 2));
      await ledger.delete(returned);
      await noteDecember();
      await ledger.delete(lent);
      expect((await notice()).gone, isTrue);

      await lend(500000, nov(1));
      final returnedAgain = await back(500000, CivilDate(2026, 12, 2));
      expect((await notice()).settledOn, CivilDate(2026, 12, 2));
      await ledger.delete(returnedAgain);
      final open = await notice();
      expect(open.settledOn, isNull);
      expect(open.left, rub(500000));
    });

    test('is read once the person settles the debt', () async {
      await remind();
      await lend(500000, nov(1));
      await noteDecember();

      await ledger.readDebtNotices(masha.id);

      expect((await notice()).isNew, isFalse);
      expect(await ledger.watchNewNotices().first, 0);
    });
  });

  group('a person', () {
    test('owns each debt, and their other debts take a new name', () async {
      final personId = masha.personId!;
      expect((await ledger.person(personId))!.name, 'Маша');
      final borrowed = await ledger.addAccount(
        name: 'не важно',
        type: AccountType.debt,
        openingBalance: rub(0),
        debt: const DebtTerms(side: DebtSide.borrowed),
        personId: personId,
      );
      expect(borrowed.name, 'Маша');
      expect(borrowed.personId, personId);

      final person = (await ledger.person(personId))!;
      await ledger.updatePerson(
        person.copyWith(
          name: ' Маша К. ',
          about: ' соседка ',
          phone: () => ' +7 999 123-45-67 ',
        ),
      );
      expect(
        await ledger.person(personId),
        Person(
          id: personId,
          name: 'Маша К.',
          about: 'соседка',
          phone: '+7 999 123-45-67',
        ),
      );
      expect((await ledger.account(masha.id))!.name, 'Маша К.');
      expect((await ledger.account(borrowed.id))!.name, 'Маша К.');

      await ledger.updateAccount(masha.id, name: 'Мария');
      expect((await ledger.person(personId))!.name, 'Мария');
      expect((await ledger.account(borrowed.id))!.name, 'Мария');
      expect((await ledger.account(cash.id))!.personId, isNull);
    });

    test('may share a name, and needs one', () async {
      final neighbour = await ledger.addPerson(name: 'Иван', about: 'сосед');
      final colleague = await ledger.addPerson(
        name: 'Иван',
        about: 'коллега',
        phone: '  ',
      );
      expect(colleague.phone, isNull);
      expect(
        [for (final it in await ledger.watchPeople().first) it.about],
        containsAll(['сосед', 'коллега']),
      );
      expect(neighbour.id, isNot(colleague.id));
      expect(() => ledger.addPerson(name: '  '), throwsLedger());
      expect(
        () => ledger.addAccount(
          name: 'Card',
          type: AccountType.debit,
          openingBalance: rub(0),
          personId: neighbour.id,
        ),
        throwsLedger(),
      );
      expect(
        () => ledger.addAccount(
          name: 'Иван',
          type: AccountType.debt,
          openingBalance: rub(0),
          debt: const DebtTerms(side: DebtSide.lent),
          personId: 'nobody',
        ),
        throwsLedger(),
      );
    });
  });

  group('a copy', () {
    test('keeps the terms of a debt', () async {
      await lend(500000, nov(3));
      await ledger.updateAccount(
        masha.id,
        debt: DebtTerms(
          side: DebtSide.lent,
          dueOn: CivilDate(2026, 12, 1),
          reminds: true,
        ),
      );
      final copy = LedgerCopy.parse((await ledger.copy()).encode());

      final other = BirkaDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      final restored = LedgerRepository(other, now: () => now);
      await restored.restore(copy);

      final read = (await restored.account(masha.id))!;
      expect(read.debt, masha.debt!.copyWith(reminds: true));
      expect(read.includeInTotals, isFalse);
      expect(await restored.balance(masha.id), rub(500000));
    });

    test('keeps the people of the debts', () async {
      final person = (await ledger.person(masha.personId!))!;
      await ledger.updatePerson(
        person.copyWith(about: 'соседка', phone: () => '+7 999 123-45-67'),
      );
      final copy = LedgerCopy.parse((await ledger.copy()).encode());

      final other = BirkaDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      final restored = LedgerRepository(other, now: () => now);
      await restored.restore(copy);

      expect(
        await restored.person(person.id),
        person.copyWith(about: 'соседка', phone: () => '+7 999 123-45-67'),
      );
      expect((await restored.account(masha.id))!.personId, person.id);
    });

    test('of an old version gives the debts of one name one person', () {
      final copy = LedgerCopy.parse(ledgerCopyOf(version: 9));
      expect(copy.personRows.single.id, 'debt');
      expect(copy.personRows.single.name, 'Ира');
      expect(copy.accountRows.single.personId, 'debt');
    });

    test('of an old version makes a debt of an account of that type', () {
      final copy = LedgerCopy.parse(ledgerCopyOf(version: 8));
      final row = copy.accountRows.single;
      expect(row.type, 'debt');
      expect(row.debtSide, 'lent');
      expect(row.includeInTotals, isFalse);
      expect(row.debtReminds, isFalse);
    });

    test('with a debt side on another account is damaged', () {
      expect(
        () => LedgerCopy.parse(
          ledgerCopyOf(version: 9, type: 'cash', side: 'lent'),
        ),
        throwsA(isA<LedgerCopyException>()),
      );
    });
  });
}

/// A copy of version [version] with one account of [type], with the debt
/// side [side] when given.
String ledgerCopyOf({
  required int version,
  String type = 'debt',
  String? side,
}) {
  final account = <String, Object?>{
    'id': 'debt',
    'createdAt': '2026-10-01T09:00:00.000Z',
    'updatedAt': '2026-10-02T09:00:00.000Z',
    'name': 'Ира',
    'type': type,
    'currency': 'RUB',
    'decimalDigits': 2,
    'openingBalanceMinor': 0,
    'lastDigits': null,
    'art': 'rose',
    'includeInTotals': true,
    'archived': false,
    'sortOrder': 0,
    'importId': null,
  };
  if (side != null) account['debtSide'] = side;
  return jsonEncode({
    'format': 'birka-copy',
    'version': version,
    'madeAt': '2026-11-14T12:00:00.000Z',
    'accounts': [account],
    'categories': <Object?>[],
    'transactions': <Object?>[],
  });
}
