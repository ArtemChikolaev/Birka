import 'package:categories_common/categories_common.dart';
import 'package:l10n/l10n.dart';
import 'package:test/test.dart';

import 'fake_categories_repository.dart';

void main() {
  Future<void> settle() => Future<void>.delayed(Duration.zero);
  Matcher loaded(CategoryKind kind, List<String> names) =>
      isA<CategoriesLoaded>()
          .having((state) => state.kind, 'kind', kind)
          .having(
            (state) => state.overview.groups.map((g) => g.category.name),
            'groups',
            names,
          );

  final food = testCategory('Food');
  final salary = testCategory('Salary', kind: CategoryKind.income);

  test('starts on expenses', () async {
    final cubit = CategoriesCubit(FakeCategoriesRepository([food, salary]));
    addTearDown(cubit.close);
    await settle();
    expect(cubit.state, loaded(CategoryKind.expense, ['Food']));
  });

  test('switches to the other kind', () async {
    final cubit = CategoriesCubit(FakeCategoriesRepository([food, salary]));
    addTearDown(cubit.close);
    await settle();

    await cubit.kindChanged(CategoryKind.income);
    await settle();
    expect(cubit.state, loaded(CategoryKind.income, ['Salary']));
  });

  test('follows later changes of its kind', () async {
    final repository = FakeCategoriesRepository([food]);
    final cubit = CategoriesCubit(repository);
    addTearDown(cubit.close);
    await settle();

    repository.emit([food, testCategory('Taxi')]);
    await settle();
    expect(cubit.state, loaded(CategoryKind.expense, ['Food', 'Taxi']));
  });

  test('says so when the categories cannot be read, and can retry', () async {
    final repository = FakeCategoriesRepository([food]);
    final cubit = CategoriesCubit(repository);
    addTearDown(cubit.close);
    await settle();

    repository.failStream();
    await settle();
    expect(cubit.state, isA<CategoriesFailed>());

    await cubit.retry();
    await settle();
    expect(cubit.state, loaded(CategoryKind.expense, ['Food']));
  });

  test('adds the ready set in the language of the user', () async {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
    final repository = FakeCategoriesRepository();
    final cubit = CategoriesCubit(repository);
    addTearDown(cubit.close);

    await cubit.addPresets();

    final first = repository.added.first;
    expect(first.name, 'Продукты');
    expect(first.kind, CategoryKind.expense);
    expect(first.icon, 'cart');
    expect(first.color, categoryColors.first);
  });

  test('adds the ready set only of the kind on the screen', () async {
    final repository = FakeCategoriesRepository([food]);
    final cubit = CategoriesCubit(repository);
    addTearDown(cubit.close);
    await settle();

    await cubit.kindChanged(CategoryKind.income);
    await settle();
    await cubit.addPresets();

    expect(
      repository.added.map((draft) => draft.name),
      unorderedEquals([
        for (final preset in categoryPresets)
          if (preset.kind == CategoryKind.income)
            t.categories.presets[preset.key],
      ]),
    );
    expect(
      repository.added.map((draft) => draft.kind),
      everyElement(CategoryKind.income),
    );
  });
}
