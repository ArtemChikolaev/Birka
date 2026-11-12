/// The метки, operations and rates of the boards «Метки и поездки» (ADR 0027)
/// and a repository that keeps them in memory, for the tests of both hosts.
library;

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:tags_common/tags_common.dart';

/// Thursday, November 12, 2026: the last day of the trip to Tbilisi.
final boardToday = CivilDate(2026, 11, 12);

/// The lari.
final gel = Currency.custom('GEL', decimalDigits: 2);

/// [units] whole units of [currency].
Money units(int units, Currency currency) => Money(units * 100, currency);

/// [text] with the spaces of formatted amounts.
String nb(String text) => text.replaceAll(' ', String.fromCharCode(0xA0));

/// The trip to Tbilisi, which marks its days.
final tbilisi = Tag(
  id: 'tbilisi',
  name: 'Тбилиси',
  days: TagDays(CivilDate(2026, 11, 3), CivilDate(2026, 11, 12)),
  marksDays: true,
);

/// A trip of May.
final istanbul = Tag(
  id: 'istanbul',
  name: 'Стамбул',
  days: TagDays(CivilDate(2026, 5, 2), CivilDate(2026, 5, 9)),
  marksDays: true,
);

/// A метка without days.
const renovation = Tag(id: 'renovation', name: 'Ремонт кухни');

/// The метки of the boards.
List<Tag> boardTags() => [tbilisi, istanbul, renovation];

/// A category of expenses.
Category category(String id, String name, String color, String icon) =>
    Category(
      id: id,
      kind: CategoryKind.expense,
      name: name,
      archived: false,
      sortOrder: 0,
      icon: icon,
      color: color,
    );

/// The categories of the boards.
List<Category> boardCategories() => [
  category('travel', 'Поездки', '#60A5FA', 'plane'),
  category('cafe', 'Кафе', '#FBBF24', 'cup'),
  category('home', 'Дом', '#A78BFA', 'home'),
];

/// An expense of [amount] on [day] to [categoryId] that wears [tags].
Transaction expense(
  String id,
  Money amount,
  CivilDate day, {
  String categoryId = 'cafe',
  String note = '',
  Map<String, TagMark> tags = const {},
  String accountId = 'card',
}) => Transaction(
  id: id,
  kind: TransactionKind.expense,
  occurredOn: day,
  note: note,
  status: TransactionStatus.cleared,
  source: TransactionSource.manual,
  entries: [Entry(accountId: accountId, amount: -amount)],
  allocations: [Allocation(categoryId: categoryId, amount: amount)],
  tags: tags,
);

/// The operations of the boards: the tickets in rubles and the flat in
/// dollars before the trip, two lunches in lari on the spot, and a tile for
/// the kitchen.
List<Transaction> boardOperations() => [
  expense(
    'lunch',
    units(38, gel),
    boardToday,
    note: 'Хинкальная',
    tags: {'tbilisi': TagMark.days},
    accountId: 'lari',
  ),
  expense(
    'dinner',
    units(96, gel),
    CivilDate(2026, 11, 11),
    note: 'Ужин в Сололаки',
    tags: {'tbilisi': TagMark.days},
    accountId: 'lari',
  ),
  expense(
    'tile',
    units(18400, Currency.rub),
    CivilDate(2026, 11, 2),
    categoryId: 'home',
    note: 'Плитка и затирка',
    tags: {'renovation': TagMark.hand},
  ),
  expense(
    'flat',
    units(420, Currency.usd),
    CivilDate(2026, 10, 20),
    categoryId: 'travel',
    note: 'Квартира в Сололаки',
    tags: {'tbilisi': TagMark.hand},
    accountId: 'dollars',
  ),
  expense(
    'tickets',
    units(23800, Currency.rub),
    CivilDate(2026, 10, 14),
    categoryId: 'travel',
    note: 'Билеты Москва — Тбилиси',
    tags: {'tbilisi': TagMark.hand},
  ),
];

/// One lari for 30,05 rubles and one dollar for 81,40, from October on.
RateBook boardRates() => RateBook([
  DayRates(CivilDate(2026, 10, 1), {
    'GEL': Decimal.parse('30.05'),
    'USD': Decimal.parse('81.40'),
  }),
]);

/// Keeps the метки and the operations in memory, and remembers what was
/// written.
final class FakeTagsRepository implements TagsRepository {
  /// Creates a repository of [tags] and [operations] on [today].
  FakeTagsRepository({
    List<Tag>? tags,
    List<Transaction>? operations,
    List<Category>? categories,
    RateBook? rates,
    CivilDate? today,
    this.toMark = 0,
  }) : _tags = tags ?? boardTags(),
       _operations = operations ?? boardOperations(),
       _categories = categories ?? boardCategories(),
       _rates = rates ?? boardRates(),
       _today = today ?? boardToday;

  List<Tag> _tags;
  List<Transaction> _operations;
  final List<Category> _categories;
  final RateBook _rates;
  final CivilDate _today;

  /// How many expenses [expensesOf] finds.
  int toMark;

  /// The ids of the trips whose days were taken back.
  final unmarked = <String>[];

  /// What [setTags] put on, by the id of the operation.
  final picked = <String, Set<String>>{};

  final _changes = StreamController<void>.broadcast();

  Stream<T> _watch<T>(T Function() read) => Stream.multi((controller) {
    controller.add(read());
    final subscription = _changes.stream.listen((_) => controller.add(read()));
    controller.onCancel = subscription.cancel;
  });

  @override
  CivilDate today() => _today;

  @override
  Stream<List<Tag>> watchTags() => _watch(() => _tags);

  @override
  Stream<List<Transaction>> watchTagged() => _watch(
    () => [
      for (final operation in _operations)
        if (operation.tagIds.isNotEmpty) operation,
    ],
  );

  @override
  Stream<List<Transaction>> watchTransactionsOf(String id) => _watch(
    () => [
      for (final operation in _operations)
        if (operation.tagIds.contains(id)) operation,
    ],
  );

  @override
  Stream<Transaction?> watchTransaction(String id) => _watch(
    () => _operations.where((operation) => operation.id == id).firstOrNull,
  );

  @override
  Stream<List<Category>> watchCategories() => _watch(() => _categories);

  @override
  Stream<RateBook> watchRates() => _watch(() => _rates);

  @override
  Stream<Currency?> watchBaseCurrency() => _watch(() => Currency.rub);

  @override
  Stream<Currency?> watchMainCurrency() => _watch(() => Currency.rub);

  @override
  Future<int> expensesOf(TagDays days) async => toMark;

  @override
  Future<TagMarking> add({
    required String name,
    TagDays? days,
    bool marksDays = false,
  }) async {
    final tag = Tag(
      id: 'tag-${_tags.length}',
      name: name,
      days: days,
      marksDays: marksDays,
    );
    _tags = [..._tags, tag];
    _changes.add(null);
    return TagMarking(tag, marked: marksDays ? toMark : 0);
  }

  @override
  Future<TagMarking> update(Tag tag) async {
    _tags = [
      for (final it in _tags) it.id == tag.id ? tag : it,
    ];
    _changes.add(null);
    return TagMarking(tag, marked: 0);
  }

  @override
  Future<void> unmarkDays(String id) async => unmarked.add(id);

  @override
  Future<void> setTags(String id, Set<String> tagIds) async {
    picked[id] = tagIds;
    _operations = [
      for (final operation in _operations)
        operation.id == id
            ? Transaction(
                id: operation.id,
                kind: operation.kind,
                occurredOn: operation.occurredOn,
                note: operation.note,
                status: operation.status,
                source: operation.source,
                entries: operation.entries,
                allocations: operation.allocations,
                tags: {for (final tagId in tagIds) tagId: TagMark.hand},
              )
            : operation,
    ];
    _changes.add(null);
  }
}
