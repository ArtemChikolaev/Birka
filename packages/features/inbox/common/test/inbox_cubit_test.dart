@TestOn('vm')
library;

import 'dart:io';

import 'package:database/database.dart';
import 'package:decimal/decimal.dart';
import 'package:device_settings/device_settings.dart';
import 'package:drift/native.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

/// The settings in memory.
final class _Store implements SettingsStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// The settings that cannot keep anything.
final class _FullStore implements SettingsStore {
  @override
  String? read(String key) => null;

  @override
  Future<void> write(String key, String value) async =>
      throw const FileSystemException('full');
}

Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late _Store store;
  late InboxCubit cubit;
  late Account card;
  late Account wise;
  late Category cafe;
  late Category shop;
  late Category side;
  late String october;
  late String sokolov;
  late String ivan;
  late String market;
  late String bonus;

  Future<String> spend(
    Account account,
    Money amount,
    CivilDate day,
    String note, {
    Category? category,
    String? importId,
  }) => ledger.record(
    TransactionDraft.expense(
      accountId: account.id,
      allocations: [Allocation(categoryId: category?.id, amount: amount)],
      occurredOn: day,
      note: note,
      source: importId == null
          ? TransactionSource.manual
          : TransactionSource.import,
    ),
    importId: importId,
  );

  Future<String> receive(
    Account account,
    Money amount,
    CivilDate day,
    String note, {
    String? importId,
  }) => ledger.record(
    TransactionDraft.income(
      accountId: account.id,
      allocations: [Allocation(categoryId: null, amount: amount)],
      occurredOn: day,
      note: note,
      source: TransactionSource.import,
    ),
    importId: importId,
  );

  /// The state once [test] holds for it, which can be at once.
  Future<InboxState> until(bool Function(InboxState state) test) async =>
      test(cubit.state) ? cubit.state : cubit.stream.firstWhere(test);

  Future<InboxState> ready() => until((state) => !state.loading);

  Future<Transaction> transaction(String id) async =>
      (await ledger.watchTransaction(id).first)!;

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    await RatesRepository(database).keep(
      DayRates(CivilDate(2026, 9, 30), {'USD': Decimal.parse('81.20')}),
    );
    card = await ledger.addAccount(
      name: 'Зарплатная карта',
      type: AccountType.debit,
      openingBalance: _rub(0),
      lastDigits: '4821',
    );
    wise = await ledger.addAccount(
      name: 'Wise USD',
      type: AccountType.debit,
      openingBalance: Money(0, Currency.usd),
    );
    cafe = await ledger.addCategory(kind: CategoryKind.expense, name: 'Кафе');
    shop = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Покупки',
    );
    side = await ledger.addCategory(
      kind: CategoryKind.income,
      name: 'Подработка',
    );
    // What the person chose in September.
    for (final day in [3, 12, 25]) {
      await spend(
        card,
        _rub(1450),
        CivilDate(2026, 9, day),
        'ИП Соколов А. В.',
        category: cafe,
      );
    }
    // The money sent from abroad, recorded by hand.
    await spend(
      wise,
      Money(231000, Currency.usd),
      CivilDate(2026, 9, 30),
      'Card top-up',
    );
    october = await ledger.addImport(
      fileName: 'alfa-2026-10.xlsx',
      format: 'alfa',
      firstDay: CivilDate(2026, 10, 1),
      lastDay: CivilDate(2026, 10, 21),
    );
    await receive(
      card,
      _rub(185000),
      CivilDate(2026, 10, 1),
      'Пополнение с Wise',
      importId: october,
    );
    sokolov = await spend(
      card,
      _rub(1450),
      CivilDate(2026, 10, 4),
      'ИП Соколов А. В.',
      importId: october,
    );
    ivan = await spend(
      card,
      _rub(3000),
      CivilDate(2026, 10, 9),
      'Перевод Ивану К.',
      importId: october,
    );
    market = await spend(
      card,
      _rub(1312),
      CivilDate(2026, 10, 21),
      'Пункт выдачи заказов',
      importId: october,
    );
    bonus = await receive(
      card,
      _rub(700),
      CivilDate(2026, 10, 20),
      'Кешбэк',
      importId: october,
    );
    store = _Store();
    cubit = InboxCubit(
      LedgerInboxRepository(ledger, RatesRepository(database)),
      store,
    );
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  test('lists what waits, the earliest first, with its hints', () async {
    final state = await ready();

    expect(
      [for (final item in state.items) item.id],
      [
        sokolov,
        ivan,
        bonus,
        market,
      ],
    );
    final hint = state.items.first.hint!;
    expect(hint.categoryId, cafe.id);
    expect(hint.reason, HintReason.sameName);
    expect(hint.count, 3);
    expect(state.items[1].hint, isNull);
    final pair = state.pairs.single;
    expect(pair.out.note, 'Card top-up');
    expect(pair.into.note, 'Пополнение с Wise');
    expect(state.count, 5);
    expect(state.latestImport?.id, october);
  });

  test('a yes gives the category of the hint and keeps the import', () async {
    await ready();

    await cubit.accept(sokolov);

    final state = await until(
      (state) => state.items.every((item) => item.id != sokolov),
    );
    expect(state.busy, isEmpty);
    final categorized = await transaction(sokolov);
    expect(categorized.allocations.single.categoryId, cafe.id);
    expect(categorized.importId, october);
  });

  test('another category goes to one operation', () async {
    await ready();

    await cubit.choose(ivan, shop.id);

    await until((state) => state.items.every((item) => item.id != ivan));
    expect((await transaction(ivan)).allocations.single.categoryId, shop.id);
  });

  test('the picked get one category of its kind together', () async {
    await ready();
    cubit
      ..toggle(ivan)
      ..toggle(market)
      ..toggle(bonus);

    expect(cubit.state.picked, hasLength(3));

    await cubit.choosePicked(shop.id);

    final state = await until((state) => state.items.length == 2);
    expect([for (final item in state.items) item.id], [sokolov, bonus]);
    expect(state.selected, {bonus});

    await cubit.choosePicked(side.id);

    await until((state) => state.items.length == 1);
    expect(cubit.state.selected, isEmpty);
  });

  test('picks all on screen, or none', () async {
    final shown = [for (final item in (await ready()).shownItems) item.id];

    cubit.toggleAll(shown);
    expect(cubit.state.selected, hasLength(4));

    cubit.toggleAll(shown);
    expect(cubit.state.selected, isEmpty);

    cubit.toggleAll([ivan, market]);
    expect(cubit.state.selected, {ivan, market});

    cubit
      ..toggle(ivan)
      ..pickNone();
    expect(cubit.state.selected, isEmpty);
  });

  test('a pair becomes one transfer of the person', () async {
    final pair = (await ready()).pairs.single;

    await cubit.makeTransfer(pair);

    final state = await until((state) => state.pairs.isEmpty);
    expect(state.transfers, 1);
    expect(state.items, hasLength(4));
    final transfers = [
      for (final transaction
          in await ledger.watchTransactions(limit: null).first)
        if (transaction.kind == TransactionKind.transfer) transaction,
    ];
    final transfer = transfers.single;
    expect(transfer.importId, isNull);
    expect(transfer.occurredOn, CivilDate(2026, 9, 30));
    expect(transfer.note, 'Card top-up · Пополнение с Wise');
    expect(
      {for (final entry in transfer.entries) entry.accountId: entry.amount},
      {
        wise.id: Money(-231000, Currency.usd),
        card.id: _rub(185000),
      },
    );
    expect(await ledger.watchTransaction(pair.into.id).first, isNull);
  });

  test('a pair kept apart stays apart, its income among the rest', () async {
    final pair = (await ready()).pairs.single;

    await cubit.notTransfer(pair);

    expect(cubit.state.pairs, isEmpty);
    expect(cubit.state.items.map((it) => it.id), contains(pair.into.id));
    expect(cubit.state.items.map((it) => it.id), contains(pair.out.id));

    await cubit.close();
    cubit = InboxCubit(
      LedgerInboxRepository(ledger, RatesRepository(database)),
      store,
    );

    expect((await ready()).pairs, isEmpty);
  });

  test('a pair that the settings cannot keep stays, with a word', () async {
    await cubit.close();
    cubit = InboxCubit(
      LedgerInboxRepository(ledger, RatesRepository(database)),
      _FullStore(),
    );
    final pair = (await ready()).pairs.single;

    await cubit.notTransfer(pair);

    expect(cubit.state.failed, isTrue);
    expect(cubit.state.pairs, [pair]);
  });

  test('shows the operations or the transfers alone', () async {
    await ready();

    cubit.show(InboxFilter.transfers);
    expect(cubit.state.shownItems, isEmpty);
    expect(cubit.state.shownPairs, hasLength(1));

    cubit.show(InboxFilter.uncategorized);
    expect(cubit.state.shownItems, hasLength(4));
    expect(cubit.state.shownPairs, isEmpty);
  });
}
