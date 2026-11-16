/// The limits of the boards «Лимиты по категориям» (ADR 0033) and a
/// repository that keeps them in memory, for the tests of both hosts.
library;

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_common/limits_common.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Wednesday, November 18, 2026: 13 days of the month are left.
final CivilDate boardToday = CivilDate(2026, 11, 18);

/// [whole] rubles.
Money rubles(int whole) => Money(whole * 100, Currency.rub);

/// [whole] euros.
Money euros(int whole) => Money(whole * 100, Currency.eur);

/// A euro at 91,50 ₽ and a dollar at 80 ₽ since August.
final RateBook boardRates = RateBook([
  DayRates(CivilDate(2026, 8, 1), {
    'EUR': Decimal.parse('91.5'),
    'USD': Decimal.fromInt(80),
  }),
]);

/// A top category of expenses.
Category boardCategory(
  String id,
  String name, {
  CategoryLimit? limit,
  int sortOrder = 0,
  String? icon,
  String? color,
}) => Category(
  id: id,
  kind: CategoryKind.expense,
  name: name,
  archived: false,
  sortOrder: sortOrder,
  icon: icon,
  color: color,
  limit: limit,
);

/// [category] with [limit] instead of its own.
Category withLimit(Category category, CategoryLimit? limit) => Category(
  id: category.id,
  kind: category.kind,
  name: category.name,
  archived: category.archived,
  sortOrder: category.sortOrder,
  parentId: category.parentId,
  icon: category.icon,
  color: category.color,
  limit: limit,
);

/// Продукты: 30 000 ₽ a month.
final Category groceries = boardCategory(
  'groceries',
  'Продукты',
  limit: CategoryLimit(rubles(30000)),
  icon: 'cart',
  color: '#4ade80',
);

/// Кафе: 12 000 ₽ a month.
final Category cafe = boardCategory(
  'cafe',
  'Кафе',
  limit: CategoryLimit(rubles(12000)),
  sortOrder: 1,
  icon: 'cup',
  color: '#fbbf24',
);

/// Транспорт: 5 000 ₽ a month.
final Category transport = boardCategory(
  'transport',
  'Транспорт',
  limit: CategoryLimit(rubles(5000)),
  sortOrder: 2,
  icon: 'bus',
  color: '#60a5fa',
);

/// Дом, without a limit: its spending jumps.
final Category home = boardCategory(
  'home',
  'Дом',
  sortOrder: 3,
  icon: 'home',
  color: '#a78bfa',
);

/// Здоровье, without a limit: it spent in one month of three.
final Category health = boardCategory(
  'health',
  'Здоровье',
  sortOrder: 4,
  icon: 'heart',
  color: '#fb7185',
);

/// Досуг: 8 000 ₽ a month, which November went over.
final Category leisure = boardCategory(
  'leisure',
  'Досуг',
  limit: CategoryLimit(rubles(8000)),
  sortOrder: 5,
  icon: 'ticket',
  color: '#fb923c',
);

/// Подписки, without a limit: regular payments go to them.
final Category subscriptions = boardCategory(
  'subscriptions',
  'Подписки',
  sortOrder: 6,
  icon: 'repeat',
  color: '#22d3ee',
);

/// Поездки: 400 € a month.
final Category travel = boardCategory(
  'travel',
  'Поездки',
  limit: CategoryLimit(euros(400)),
  sortOrder: 8,
  icon: 'plane',
  color: '#60a5fa',
);

/// The categories of the boards, in their order.
final List<Category> boardCategories = [
  groceries,
  cafe,
  transport,
  home,
  health,
  leisure,
  subscriptions,
  travel,
];

CategoryDayTotal _on(Category category, int month, int day, Money total) =>
    CategoryDayTotal(category, CivilDate(2026, month, day), total);

/// What August to October took, for the averages, and November so far.
final List<CategoryDayTotal> boardSpending = [
  _on(groceries, 8, 10, rubles(29000)),
  _on(groceries, 9, 10, rubles(30120)),
  _on(groceries, 10, 10, rubles(29800)),
  _on(cafe, 8, 12, rubles(11500)),
  _on(cafe, 9, 12, rubles(11860)),
  _on(cafe, 10, 12, rubles(11500)),
  _on(leisure, 8, 15, rubles(7400)),
  _on(leisure, 9, 15, rubles(7830)),
  _on(leisure, 10, 15, rubles(7600)),
  _on(transport, 8, 5, rubles(4400)),
  _on(transport, 9, 5, rubles(4560)),
  _on(transport, 10, 5, rubles(4600)),
  _on(home, 8, 3, rubles(2100)),
  _on(home, 9, 3, rubles(11400)),
  _on(home, 10, 3, rubles(5130)),
  _on(health, 9, 14, rubles(7020)),
  _on(subscriptions, 8, 1, rubles(1997)),
  _on(subscriptions, 9, 1, rubles(1997)),
  _on(subscriptions, 10, 1, rubles(1997)),
  _on(travel, 8, 20, rubles(15370)),
  _on(travel, 9, 20, rubles(15370)),
  _on(travel, 10, 20, rubles(15370)),
  _on(leisure, 11, 7, rubles(4300)),
  _on(leisure, 11, 16, rubles(5000)),
  _on(cafe, 11, 3, rubles(4150)),
  _on(cafe, 11, 12, rubles(6000)),
  _on(travel, 11, 9, euros(214)),
  _on(travel, 11, 9, rubles(4300)),
  _on(groceries, 11, 2, rubles(18640)),
  _on(transport, 11, 4, rubles(2870)),
  _on(home, 11, 6, rubles(6400)),
  _on(health, 11, 10, rubles(2100)),
  _on(subscriptions, 11, 1, rubles(1997)),
];

/// Limits in memory, which a test changes and the cubits follow.
final class MemoryLimitsRepository implements LimitsRepository {
  /// Creates the repository with the story of the boards, unless told
  /// otherwise.
  MemoryLimitsRepository({
    List<Category>? categories,
    List<CategoryDayTotal>? spending,
    RateBook? rates,
    CivilDate? today,
    this.monthStart = 1,
    this.shown = Currency.rub,
    Set<String>? regular,
    List<Currency>? currencies,
  }) : categories = categories ?? boardCategories,
       spending = spending ?? boardSpending,
       rates = rates ?? boardRates,
       todayIs = today ?? boardToday,
       regular = regular ?? {subscriptions.id},
       accountCurrencies = currencies ?? const [Currency.rub, Currency.eur];

  /// The categories of expenses.
  List<Category> categories;

  /// The expenses by day.
  List<CategoryDayTotal> spending;

  /// The rates.
  RateBook rates;

  /// Today.
  CivilDate todayIs;

  /// The day the month starts on.
  int monthStart;

  /// The currency the totals are shown in.
  Currency shown;

  /// The categories of regular payments.
  Set<String> regular;

  /// The currencies of the accounts.
  List<Currency> accountCurrencies;

  /// The limits set, in their order.
  final setLimits = <(String, CategoryLimit?)>[];

  /// What [setLimit] throws, when set.
  Exception? failure;

  final _changes = StreamController<void>.broadcast();

  /// Tells the cubits that something changed.
  void changed() => _changes.add(null);

  Stream<T> _watch<T>(T Function() read) => Stream.multi((controller) {
    controller.add(read());
    final subscription = _changes.stream.listen((_) => controller.add(read()));
    controller.onCancel = subscription.cancel;
  });

  @override
  CivilDate today() => todayIs;

  @override
  Stream<int> watchMonthStart() => _watch(() => monthStart);

  @override
  Stream<List<Category>> watchCategories() => _watch(
    () => [
      for (final category in categories)
        if (!category.archived) category,
    ],
  );

  @override
  Stream<List<CategoryDayTotal>> watchSpending({
    required CivilDate from,
    required CivilDate to,
  }) => _watch(
    () => [
      for (final row in spending)
        if (row.day.compareTo(from) >= 0 && row.day.compareTo(to) <= 0) row,
    ],
  );

  @override
  Stream<RateBook> watchRates() => _watch(() => rates);

  @override
  Stream<Currency> watchShownCurrency() => _watch(() => shown);

  @override
  Stream<Set<String>> watchRegular() => _watch(() => regular);

  @override
  Future<List<Currency>> currencies() async => accountCurrencies;

  @override
  Future<void> setLimit(String categoryId, CategoryLimit? limit) async {
    if (failure case final failure?) throw failure;
    setLimits.add((categoryId, limit));
    categories = [
      for (final category in categories)
        category.id == categoryId ? withLimit(category, limit) : category,
    ];
    changed();
  }
}
