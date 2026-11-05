@TestOn('vm')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:database/database.dart';
import 'package:device_settings/device_settings.dart';
import 'package:drift/native.dart';
import 'package:import_common/import_common.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

/// The window of files, with the file that the person chooses in it.
final class _Files implements StatementFiles {
  ChosenStatement? file;

  @override
  Future<ChosenStatement?> choose() async => file;
}

/// A CSV of a card of Alfa-Bank in October, which ends in [card].
Uint8List _october({String card = '4821'}) => utf8.encode(
  [
    'Дата операции;Описание;Сумма;Валюта;Категория;Номер карты',
    '01.10.2026 10:00;TOPUP WISE;185 000,00;RUR;Переводы;*$card',
    '02.10.2026 18:40;PRODUKTY BEREZKA;−2 340,50;RUR;Продукты;*$card',
    '03.10.2026 09:12;ZERNO COFFEE;−420,00;RUR;Рестораны и кафе;*$card',
    '07.10.2026;ZHKU MOSKVA;−6 845,30;RUR;ЖКХ;*$card',
  ].join('\n'),
);

/// The settings in memory.
final class _Store implements SettingsStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// A CSV of a bank that no format knows, with [rows] under its headers: a
/// day, a text, the amount that the guess takes for a currency, a balance.
Uint8List _own(List<String> rows) => utf8.encode(
  [
    'День;Назначение платежа;Сумма в валюте счёта;Остаток',
    ...rows,
  ].join('\n'),
);

const _fileName = 'alfa-2026-10.csv';
const BankCategory _bills = (kind: CategoryKind.expense, name: 'ЖКХ');
const BankCategory _cafe = (
  kind: CategoryKind.expense,
  name: 'Рестораны и кафе',
);

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late LedgerImportRepository repository;
  late _Files files;
  late ImportCubit cubit;
  late _Store store;
  late Account card;
  late Category food;
  late Category home;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    repository = LedgerImportRepository(ledger);
    files = _Files();
    store = _Store();
    card = await ledger.addAccount(
      name: 'Зарплатная карта',
      type: AccountType.debit,
      openingBalance: Money(0, Currency.rub),
      lastDigits: '4821',
    );
    food = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Продукты',
    );
    home = await ledger.addCategory(kind: CategoryKind.expense, name: 'Дом');
    await ledger.addCategory(kind: CategoryKind.income, name: 'Зарплата');
    cubit = ImportCubit(
      repository,
      const FileStatementReader(),
      files,
      remembered: ImportMemory(store),
      today: () => CivilDate(2026, 11, 4),
    );
    await cubit.start();
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  /// The state once [test] holds for it, which can be at once.
  Future<ImportState> until(bool Function(ImportState state) test) async =>
      test(cubit.state) ? cubit.state : cubit.stream.firstWhere(test);

  /// The state once the plan follows the latest choices.
  Future<ImportState> planned() => until((state) => state.planned);

  Future<List<Transaction>> october(String accountId) =>
      repository.transactions(
        accountId,
        from: CivilDate(2026, 10, 1),
        to: CivilDate(2026, 10, 31),
      );

  test('knows the accounts and the categories of both kinds', () {
    expect(cubit.state.step, ImportStep.file);
    expect(cubit.state.accounts.map((it) => it.id), [card.id]);
    expect(cubit.state.categories.map((it) => it.name), [
      'Продукты',
      'Дом',
      'Зарплата',
    ]);
    expect(cubit.state.balances, {card.id: Money(0, Currency.rub)});
  });

  group('a file', () {
    test('reads, and Birka chooses what it can', () async {
      await cubit.read(_fileName, _october());

      final state = await planned();
      expect(state.step, ImportStep.format);
      expect(state.fileName, _fileName);
      expect(state.layout!.format, alfa);
      expect(state.statement!.rows, hasLength(4));
      final account = state.choices!.accounts['RUB']! as IntoAccount;
      expect(account.account.id, card.id);
      final categories = state.choices!.categories;
      expect(
        categories[(kind: CategoryKind.expense, name: 'Продукты')],
        isA<IntoCategory>().having((it) => it.categoryId, 'id', food.id),
      );
      expect(
        categories[_bills],
        isA<IntoCategory>().having((it) => it.categoryId, 'id', home.id),
      );
      expect(
        categories[(kind: CategoryKind.expense, name: 'Рестораны и кафе')],
        isA<Unsorted>(),
      );
      expect(state.plan!.added, hasLength(4));
      expect(state.plan!.unsorted, 2);
    });

    test('that does not read says why', () async {
      await cubit.read(_fileName, _october());
      await planned();

      await cubit.read('empty.csv', Uint8List(0));

      expect(cubit.state.unreadable, UnreadableReason.empty);
      expect(cubit.state.step, ImportStep.file);
      expect(cubit.state.table, isNull);
      expect(cubit.state.accounts, isNotEmpty);
    });

    test('comes from the window of the system', () async {
      await cubit.choose();
      expect(cubit.state.table, isNull);

      files.file = ChosenStatement(_fileName, _october());
      await cubit.choose();

      expect(cubit.state.fileName, _fileName);
    });

    test('of no currency is in the base currency of the device', () async {
      await cubit.close();
      cubit = ImportCubit(
        repository,
        const FileStatementReader(),
        files,
        currency: Currency.eur,
      );
      await cubit.start();

      await cubit.read(
        'own.csv',
        utf8.encode('Дата;Сумма;Описание\n01.10.2026;-100,00;Кофе'),
      );

      final state = await planned();
      expect(state.layout!.format, isNull);
      expect(state.currency, Currency.eur);
      final account = state.choices!.accounts.values.single as NewAccount;
      expect(account.openingBalance.currency, Currency.eur);
    });

    test(
      'of a card that Birka does not know goes into a new account',
      () async {
        await cubit.read(_fileName, _october(card: '7777'));

        final state = await planned();
        final account = state.choices!.accounts['RUB']! as NewAccount;
        expect(account.name, '${formatLabel(alfa)} ••7777');
        expect(account.lastDigits, '7777');
      },
    );
  });

  group('the steps', () {
    test('open no further than the file allows', () async {
      cubit.goTo(ImportStep.columns);
      expect(cubit.state.step, ImportStep.file);

      await cubit.read(_fileName, _october());
      await planned();
      cubit
        ..goTo(ImportStep.done)
        ..goTo(ImportStep.copies);

      expect(cubit.state.step, ImportStep.copies);
    });

    test('go one by one and remember how far the person went', () async {
      await cubit.read(_fileName, _october());
      await planned();
      expect(cubit.state.reachable, ImportStep.format);

      cubit
        ..next()
        ..next()
        ..back();

      expect(cubit.state.step, ImportStep.columns);
      expect(cubit.state.reachable, ImportStep.account);

      cubit
        ..next()
        ..next()
        ..next();

      expect(cubit.state.step, ImportStep.copies);
    });

    test('that the file no longer allows close', () async {
      await cubit.read(_fileName, _october());
      await planned();
      cubit
        ..next()
        ..next()
        ..back();
      final date = cubit.state.layout!.roles.indexOf(ColumnRole.date);

      cubit.setRole(date, ColumnRole.skip);

      expect(cubit.state.reachable, ImportStep.columns);
    });

    test('wait for the columns of a date and an amount', () async {
      await cubit.read(_fileName, _october());
      await planned();
      final date = cubit.state.layout!.roles.indexOf(ColumnRole.date);

      cubit.setRole(date, ColumnRole.skip);

      expect(cubit.state.readable, isFalse);
      expect(cubit.state.plan, isNull);
      expect(cubit.state.furthest, ImportStep.columns);

      cubit.setRole(date, ColumnRole.date);

      expect((await planned()).plan!.added, hasLength(4));
    });

    test('keep what the person chose when the file reads anew', () async {
      await cubit.read(_fileName, _october());
      await planned();
      cubit
        ..chooseCategory(_cafe, IntoCategory(food.id))
        ..useFormat(null);

      final state = await planned();
      expect(state.layout!.format, isNull);
      expect(state.choices!.categories[_cafe], isA<IntoCategory>());
      expect(state.choices!.accounts['RUB'], isA<IntoAccount>());
    });
  });

  group('the writing', () {
    test('waits for the plan of the latest choice', () async {
      await cubit.read(_fileName, _october());
      await planned();
      cubit.chooseCategory(_cafe, IntoCategory(food.id));

      await cubit.write();
      expect(cubit.state.importId, isNull);

      await planned();
      await cubit.write();

      expect(cubit.state.step, ImportStep.done);
      expect(cubit.state.importId, isNotNull);
      expect(cubit.state.progress, (done: 4, total: 4));
      expect(cubit.state.seen, ImportStep.done);
      expect(cubit.state.balances[card.id], Money(17539420, Currency.rub));
      final transactions = await october(card.id);
      expect(transactions, hasLength(4));
      expect(
        transactions.expand((it) => it.allocations).map((it) => it.categoryId),
        containsAll([home.id, food.id]),
      );
    });

    test('of nothing does not start', () async {
      await cubit.read(_fileName, _october());
      await planned();
      cubit.chooseAccount('RUB', const LeaveOut());

      final state = await planned();
      expect(state.plan!.added, isEmpty);

      await cubit.write();

      expect(cubit.state.importId, isNull);
      expect(await october(card.id), isEmpty);
    });

    test('leaves the result alone and the choices fixed', () async {
      await cubit.read(_fileName, _october());
      await planned();
      await cubit.write();
      final choices = cubit.state.choices;

      cubit
        ..goTo(ImportStep.file)
        ..chooseAccount('RUB', const LeaveOut())
        ..useFormat(null);

      expect(cubit.state.step, ImportStep.done);
      expect(cubit.state.choices, same(choices));
    });

    test('shows up among the past imports', () async {
      await cubit.read(_fileName, _october());
      await planned();
      await cubit.write();

      final state = await until((state) => state.history.isNotEmpty);
      expect(state.history.single.id, cubit.state.importId);
      expect(state.history.single.fileName, _fileName);
    });

    test('comes back out with its undo', () async {
      await cubit.read(_fileName, _october());
      await planned();
      await cubit.write();

      await cubit.undo();

      expect(cubit.state.undone, isTrue);
      expect(await october(card.id), isEmpty);
    });

    test('of a new card adds its account', () async {
      await cubit.read(_fileName, _october(card: '7777'));
      await planned();

      await cubit.write();

      final account = cubit.state.accounts.singleWhere(
        (it) => it.lastDigits == '7777',
      );
      expect(account.name, '${formatLabel(alfa)} ••7777');
      expect(await october(account.id), hasLength(4));
    });
  });

  group('a file again', () {
    Future<String> imported({String card = '4821'}) async {
      await cubit.read(_fileName, _october(card: card));
      await planned();
      await cubit.write();
      final id = cubit.state.importId!;
      cubit.restart();
      await cubit.read(_fileName, _october(card: card));
      return id;
    }

    test('finds what is already in, and lets one in anyway', () async {
      await imported();

      var state = await planned();
      expect(state.plan!.added, isEmpty);
      expect(state.plan!.copies, hasLength(4));

      cubit.keep(state.plan!.copies.first.row.line, keep: true);

      state = await planned();
      expect(state.plan!.added, hasLength(1));
    });

    test('plans anew when a past import comes back out', () async {
      final first = await imported();
      await planned();

      await cubit.undoPast(first);

      final state = await planned();
      expect(state.plan!.added, hasLength(4));
      expect(state.plan!.copies, isEmpty);
    });

    test('of a new card chooses anew when its account goes', () async {
      final first = await imported(card: '7777');
      expect(
        (await planned()).choices!.accounts['RUB'],
        isA<IntoAccount>(),
      );

      await cubit.undoPast(first);

      final state = await planned();
      expect(state.accounts.map((it) => it.id), [card.id]);
      expect(state.choices!.accounts['RUB'], isA<NewAccount>());
    });
  });

  group('the next file of a format', () {
    test('of its own reads by the columns that the person set', () async {
      await cubit.read(
        'statement_oct_2026.csv',
        _own([
          '01.10.2026;Зарплата;96500,00;142679,81',
          '03.10.2026;Кофейня Зерно;-420,00;142259,81',
        ]),
      );
      var state = await until((state) => state.layout != null);
      expect(state.layout!.format, isNull);
      expect(state.readable, isFalse);

      cubit.setRole(2, ColumnRole.amount);
      state = await planned();
      expect(state.choices!.accounts[''], isA<NewAccount>());
      await cubit.write();
      final made = cubit.state.accounts.singleWhere((it) => it.id != card.id);
      cubit.restart();
      await cubit.read(
        'statement_nov_2026.csv',
        _own([
          '02.11.2026;Аптека №12;-1180,00;141079,81',
        ]),
      );

      state = await planned();
      expect(isOwnFormat(state.layout!.format), isTrue);
      expect(state.readable, isTrue);
      expect(
        state.choices!.accounts[''],
        isA<IntoAccount>().having((it) => it.account.id, 'account', made.id),
      );
      expect(state.plan!.added, hasLength(1));
    });

    test('puts a category of the bank where the person put it', () async {
      await cubit.read(_fileName, _october());
      await planned();
      cubit.chooseCategory(_cafe, IntoCategory(home.id));
      await planned();
      await cubit.write();
      cubit.restart();

      await cubit.read(_fileName, _october());

      final state = await planned();
      expect(
        state.choices!.categories[_cafe],
        isA<IntoCategory>().having((it) => it.categoryId, 'id', home.id),
      );
    });

    test('keeps out an account that the person left out', () async {
      await ImportMemory(
        store,
      ).remember(alfa, const RememberedChoices(accounts: {'RUB·4821': null}));

      await cubit.read(_fileName, _october());

      final state = await planned();
      expect(state.choices!.accounts['RUB'], isA<LeaveOut>());
    });

    test('of another card of the bank goes its own way', () async {
      await cubit.read(_fileName, _october(card: '7777'));
      await planned();
      await cubit.write();
      cubit.restart();

      await cubit.read(_fileName, _october());

      final state = await planned();
      expect(
        state.choices!.accounts['RUB'],
        isA<IntoAccount>().having((it) => it.account.id, 'account', card.id),
      );
    });

    test('chooses anew what is no longer there', () async {
      await ImportMemory(store).remember(
        alfa,
        const RememberedChoices(
          accounts: {'RUB·4821': 'gone'},
          categories: {_cafe: 'gone'},
        ),
      );

      await cubit.read(_fileName, _october());

      final state = await planned();
      expect(
        state.choices!.accounts['RUB'],
        isA<IntoAccount>().having((it) => it.account.id, 'account', card.id),
      );
      expect(state.choices!.categories[_cafe], isA<Unsorted>());
    });
  });
}
