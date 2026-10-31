import 'package:categories_common/categories_common.dart';
import 'package:test/test.dart';

void main() {
  test('a category shows its own look', () {
    const category = Category(
      id: 'food',
      kind: CategoryKind.expense,
      name: 'Food',
      archived: false,
      sortOrder: 0,
      icon: 'cup',
      color: '#123456',
    );

    expect(category.iconName, 'cup');
    expect(category.colorHex, '#123456');
  });

  test('a category without a look takes the first one on offer', () {
    const category = Category(
      id: 'food',
      kind: CategoryKind.expense,
      name: 'Food',
      archived: false,
      sortOrder: 0,
    );

    expect(category.iconName, categoryIcons.first);
    expect(category.colorHex, categoryColors.first);
  });
}
