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

  test('is empty without categories', () {
    expect(CategoriesOverview.of(const []).isEmpty, isTrue);
  });
}
