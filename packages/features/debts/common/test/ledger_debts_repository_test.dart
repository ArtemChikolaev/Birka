@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:debts_common/debts_common.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

Money rub(int units) => Money(units * 100, Currency.rub);

CivilDate nov(int day) => CivilDate(2026, 11, day);

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late LedgerDebtsRepository repository;
  late Account cash;
  late Account card;

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    final now = DateTime.utc(2026, 11, 14, 12);
    ledger = LedgerRepository(database, now: () => now);
    repository = LedgerDebtsRepository(
      ledger,
      RatesRepository(database),
      BaseCurrency(null),
      now: () => now,
    );
    cash = await ledger.addAccount(
      name: 'Наличные',
      type: AccountType.cash,
      openingBalance: rub(6500),
    );
    card = await ledger.addAccount(
      name: 'Зарплатная карта',
      type: AccountType.debit,
      openingBalance: rub(45200),
    );
  });

  tearDown(() => database.close());

  test('a new debt is an account of the person outside the capital, and the '
      'money moves to it', () async {
    final id = await repository.open(
      name: ' Маша ',
      side: DebtSide.lent,
      accountId: cash.id,
      amount: rub(5000),
      day: nov(3),
      note: 'на билеты',
      terms: DebtTerms(side: DebtSide.lent, dueOn: CivilDate(2026, 12, 1)),
    );

    final masha = (await ledger.account(id))!;
    expect(masha.name, 'Маша');
    expect(masha.isDebt, isTrue);
    expect(masha.includeInTotals, isFalse);
    expect(masha.art, AccountArt.emerald);
    expect(masha.debt?.dueOn, CivilDate(2026, 12, 1));
    expect(await ledger.balance(cash.id), rub(1500));
    expect(await ledger.balance(id), rub(5000));
    expect(
      (await repository.watchAccounts().first).map((row) => row.account.name),
      ['Наличные', 'Зарплатная карта'],
    );

    final debts = await repository.watchDebts().first;
    expect(debts.single.left, rub(5000));
    expect(debts.single.steps.single.account?.name, 'Наличные');
    expect(debts.single.steps.single.note, 'на билеты');
  });

  test('more money on a person goes to the debt of that name and side, and '
      'a return settles it', () async {
    final id = await repository.open(
      name: 'Маша',
      side: DebtSide.lent,
      accountId: cash.id,
      amount: rub(5000),
      day: nov(3),
    );
    final again = await repository.open(
      name: 'маша',
      side: DebtSide.lent,
      accountId: card.id,
      amount: rub(1000),
      day: nov(5),
      terms: const DebtTerms(side: DebtSide.lent),
    );
    expect(again, id);

    await repository.settle(
      id,
      accountId: card.id,
      amount: rub(6000),
      day: nov(10),
    );
    final masha = (await repository.watchDebts().first).single;
    expect(masha.closed, isTrue);
    expect(masha.closedOn, nov(10));
    expect(masha.total, rub(6000));
    expect(await ledger.balance(card.id), rub(50200));
  });

  test('a debt of the person goes the other way, and takes its own '
      'account', () async {
    final lent = await repository.open(
      name: 'Саша',
      side: DebtSide.lent,
      accountId: cash.id,
      amount: rub(500),
      day: nov(1),
    );
    final borrowed = await repository.open(
      name: 'Саша',
      side: DebtSide.borrowed,
      accountId: card.id,
      amount: rub(4000),
      day: nov(8),
      note: 'до зарплаты',
    );
    expect(borrowed, isNot(lent));
    expect(await ledger.balance(borrowed), -rub(4000));
    expect((await ledger.account(borrowed))!.art, AccountArt.sapphire);

    await repository.settle(
      borrowed,
      accountId: card.id,
      amount: rub(1000),
      day: nov(14),
    );
    final debts = {
      for (final debt in await repository.watchDebts().first) debt.id: debt,
    };
    expect(debts[borrowed]!.left, rub(3000));
    expect(debts[borrowed]!.steps.first.move, DebtMove.repaid);
    expect(debts[lent]!.left, rub(500));
  });

  test('the terms change with the name', () async {
    final id = await repository.open(
      name: 'Дима',
      side: DebtSide.lent,
      accountId: card.id,
      amount: rub(9768),
      day: nov(1),
    );
    await repository.update(
      id,
      name: ' Дима К. ',
      terms: DebtTerms(side: DebtSide.lent, dueOn: nov(14), reminds: true),
    );

    final dima = (await repository.watchDebts().first).single;
    expect(dima.name, 'Дима К.');
    expect(dima.dueOn, nov(14));
    expect(dima.reminds, isTrue);
  });
}
