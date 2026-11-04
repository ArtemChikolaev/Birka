import 'package:decimal/decimal.dart';
import 'package:import_common/import_common.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Account _account(
  String id, {
  String name = 'Карта',
  Currency currency = Currency.rub,
  String? lastDigits,
  bool archived = false,
}) => Account(
  id: id,
  name: name,
  type: AccountType.debit,
  openingBalance: Money(0, currency),
  includeInTotals: true,
  archived: archived,
  sortOrder: 0,
  lastDigits: lastDigits,
);

Category _category(
  String id,
  String name, {
  CategoryKind kind = CategoryKind.expense,
  String? parentId,
  bool archived = false,
}) => Category(
  id: id,
  kind: kind,
  name: name,
  archived: archived,
  sortOrder: 0,
  parentId: parentId,
);

SourceAccount _source(
  String key, {
  String? currency = 'RUB',
  Set<String> cards = const {},
  String? opening,
}) => SourceAccount(
  key: key,
  operations: 1,
  spent: Decimal.zero,
  received: Decimal.zero,
  currency: currency,
  cards: cards,
  opening: opening == null ? null : Decimal.parse(opening),
);

const _zenHeaders = [
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
];

List<String> _zen(
  String category,
  String from,
  String spent,
  String to,
  String received,
) => ['2026-10-01', category, '', '', from, spent, 'RUB', to, received, 'RUB'];

void main() {
  group('the currency of a file', () {
    test('is the one Birka offers, with its digits', () {
      expect(currencyNamed('USDT').decimalDigits, 6);
      expect(currencyNamed('RUB'), Currency.rub);
    });

    test('is any other of ISO 4217, or one of two digits outside it', () {
      expect(currencyNamed('JPY').decimalDigits, 0);
      expect(currencyNamed('BTC1').decimalDigits, 2);
    });
  });

  group('the account of a source', () {
    final salary = _account('salary', lastDigits: '4821');
    final cash = _account('cash', name: 'Наличные');

    test('is an open one with the digits of its card', () {
      final choice = defaultAccount(
        _source('RUB', cards: {'4821'}),
        [cash, salary],
        newName: 'Альфа-Банк ••4821',
      );

      expect(choice, isA<IntoAccount>());
      expect((choice as IntoAccount).account.id, 'salary');
    });

    test('is an open one of the same name, ё and case aside', () {
      final choice = defaultAccount(
        _source('наличные'),
        [cash, salary],
        newName: 'Наличные',
      );

      expect((choice as IntoAccount).account.id, 'cash');
    });

    test('is never of another currency or in the archive', () {
      final choice = defaultAccount(
        _source('RUB', cards: {'4821'}),
        [
          _account('usd', currency: Currency.usd, lastDigits: '4821'),
          _account('old', lastDigits: '4821', archived: true),
        ],
        newName: 'Альфа-Банк ••4821',
      );

      expect(choice, isA<NewAccount>());
    });

    test('is never one of two that fit alike', () {
      final choice = defaultAccount(
        _source('RUB', cards: {'4821'}),
        [_account('a', lastDigits: '4821'), _account('b', lastDigits: '4821')],
        newName: 'Альфа-Банк ••4821',
      );

      expect(choice, isA<NewAccount>());
    });

    test('is else a new one with the balance before the statement', () {
      final choice = defaultAccount(
        _source('RUB', cards: {'7777'}, opening: '1234.567'),
        [salary],
        newName: 'Альфа-Банк ••7777',
      );

      final account = choice as NewAccount;
      expect(account.name, 'Альфа-Банк ••7777');
      expect(account.type, AccountType.debit);
      expect(account.openingBalance, Money(123457, Currency.rub));
      expect(account.lastDigits, '7777');
    });

    test('of no currency is in the fallback one', () {
      final choice = defaultAccount(
        _source('', currency: null),
        const [],
        newName: 'Счёт',
        fallback: Currency.eur,
      );

      expect((choice as NewAccount).openingBalance, Money(0, Currency.eur));
    });
  });

  group('the category of the bank', () {
    final food = _category('food', 'Продукты');
    final shops = _category('shops', 'Супермаркеты', parentId: 'food');
    final salary = _category('salary', 'Зарплата', kind: CategoryKind.income);
    final categories = [food, shops, salary];

    CategoryChoice of(
      String? name, {
      CategoryKind kind = CategoryKind.expense,
      bool create = false,
    }) => defaultCategory((kind: kind, name: name), categories, create: create);

    test('of the same name and kind is that one', () {
      expect(of(' продукты '), isA<IntoCategory>());
      expect(
        (of('ЗАРПЛАТА', kind: CategoryKind.income) as IntoCategory).categoryId,
        'salary',
      );
      expect(of('Зарплата'), isA<Unsorted>());
    });

    test('with a parent is the subcategory, or the parent', () {
      expect(
        (of('Продукты / Супермаркеты') as IntoCategory).categoryId,
        'shops',
      );
      expect((of('Продукты / Рынок') as IntoCategory).categoryId, 'food');
      final child = of('Продукты / Рынок', create: true) as NewCategory;
      expect(child.name, 'Рынок');
      expect(child.parentId, 'food');
    });

    test('of a new parent is new with its parent, or the inbox', () {
      final child = of('Дом / Ремонт', create: true) as NewCategory;
      expect(child.name, 'Ремонт');
      expect(child.parentName, 'Дом');
      expect(of('Дом / Ремонт'), isA<Unsorted>());
    });

    test('that Birka does not have is new or waits in the inbox', () {
      expect((of('Кафе', create: true) as NewCategory).name, 'Кафе');
      expect(of('Кафе'), isA<Unsorted>());
    });

    test('of no name waits in the inbox', () {
      expect(of(null, create: true), isA<Unsorted>());
      expect(of('  ', create: true), isA<Unsorted>());
    });

    test('in the archive is never chosen', () {
      final choice = defaultCategory(
        (kind: CategoryKind.expense, name: 'Кафе'),
        [_category('cafe', 'Кафе', archived: true)],
        create: false,
      );

      expect(choice, isA<Unsorted>());
    });
  });

  group('a category of a bank', () {
    final food = _category('food', 'Еда');
    final interest = _category(
      'interest',
      'Проценты по вкладу',
      kind: CategoryKind.income,
    );
    final presets = {'groceries': food, 'interest': interest};

    CategoryChoice of(
      String name, {
      CategoryKind kind = CategoryKind.expense,
      bool create = false,
    }) => defaultCategory(
      (kind: kind, name: name),
      [food, interest],
      create: create,
      presets: presets,
    );

    test('goes into the preset that it stands for', () {
      expect((of('Супермаркеты') as IntoCategory).categoryId, 'food');
      expect(
        (of('ПРОЦЕНТЫ', kind: CategoryKind.income) as IntoCategory).categoryId,
        'interest',
      );
    });

    test('of another kind or of an app stays its own', () {
      expect(of('Проценты'), isA<Unsorted>());
      expect(
        (of('Супермаркеты', create: true) as NewCategory).name,
        'Супермаркеты',
      );
    });

    test('of a preset the ledger lacks waits in the inbox', () {
      expect(of('Такси'), isA<Unsorted>());
    });

    test('stands only for presets of its kind, by its name in lower case', () {
      for (final MapEntry(key: kind, value: names)
          in bankCategoryPresets.entries) {
        for (final MapEntry(key: name, value: key) in names.entries) {
          expect(name, name.trim().toLowerCase().replaceAll('ё', 'е'));
          expect(
            categoryPresets.where((it) => it.key == key && it.kind == kind),
            hasLength(1),
            reason: name,
          );
        }
      }
    });
  });

  group('the categories of the presets', () {
    setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

    Category drawn(String id, String name, String icon) => Category(
      id: id,
      kind: CategoryKind.expense,
      name: name,
      archived: false,
      sortOrder: 0,
      icon: icon,
    );

    test('are those of their names and kinds', () {
      final presets = presetCategories([
        _category('food', 'Продукты'),
        _category('gift', 'Подарки', kind: CategoryKind.income),
        _category('old', 'Кафе', archived: true),
      ]);

      expect(presets.keys, ['groceries', 'giftsReceived']);
      expect(presets['groceries']!.id, 'food');
    });

    test('are else the one of the icon of the preset', () {
      final icon = categoryPresets.first.icon;

      expect(
        presetCategories([drawn('food', 'Еда', icon)])['groceries']!.id,
        'food',
      );
      expect(
        presetCategories([
          drawn('food', 'Еда', icon),
          drawn('market', 'Рынок', icon),
        ]),
        isEmpty,
      );
    });
  });

  group('the categories of a statement', () {
    final table = tableOf([
      _zenHeaders,
      _zen('Кафе', 'Карта', '420', '', '0'),
      _zen('Продукты', 'Карта', '1200', '', '0'),
      _zen('Кафе', 'Карта', '380', '', '0'),
      _zen('Зарплата', '', '0', 'Карта', '150000'),
      _zen('', 'Карта', '5000', 'Наличные', '5000'),
    ]);
    final statement = readStatement(table, detectLayout(table));

    test('are of the operations, the most used first', () {
      expect(bankCategoriesOf(statement), [
        (kind: CategoryKind.expense, name: 'Кафе'),
        (kind: CategoryKind.expense, name: 'Продукты'),
        (kind: CategoryKind.income, name: 'Зарплата'),
      ]);
    });

    test('take a transfer of an account left out as an operation', () {
      expect(
        bankCategoriesOf(statement, leftOut: {'Наличные'}),
        contains((kind: CategoryKind.expense, name: null)),
      );
      expect(
        bankCategoriesOf(statement, leftOut: {'Карта'}),
        contains((kind: CategoryKind.income, name: null)),
      );
    });
  });

  group('the name of a new account', () {
    test('is its name in the file', () {
      expect(newAccountNames([_source('Карта Сбера')], zenmoney), {
        'Карта Сбера': 'Карта Сбера',
      });
    });

    test('is else the bank and the digits of the card', () {
      expect(
        newAccountNames([
          _source('RUB', cards: {'4821'}),
        ], tbank),
        {'RUB': '${t.imports.formats['tbank']} ••4821'},
      );
      expect(newAccountNames([_source('')], null), {'': t.imports.account});
    });

    test('tells two of one card by their currencies', () {
      expect(
        newAccountNames([
          _source('RUB', cards: {'4821'}),
          _source('USD', currency: 'USD', cards: {'4821'}),
        ], alfa),
        {
          'RUB': '${t.imports.formats['alfa']} ••4821 RUB',
          'USD': '${t.imports.formats['alfa']} ••4821 USD',
        },
      );
    });

    test('of a format is the name of the bank or the app', () {
      expect(formatLabel(sber), t.imports.formats['sber']);
    });
  });
}
