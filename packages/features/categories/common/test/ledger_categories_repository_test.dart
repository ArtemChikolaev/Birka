@TestOn('vm')
library;

import 'package:categories_common/categories_common.dart';
import 'package:categories_common/src/data/ledger_categories_repository.dart';
import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart' show LedgerRepository;
import 'package:test/test.dart';

void main() {
  late BirkaDatabase database;
  late CategoriesRepository repository;
  const food = CategoryDraft(
    kind: CategoryKind.expense,
    name: 'Food',
    icon: 'cart',
    color: '#4ade80',
  );

  setUp(() {
    database = BirkaDatabase(NativeDatabase.memory());
    repository = LedgerCategoriesRepository(LedgerRepository(database));
  });
  tearDown(() => database.close());

  Future<Category> only() async =>
      (await repository.watchCategories(CategoryKind.expense).first).single;

  test('a new category comes back with its look', () async {
    await repository.add(food);

    final category = await only();
    expect(category.name, 'Food');
    expect(category.icon, 'cart');
    expect(category.color, '#4ade80');
  });

  test('a ready set keeps its order', () async {
    await repository.addAll(const [
      CategoryDraft(kind: CategoryKind.expense, name: 'Zebra'),
      CategoryDraft(kind: CategoryKind.expense, name: 'Apple'),
    ]);

    final names = (await repository.watchCategories(CategoryKind.expense).first)
        .map((category) => category.name);
    expect(names, ['Zebra', 'Apple']);
  });

  test('a ready set goes in whole or not at all', () async {
    await expectLater(
      repository.addAll(const [
        CategoryDraft(kind: CategoryKind.expense, name: 'Apple'),
        CategoryDraft(
          kind: CategoryKind.expense,
          name: 'Pear',
          parentId: 'nobody',
        ),
      ]),
      throwsA(anything),
    );

    expect(
      await repository.watchCategories(CategoryKind.expense).first,
      isEmpty,
    );
    expect(await database.select(database.changes).get(), isEmpty);
  });

  test('a ready set reaches the list in one step', () async {
    final sizes = <int>[];
    final subscription = repository
        .watchCategories(CategoryKind.expense)
        .listen((categories) => sizes.add(categories.length));
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await repository.addAll(const [
      CategoryDraft(kind: CategoryKind.expense, name: 'Apple'),
      CategoryDraft(kind: CategoryKind.expense, name: 'Pear'),
      CategoryDraft(kind: CategoryKind.expense, name: 'Plum'),
    ]);
    await pumpEventQueue();

    expect(sizes, [0, 3]);
  });

  test('a change replaces the fields', () async {
    await repository.add(food);
    final id = (await only()).id;

    await repository.update(
      id,
      const CategoryDraft(kind: CategoryKind.expense, name: 'Groceries'),
    );

    final category = (await repository.category(id))!;
    expect(category.name, 'Groceries');
    expect(category.icon, isNull);
    expect(category.color, isNull);
  });

  test('an archived category stays in the stream', () async {
    await repository.add(food);
    final id = (await only()).id;

    await repository.setArchived(id, archived: true);

    expect((await only()).archived, isTrue);
  });
}
