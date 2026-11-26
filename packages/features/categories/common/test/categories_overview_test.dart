import 'package:categories_common/categories_common.dart';
import 'package:test/test.dart';

import 'fake_categories_repository.dart';

void main() {
  test('puts subcategories under their parents, in order', () {
    final overview = CategoriesOverview.of([
      testCategory('Food'),
      testCategory('Transport'),
      testCategory('Cafe', parentId: 'Food'),
      testCategory('Taxi', parentId: 'Transport'),
      testCategory('Groceries', parentId: 'Food'),
    ]);

    expect(overview.groups.map((group) => group.category.name), [
      'Food',
      'Transport',
    ]);
    expect(overview.groups.first.children.map((c) => c.name), [
      'Cafe',
      'Groceries',
    ]);
    expect(overview.archived, isEmpty);
    expect(overview.isEmpty, isFalse);
  });

  test('puts archived categories away with their subcategories', () {
    final overview = CategoriesOverview.of([
      testCategory('Old', archived: true),
      testCategory('Older', parentId: 'Old'),
      testCategory('Food'),
      testCategory('Gone', parentId: 'Food', archived: true),
    ]);

    expect(overview.groups.single.category.name, 'Food');
    expect(overview.groups.single.children, isEmpty);
    expect(overview.archived.map((c) => c.name), ['Old', 'Older', 'Gone']);
  });

  test('a subcategory without its parent stands on its own', () {
    final overview = CategoriesOverview.of([
      testCategory('Orphan', parentId: 'Deleted'),
    ]);
    expect(overview.groups.single.category.name, 'Orphan');
  });

  test('matches families and archive names in directory order', () {
    final all = CategoriesOverview.of([
      testCategory('Еда'),
      testCategory('Мёд', parentId: 'Еда'),
      testCategory('Хлеб', parentId: 'Еда'),
      testCategory('Медовые подарки'),
      testCategory('Наборы', parentId: 'Медовые подарки'),
      testCategory('Дом'),
      testCategory('Мёд в офис', archived: true),
      testCategory('Старые подарки', archived: true),
    ]);
    final result = all.matching('  МЕД ');
    expect(result.groups.map((g) => g.category.name), [
      'Еда',
      'Медовые подарки',
    ]);
    expect(result.groups.first.children.map((c) => c.name), ['Мёд']);
    expect(result.groups.last.children.map((c) => c.name), ['Наборы']);
    expect(result.archived.map((c) => c.name), ['Мёд в офис']);
    expect(all.matching('подарки').archived.single.name, 'Старые подарки');
    expect(all.matching('офис').groups, isEmpty);
    expect(all.matching('  '), same(all));
    expect(all.matching('xyz').isEmpty, isTrue);
    expect(all.groups.first.children, hasLength(2));
  });

  test('is empty without categories', () {
    expect(CategoriesOverview.of(const []).isEmpty, isTrue);
  });
}
