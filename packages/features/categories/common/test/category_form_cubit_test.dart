import 'package:categories_common/categories_common.dart';
import 'package:test/test.dart';

import 'fake_categories_repository.dart';

void main() {
  late FakeCategoriesRepository repository;
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<CategoryFormCubit> form({String? id, CategoryKind? kind}) async {
    final cubit = CategoryFormCubit(
      repository,
      categoryId: id,
      kind: kind ?? CategoryKind.expense,
    );
    addTearDown(cubit.close);
    await settle();
    return cubit;
  }

  setUp(() => repository = FakeCategoriesRepository());

  test('needs a name', () async {
    final cubit = await form();
    await cubit.save();

    expect(cubit.state.nameMissing, isTrue);
    expect(repository.added, isEmpty);

    cubit.nameChanged('F');
    expect(cubit.state.nameMissing, isFalse);
  });

  test('saves a new category with its look', () async {
    final cubit = await form(kind: CategoryKind.income);
    cubit
      ..nameChanged('  Salary ')
      ..colorChanged(categoryColors[2])
      ..iconChanged('briefcase');
    await cubit.save();

    expect(cubit.state.status, CategoryFormStatus.saved);
    final draft = repository.added.single;
    expect(draft.name, 'Salary');
    expect(draft.kind, CategoryKind.income);
    expect(draft.color, categoryColors[2]);
    expect(draft.icon, 'briefcase');
    expect(draft.parentId, isNull);
  });

  test('offers the live categories of the first level as parents', () async {
    repository = FakeCategoriesRepository([
      testCategory('Food'),
      testCategory('Cafe', parentId: 'Food'),
      testCategory('Old', archived: true),
      testCategory('Salary', kind: CategoryKind.income),
    ]);
    final cubit = await form();

    expect(cubit.state.parents.map((c) => c.name), ['Food']);
  });

  test('another kind has other parents and drops the picked one', () async {
    repository = FakeCategoriesRepository([
      testCategory('Food'),
      testCategory('Salary', kind: CategoryKind.income),
    ]);
    final cubit = await form();
    cubit.parentChanged('Food');

    await cubit.kindChanged(CategoryKind.income);

    expect(cubit.state.parentId, isNull);
    expect(cubit.state.parents.map((c) => c.name), ['Salary']);
  });

  test('saves a subcategory under its parent', () async {
    repository = FakeCategoriesRepository([testCategory('Food')]);
    final cubit = await form();
    cubit
      ..nameChanged('Cafe')
      ..parentChanged('Food');
    await cubit.save();

    expect(repository.added.single.parentId, 'Food');
  });

  test('reports a failed save', () async {
    repository.failure = Exception('disk full');
    final cubit = await form();
    cubit.nameChanged('Food');
    await cubit.save();
    expect(cubit.state.status, CategoryFormStatus.failed);
  });

  group('an existing category', () {
    setUp(() {
      repository = FakeCategoriesRepository([
        testCategory('Food', icon: 'cart', color: categoryColors[1]),
        testCategory('Cafe', parentId: 'Food'),
        testCategory('Taxi'),
      ]);
    });

    test('fills in the form', () async {
      final cubit = await form(id: 'Cafe');

      expect(cubit.state.status, CategoryFormStatus.editing);
      expect(cubit.state.isNew, isFalse);
      expect(cubit.state.name, 'Cafe');
      expect(cubit.state.parentId, 'Food');
    });

    test('takes its look from the row', () async {
      final cubit = await form(id: 'Food');
      expect(cubit.state.icon, 'cart');
      expect(cubit.state.color, categoryColors[1]);
    });

    test('keeps its kind', () async {
      final cubit = await form(id: 'Taxi');
      await cubit.kindChanged(CategoryKind.income);
      expect(cubit.state.kind, CategoryKind.expense);
    });

    test('cannot go inside itself', () async {
      final cubit = await form(id: 'Taxi');
      expect(cubit.state.parents.map((c) => c.name), ['Food']);
    });

    test('with subcategories it cannot go inside another one', () async {
      final cubit = await form(id: 'Food');
      expect(cubit.state.parents, isEmpty);
    });

    test('saves over itself', () async {
      final cubit = await form(id: 'Cafe');
      cubit
        ..nameChanged('Coffee')
        ..parentChanged(null);
      await cubit.save();

      expect(repository.updated['Cafe']?.name, 'Coffee');
      expect(repository.updated['Cafe']?.parentId, isNull);
    });

    test('can be put away and brought back', () async {
      final cubit = await form(id: 'Taxi');
      await cubit.toggleArchived();
      expect(cubit.state.status, CategoryFormStatus.saved);
      expect((await repository.category('Taxi'))?.archived, isTrue);

      final again = await form(id: 'Taxi');
      expect(again.state.archived, isTrue);
      await again.toggleArchived();
      expect((await repository.category('Taxi'))?.archived, isFalse);
    });

    test('reports a category that is gone', () async {
      final cubit = await form(id: 'nobody');
      expect(cubit.state.status, CategoryFormStatus.failed);
    });
  });
}
