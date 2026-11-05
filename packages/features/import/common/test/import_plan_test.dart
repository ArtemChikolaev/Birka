@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:import_common/import_common.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
Money usd(int minorUnits) => Money(minorUnits, Currency.usd);

Statement _statement(List<List<String>> rows) {
  final table = tableOf(rows);
  return readStatement(table, detectLayout(table));
}

/// A card of Alfa-Bank in October, as on the boards of the import.
Statement _card() => _statement([
  ['Дата операции', 'Описание', 'Сумма', 'Валюта', 'Категория', 'Номер карты'],
  [
    '01.10.2026 10:00',
    'TOPUP WISE EUROPE',
    '185 000,00',
    'RUR',
    'Переводы',
    '*4821',
  ],
  [
    '02.10.2026 18:40',
    'PRODUKTY BEREZKA',
    '−2 340,50',
    'RUR',
    'Супермаркеты',
    '*4821',
  ],
  [
    '03.10.2026 09:12',
    'ZERNO COFFEE',
    '−420,00',
    'RUR',
    'Рестораны и кафе',
    '*4821',
  ],
  [
    '04.10.2026 09:30',
    'ZERNO COFFEE',
    '−420,00',
    'RUR',
    'Рестораны и кафе',
    '*4821',
  ],
  ['07.10.2026', 'ZHKU MOSKVA', '−6 845,30', 'RUR', 'ЖКХ', '*4821'],
  ['09.10.2026', 'PEREVOD PO NOMERU', '−3 000,00', 'RUR', '', '*4821'],
  ['12.10.2026', 'Маркетплейс', '−2 199,00', 'RUR', 'Маркетплейсы', '*4821'],
]);

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late LedgerImportRepository repository;
  late Account card;
  late Category food;
  late Category cafe;
  late Category home;

  Future<String> spend(Money amount, CivilDate day, String note, Category to) =>
      ledger.record(
        TransactionDraft.expense(
          accountId: card.id,
          allocations: [Allocation(categoryId: to.id, amount: amount)],
          occurredOn: day,
          note: note,
        ),
      );

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    repository = LedgerImportRepository(ledger);
    card = await ledger.addAccount(
      name: 'Зарплатная карта',
      type: AccountType.debit,
      openingBalance: rub(14267981),
      lastDigits: '4821',
    );
    food = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Продукты',
    );
    cafe = await ledger.addCategory(kind: CategoryKind.expense, name: 'Кафе');
    home = await ledger.addCategory(kind: CategoryKind.expense, name: 'Дом');
    final shop = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Покупки',
    );
    // What the person recorded by hand.
    await spend(rub(42000), CivilDate(2026, 10, 3), 'Кофе с Олей', cafe);
    await spend(
      rub(684530),
      CivilDate(2026, 10, 6),
      'Коммуналка за сентябрь',
      home,
    );
    await spend(
      rub(219900),
      CivilDate(2026, 10, 12),
      'Маркетплейс: зарядка',
      shop,
    );
    // And something after the statement, which its balance does not know.
    await spend(rub(10000), CivilDate(2026, 11, 2), 'Хлеб', food);
  });

  tearDown(() => database.close());

  ImportChoices cardChoices() => ImportChoices(
    accounts: {'RUB': IntoAccount(card)},
    categories: {
      (kind: CategoryKind.expense, name: 'Супермаркеты'): IntoCategory(food.id),
      (kind: CategoryKind.expense, name: 'Рестораны и кафе'): IntoCategory(
        cafe.id,
      ),
      (kind: CategoryKind.expense, name: 'ЖКХ'): IntoCategory(home.id),
    },
  );

  group('the plan of a card', () {
    test('finds what the person recorded by hand', () async {
      final plan = await prepareImport(repository, _card(), cardChoices());
      expect(plan.problems, isEmpty);
      expect(plan.operations, hasLength(7));
      final copies = {
        for (final it in plan.copies) it.row.description: it.duplicate!,
      };
      expect(copies.keys, ['ZERNO COFFEE', 'ZHKU MOSKVA', 'Маркетплейс']);
      expect(copies['ZERNO COFFEE']!.transaction.note, 'Кофе с Олей');
      expect(copies['ZERNO COFFEE']!.reasons, {
        DuplicateReason.sameAmount,
        DuplicateReason.sameDay,
        DuplicateReason.sameAccount,
      });
      expect(
        copies['ZHKU MOSKVA']!.reasons,
        contains(DuplicateReason.dayBefore),
      );
      expect(
        copies['Маркетплейс']!.reasons,
        contains(DuplicateReason.similarName),
      );
      // The second coffee of the statement is a purchase of its own.
      expect(
        plan.added.where((it) => it.row.description == 'ZERNO COFFEE'),
        hasLength(1),
      );
      expect(plan.added, hasLength(4));
      expect(plan.unsorted, 2);
    });

    test(
      'gives the balance after it on the last day of the statement',
      () async {
        final plan = await prepareImport(repository, _card(), cardChoices());
        // 142 679,81 before, minus what was recorded by hand in October, plus
        // the top-up, the groceries, one coffee and the transfer of the file.
        const before = 14267981 - 42000 - 684530 - 219900;
        const added = 18500000 - 234050 - 42000 - 300000;
        expect(plan.balances['RUB'], rub(before + added));
      },
    );

    test('keeps a copy that the person keeps', () async {
      final statement = _card();
      final plan = await prepareImport(repository, statement, cardChoices());
      final coffee = plan.copies.first.row.line;
      final kept = await prepareImport(
        repository,
        statement,
        cardChoices().keeping({coffee}),
      );
      expect(kept.added, hasLength(5));
      expect(kept.balances['RUB'], plan.balances['RUB']! - rub(42000));
    });

    test('names the rows that do not fit their account', () async {
      final plan = await prepareImport(
        repository,
        _statement([
          ['Date', 'Description', 'Amount', 'Currency'],
          ['03.10.2026', 'Coffee', '-4.20', 'RUB'],
          ['04.10.2026', 'Burger', '-10.00', 'USD'],
          ['05.10.2026', 'Dust', '-0.001', 'RUB'],
        ]),
        ImportChoices(
          accounts: {'RUB': IntoAccount(card), 'USD': const LeaveOut()},
        ),
      );
      expect(plan.operations, hasLength(1));
      expect(plan.left, 1);
      expect(plan.problems.map((it) => (it.line, it.fault)), [
        (4, PlanFault.tooPrecise),
      ]);
      final other = await prepareImport(
        repository,
        _statement([
          ['Date', 'Description', 'Amount', 'Currency'],
          ['04.10.2026', 'Burger', '-10.00', 'USD'],
        ]),
        ImportChoices(accounts: {'USD': IntoAccount(card)}),
      );
      expect(other.problems.single.fault, PlanFault.otherCurrency);
      expect(other.problems.single.text, 'USD');
    });
  });

  group('an import', () {
    test('goes in at once, with its progress, and out again', () async {
      final before = await ledger.balance(card.id);
      final plan = await prepareImport(repository, _card(), cardChoices());
      final progress = <int>[];
      final id = await repository.write(
        plan,
        fileName: 'alfa-2026-10.xlsx',
        format: 'alfa',
        progress: (done, total) => progress.add(total - done),
      );
      expect(progress, [3, 2, 1, 0]);
      final [listed] = await repository.watchImports().first;
      expect(listed.id, id);
      expect(listed.transactions, 4);
      expect(listed.accountIds, {card.id});
      final imported = [
        for (final it in await ledger.watchTransactions(limit: null).first)
          if (it.importId == id) it,
      ];
      expect(imported, hasLength(4));
      final groceries = imported.singleWhere(
        (it) => it.note == 'PRODUKTY BEREZKA',
      );
      expect(groceries.allocations.single.categoryId, food.id);
      expect(groceries.occurredAt?.toLocal(), DateTime(2026, 10, 2, 18, 40));
      expect(groceries.source, TransactionSource.import);
      final topUp = imported.singleWhere(
        (it) => it.kind == TransactionKind.income,
      );
      expect(topUp.allocations.single.categoryId, isNull);
      expect(
        await ledger.balance(card.id),
        before + rub(18500000 - 234050 - 42000 - 300000),
      );
      await repository.undo(id);
      expect(await ledger.balance(card.id), before);
      expect(await repository.watchImports().first, isEmpty);
    });

    test(
      'of the same file again finds every operation in the ledger',
      () async {
        final statement = _card();
        final first = await prepareImport(repository, statement, cardChoices());
        await repository.write(first, fileName: 'alfa.xlsx');
        final again = await prepareImport(repository, statement, cardChoices());
        expect(again.added, isEmpty);
        expect(
          again.copies.where(
            (it) => it.duplicate!.reasons.contains(DuplicateReason.imported),
          ),
          hasLength(4),
        );
        expect(
          () => repository.write(again, fileName: 'alfa.xlsx'),
          throwsStateError,
        );
      },
    );

    test(
      'adds the accounts and categories of Zenmoney and takes them back',
      () async {
        final statement = _statement([
          [
            'date',
            'categoryName',
            'payee',
            'comment',
            'outcomeAccountName',
            'outcome',
            'outcomeCurrencyShortTitle',
            'incomeAccountName',
            'income',
            'incomeCurrencyShortTitle',
          ],
          [
            '2026-10-01',
            'Путешествия / Билеты',
            'Аэрофлот',
            '',
            'Карта',
            '25000',
            'RUB',
            'Карта',
            '0',
            'RUB',
          ],
          [
            '2026-10-02',
            'Зарплата',
            'ООО Ромашка',
            '',
            'Карта',
            '0',
            'RUB',
            'Карта',
            '150000',
            'RUB',
          ],
          [
            '2026-10-03',
            '',
            '',
            'обмен',
            'Карта',
            '80090',
            'RUB',
            'Наличные',
            '1000',
            'USD',
          ],
          [
            '2026-10-04',
            'Путешествия / Жильё',
            'Hotel',
            '',
            'Наличные',
            '120',
            'USD',
            'Наличные',
            '0',
            'USD',
          ],
        ]);
        final choices = ImportChoices(
          accounts: {
            'Карта': NewAccount(
              name: 'Карта',
              type: AccountType.debit,
              openingBalance: rub(0),
            ),
            'Наличные': NewAccount(
              name: 'Наличные',
              type: AccountType.cash,
              openingBalance: usd(5000),
            ),
          },
          categories: const {
            (kind: CategoryKind.expense, name: 'Путешествия / Билеты'):
                NewCategory('Билеты', parentName: 'Путешествия'),
            (kind: CategoryKind.expense, name: 'Путешествия / Жильё'):
                NewCategory('Жильё', parentName: 'Путешествия'),
            (kind: CategoryKind.income, name: 'Зарплата'): NewCategory(
              'Зарплата',
            ),
          },
        );
        final plan = await prepareImport(repository, statement, choices);
        expect(plan.operations.map((it) => it.kind), [
          TransactionKind.expense,
          TransactionKind.income,
          TransactionKind.transfer,
          TransactionKind.expense,
        ]);
        expect(plan.balances, {
          'Карта': rub(15000000 - 2500000 - 8009000),
          'Наличные': usd(5000 + 100000 - 12000),
        });
        final id = await repository.write(
          plan,
          fileName: 'zen.csv',
          format: 'zenmoney',
        );
        final accounts = await ledger.watchAccounts().first;
        expect(accounts.map((it) => it.name), [
          'Зарплатная карта',
          'Карта',
          'Наличные',
        ]);
        final expenses = await ledger
            .watchCategories(CategoryKind.expense)
            .first;
        final travel = expenses.singleWhere((it) => it.name == 'Путешествия');
        expect(
          expenses.where((it) => it.parentId == travel.id).map((it) => it.name),
          unorderedEquals(['Билеты', 'Жильё']),
        );
        final exchange = (await ledger.watchTransactions(limit: null).first)
            .singleWhere((it) => it.kind == TransactionKind.transfer);
        expect(exchange.entries.map((it) => it.amount), [
          rub(-8009000),
          usd(100000),
        ]);
        expect(exchange.note, 'обмен');
        await repository.undo(id);
        expect(
          (await ledger.watchAccounts().first).map((it) => it.name),
          ['Зарплатная карта'],
        );
        expect(
          (await ledger.watchCategories(CategoryKind.expense).first).map(
            (it) => it.name,
          ),
          unorderedEquals(['Продукты', 'Кафе', 'Дом', 'Покупки']),
        );
      },
    );

    test(
      'puts a fee apart and leaves a transfer within one account out',
      () async {
        final statement = _statement([
          ['Account', 'Date', 'Amount', 'Fee', 'Description'],
          ['Card', '03.10.2026 10:00:00', '-10.00', '0.50', 'Cafe'],
          ['Card', '04.10.2026 10:00:00', '-500.00', '', 'To savings'],
          ['Savings', '04.10.2026 10:00:30', '500.00', '', 'To savings'],
        ]);
        final fees = await ledger.addCategory(
          kind: CategoryKind.expense,
          name: 'Комиссии',
        );
        final plan = await prepareImport(
          repository,
          statement,
          ImportChoices(
            accounts: {'Card': IntoAccount(card), 'Savings': IntoAccount(card)},
            fees: IntoCategory(fees.id),
          ),
        );
        expect(plan.left, 1);
        expect(plan.operations.single.fee, rub(50));
        final id = await repository.write(plan, fileName: 'bank.csv');
        final imported = [
          for (final it in await ledger.watchTransactions(limit: null).first)
            if (it.importId == id) it,
        ];
        expect(
          imported.map(
            (it) =>
                (it.entries.single.amount, it.allocations.single.categoryId),
          ),
          unorderedEquals([(rub(-1000), null), (rub(-50), fees.id)]),
        );
      },
    );
  });

  test('a balance on a day leaves out what came after it', () async {
    expect(
      await repository.balanceOn(card.id, CivilDate(2026, 10, 31)),
      rub(14267981 - 42000 - 684530 - 219900),
    );
    expect(
      await repository.balanceOn(card.id, CivilDate(2026, 11, 2)),
      rub(14267981 - 42000 - 684530 - 219900 - 10000),
    );
  });

  group('the past choices of the person', () {
    /// A month of the card with operations that the bank gives no category
    /// Birka knows.
    Statement month(int number) => _statement([
      [
        'Дата операции',
        'Описание',
        'Сумма',
        'Валюта',
        'Категория',
        'Номер карты',
      ],
      ['0$number.11.2026', 'ZERNO COFFEE', '−420,00', 'RUR', 'Разное', '*4821'],
      [
        '1$number.11.2026',
        'BARBERSHOP 77',
        '−2 000,00',
        'RUR',
        'Разное',
        '*4821',
      ],
      ['2$number.11.2026', 'Подписка', '−399,00', 'RUR', 'Разное', '*4821'],
    ]);

    test('give the next file the category of the same name', () async {
      // The person sorted the coffee of October in the inbox.
      await spend(rub(42000), CivilDate(2026, 10, 9), 'ZERNO COFFEE', cafe);

      final plan = await prepareImport(
        repository,
        month(1),
        ImportChoices(accounts: {'RUB': IntoAccount(card)}),
      );

      final coffee = plan.operations.first;
      expect(coffee.learned?.categoryId, cafe.id);
      expect(coffee.learned?.reason, HintReason.sameName);
      expect(plan.operations[1].learned, isNull);
      expect(plan.unsorted, 2);

      final id = await repository.write(plan, fileName: 'card.csv');
      final written = [
        for (final it in await ledger.watchTransactions(limit: null).first)
          if (it.importId == id && it.note == 'ZERNO COFFEE') it,
      ];
      expect(written.single.allocations.single.categoryId, cafe.id);
    });

    test('never over a category that the person chose for the bank', () async {
      await spend(rub(42000), CivilDate(2026, 10, 9), 'ZERNO COFFEE', cafe);

      final plan = await prepareImport(
        repository,
        month(1),
        ImportChoices(
          accounts: {'RUB': IntoAccount(card)},
          categories: {
            (kind: CategoryKind.expense, name: 'Разное'): IntoCategory(food.id),
          },
        ),
      );

      expect(plan.operations.first.learned, isNull);
      expect(plan.unsorted, 0);
    });

    test('of a similar name only wait in the inbox', () async {
      await spend(rub(200000), CivilDate(2026, 10, 14), 'Барбершоп', home);

      final plan = await prepareImport(
        repository,
        month(1),
        ImportChoices(accounts: {'RUB': IntoAccount(card)}),
      );

      expect(plan.operations[1].learned, isNull);
    });

    test('of an amount month after month need the account', () async {
      for (final day in [CivilDate(2026, 9, 21), CivilDate(2026, 10, 21)]) {
        await spend(rub(39900), day, 'APPLE.COM/BILL', home);
      }

      final into = await prepareImport(
        repository,
        month(1),
        ImportChoices(accounts: {'RUB': IntoAccount(card)}),
      );
      final fresh = await prepareImport(
        repository,
        month(1),
        ImportChoices(
          accounts: {
            'RUB': NewAccount(
              name: 'Новая карта',
              type: AccountType.debit,
              openingBalance: rub(0),
            ),
          },
        ),
      );

      expect(into.operations.last.learned?.reason, HintReason.everyMonth);
      expect(into.operations.last.learned?.categoryId, home.id);
      expect(fresh.operations.last.learned, isNull);
    });

    test('of a category in the archive teach nothing', () async {
      await spend(rub(42000), CivilDate(2026, 10, 9), 'ZERNO COFFEE', cafe);
      await ledger.updateCategory(cafe.id, archived: true);

      final plan = await prepareImport(
        repository,
        month(1),
        ImportChoices(accounts: {'RUB': IntoAccount(card)}),
      );

      expect(plan.operations.first.learned, isNull);
    });
  });
}
