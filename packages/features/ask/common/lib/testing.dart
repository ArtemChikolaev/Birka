/// The story of the boards of «Спросить» and a repository on it, for the
/// tests of this feature and of the hosts.
library;

import 'dart:async';

import 'package:ask_common/ask_common.dart';
import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Thursday, 12 November 2026: the last day of the trip to Tbilisi.
final askToday = CivilDate(2026, 11, 12);

/// The Georgian lari.
final gel = Currency.custom('GEL', decimalDigits: 2);

/// [units] whole units of [currency].
Money units(int units, Currency currency) => Money(units * 100, currency);

/// A category of [kind].
Category askCategory(
  String id,
  String name, {
  CategoryKind kind = CategoryKind.expense,
  String? parentId,
  int sortOrder = 0,
}) => Category(
  id: id,
  parentId: parentId,
  kind: kind,
  name: name,
  archived: false,
  sortOrder: sortOrder,
);

/// The categories of the story, of both kinds.
List<Category> askCategories() => [
  askCategory('groceries', 'Продукты'),
  askCategory('cafe', 'Кафе', sortOrder: 1),
  askCategory('coffee', 'Кофейни', parentId: 'cafe', sortOrder: 2),
  askCategory('transport', 'Транспорт', sortOrder: 3),
  askCategory('travel', 'Поездки', sortOrder: 4),
  askCategory('gifts', 'Подарки', sortOrder: 5),
  askCategory('home', 'Дом', sortOrder: 6),
  askCategory('subs', 'Подписки', sortOrder: 7),
  askCategory('salary', 'Зарплата', kind: CategoryKind.income),
  askCategory('sold', 'Продажа вещей', kind: CategoryKind.income),
];

/// The trip to Tbilisi, from 3 to 12 November 2026.
final askTbilisi = Tag(
  id: 'tbilisi',
  name: 'Тбилиси',
  days: TagDays(CivilDate(2026, 11, 3), CivilDate(2026, 11, 12)),
  marksDays: true,
);

/// The метки of the story.
List<Tag> askTags() => [
  askTbilisi,
  Tag(
    id: 'istanbul',
    name: 'Стамбул',
    days: TagDays(CivilDate(2026, 5, 2), CivilDate(2026, 5, 9)),
    marksDays: true,
  ),
  const Tag(id: 'renovation', name: 'Ремонт кухни'),
];

/// An account that holds [balance], in its currency.
AccountBalance askAccount(
  String id,
  String name,
  Money balance, {
  bool includeInTotals = true,
}) => AccountBalance(
  Account(
    id: id,
    name: name,
    type: AccountType.debit,
    openingBalance: Money.zero(balance.currency),
    includeInTotals: includeInTotals,
    archived: false,
    sortOrder: 0,
  ),
  balance,
);

/// The accounts of the story.
List<AccountBalance> askBalances() => [
  askAccount('card', 'Зарплатная карта', units(86400, Currency.rub)),
  askAccount('cash', 'Наличные', units(3200, Currency.rub)),
  askAccount('lari', 'Карта в лари', units(2140, gel)),
  askAccount('savings', 'Накопления', units(283273, Currency.rub)),
];

/// An operation of [kind] of [amount] on [day] in [categoryId].
Transaction askOperation(
  String id,
  Money amount,
  CivilDate day, {
  String categoryId = 'cafe',
  String note = '',
  TransactionKind kind = TransactionKind.expense,
  Map<String, TagMark> tags = const {},
  String accountId = 'card',
}) => Transaction(
  id: id,
  kind: kind,
  occurredOn: day,
  note: note,
  status: TransactionStatus.cleared,
  source: TransactionSource.manual,
  entries: [
    Entry(
      accountId: accountId,
      amount: kind == TransactionKind.income ? amount : -amount,
    ),
  ],
  allocations: [Allocation(categoryId: categoryId, amount: amount)],
  tags: tags,
);

CivilDate _day(int month, int day) => CivilDate(2026, month, day);

/// The operations of the story: cafes in September and October, the trip
/// to Tbilisi, the renovation and two incomes.
List<Transaction> askOperations() {
  const trip = {'tbilisi': TagMark.days};
  const byHand = {'tbilisi': TagMark.hand};
  return [
    askOperation(
      'beluga',
      units(2400, Currency.rub),
      _day(9, 19),
      note: 'Ресторан Белуга',
    ),
    askOperation(
      'bakery',
      units(1240, Currency.rub),
      _day(10, 3),
      note: 'Пекарня у дома',
      accountId: 'cash',
    ),
    askOperation(
      'groceries',
      units(5640, Currency.rub),
      _day(10, 4),
      categoryId: 'groceries',
      note: 'Продукты на неделю',
    ),
    askOperation(
      'surf',
      units(1950, Currency.rub),
      _day(10, 14),
      note: 'Кофейня Surf',
    ),
    askOperation(
      'tickets',
      units(23800, Currency.rub),
      _day(10, 14),
      categoryId: 'travel',
      note: 'Билеты в Тбилиси',
      tags: byHand,
    ),
    askOperation(
      'mom',
      units(6980, Currency.rub),
      _day(10, 17),
      categoryId: 'gifts',
      note: 'Подарок маме',
    ),
    askOperation(
      'bike',
      units(12000, Currency.rub),
      _day(10, 18),
      categoryId: 'sold',
      note: 'Велосипед на Авито',
      kind: TransactionKind.income,
      accountId: 'cash',
    ),
    askOperation(
      'flat',
      units(420, Currency.usd),
      _day(10, 20),
      categoryId: 'travel',
      note: 'Квартира в Тбилиси',
      tags: byHand,
      accountId: 'dollars',
    ),
    askOperation(
      'khinkali',
      units(1780, Currency.rub),
      _day(10, 21),
      note: 'Хинкальная на Пятницкой',
    ),
    askOperation(
      'salary',
      units(210000, Currency.rub),
      _day(10, 25),
      categoryId: 'salary',
      note: 'Зарплата',
      kind: TransactionKind.income,
    ),
    askOperation(
      'coffee',
      units(250, Currency.rub),
      _day(10, 28),
      categoryId: 'coffee',
      note: 'Кофе с собой',
    ),
    askOperation(
      'week',
      units(5380, Currency.rub),
      _day(11, 1),
      categoryId: 'groceries',
      note: 'Продукты на неделю',
    ),
    askOperation(
      'tile',
      units(18400, Currency.rub),
      _day(11, 2),
      categoryId: 'home',
      note: 'Плитка и затирка',
      tags: {'renovation': TagMark.hand},
    ),
    askOperation(
      'taxi',
      units(70, gel),
      _day(11, 3),
      categoryId: 'transport',
      note: 'Такси из аэропорта',
      tags: trip,
      accountId: 'lari',
    ),
    askOperation(
      'barbarestan',
      units(210, gel),
      _day(11, 8),
      note: 'Ужин в Barbarestan',
      tags: trip,
      accountId: 'lari',
    ),
    askOperation(
      'sololaki',
      units(96, gel),
      _day(11, 11),
      note: 'Ужин в Сололаки',
      tags: trip,
      accountId: 'lari',
    ),
  ];
}

/// The rates of the story: 1 ₾ = 30,05 ₽, 1 $ = 81,40 ₽ from 1 October.
RateBook askRates() => RateBook([
  DayRates(CivilDate(2026, 9, 1), {
    'GEL': Decimal.parse('30.05'),
    'USD': Decimal.parse('81.40'),
  }),
]);

/// A repository on the story, which keeps its questions in memory.
final class FakeAskRepository implements AskRepository {
  /// Creates a repository on the story, or on what is given.
  FakeAskRepository({
    List<Category>? categories,
    List<Tag>? tags,
    List<AccountBalance>? balances,
    List<Transaction>? operations,
    RateBook? rates,
    CivilDate? today,
    this.base = Currency.rub,
    this.monthStart = 1,
    List<String> recent = const [],
  }) : _categories = categories ?? askCategories(),
       _tags = tags ?? askTags(),
       _balances = balances ?? askBalances(),
       operations = operations ?? askOperations(),
       _rates = rates ?? askRates(),
       _today = today ?? askToday,
       _recent = recent;

  final List<Category> _categories;
  final List<Tag> _tags;
  final List<AccountBalance> _balances;
  final RateBook _rates;
  final CivilDate _today;
  List<String> _recent;

  /// The operations it holds; [changed] tells the watchers.
  List<Transaction> operations;

  /// The currency of the totals.
  Currency? base;

  /// The day that months start on.
  int monthStart;

  /// The ranges that the operations were read for.
  final asked = <(CivilDate?, CivilDate?, String?)>[];

  final _changes = StreamController<void>.broadcast();

  /// Tells the watchers that [operations] changed.
  void changed() => _changes.add(null);

  Stream<T> _watch<T>(T Function() read) => Stream.multi((controller) {
    controller.add(read());
    final subscription = _changes.stream.listen((_) => controller.add(read()));
    controller.onCancel = subscription.cancel;
  });

  @override
  CivilDate today() => _today;

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) => _watch(
    () => [
      for (final category in _categories)
        if (category.kind == kind) category,
    ],
  );

  @override
  Stream<List<Tag>> watchTags() => _watch(() => _tags);

  @override
  Stream<List<AccountBalance>> watchBalances() => _watch(() => _balances);

  @override
  Stream<List<Transaction>> watchTransactions({
    CivilDate? from,
    CivilDate? to,
    String? tagId,
  }) {
    asked.add((from, to, tagId));
    return _watch(
      () => [
        for (final operation in operations)
          if ((from == null || from.compareTo(operation.occurredOn) <= 0) &&
              (to == null || operation.occurredOn.compareTo(to) <= 0) &&
              (tagId == null || operation.tagIds.contains(tagId)))
            operation,
      ],
    );
  }

  @override
  Stream<RateBook> watchRates() => _watch(() => _rates);

  @override
  Stream<Currency?> watchBaseCurrency() => _watch(() => base);

  @override
  Stream<int> watchMonthStart() => _watch(() => monthStart);

  @override
  List<String> recent() => _recent;

  @override
  Future<void> keepRecent(List<String> questions) async {
    _recent = questions;
  }
}
