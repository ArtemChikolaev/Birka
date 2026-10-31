import 'package:categories_common/categories_common.dart';
import 'package:categories_jaspr/categories_jaspr.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';

import 'fake_categories_repository.dart';

void main() {
  late FakeCategoriesRepository repository;
  var closed = 0;

  Future<void> pump(
    ComponentTester tester, {
    String? categoryId,
    CategoryKind kind = CategoryKind.expense,
  }) async {
    tester.pumpComponent(
      BlocProvider(
        create: (_) => CategoryFormCubit(
          repository,
          categoryId: categoryId,
          kind: kind,
        ),
        child: CategoryFormPage(onClose: () => closed++),
      ),
    );
    await tester.pump();
  }

  BirkaTextField nameField() =>
      find.byType(BirkaTextField).evaluate().single.component as BirkaTextField;

  Future<void> typeName(ComponentTester tester, String text) async {
    nameField().onChanged(text);
    await tester.pump();
  }

  Future<void> save(ComponentTester tester) async {
    (find.byType(BirkaForm).evaluate().single.component as BirkaForm)
        .onSubmit();
    await tester.pump();
  }

  Future<void> tap(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
  }

  /// Clicks the button that screen readers call [label].
  Future<void> tapNamed(ComponentTester tester, String label) async {
    await tester.click(
      find.byElementPredicate((element) {
        final component = element.component;
        return component is DomComponent &&
            component.tag == 'button' &&
            component.attributes?['aria-label'] == label;
      }),
    );
    await tester.pump();
  }

  setUp(() {
    setIsClientForTesting(true);
    repository = FakeCategoriesRepository();
    closed = 0;
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('saves a new category with its look and closes', (
    tester,
  ) async {
    await pump(tester);

    await typeName(tester, 'Кафе');
    await tapNamed(tester, 'cup');
    await tapNamed(tester, 'Цвет ${categoryColors[1].substring(1)}');
    await save(tester);

    final draft = repository.added.single;
    expect(draft.name, 'Кафе');
    expect(draft.icon, 'cup');
    expect(draft.color, categoryColors[1]);
    expect(closed, 1);
  });

  testComponents('says that the name is missing and stays open', (
    tester,
  ) async {
    await pump(tester);

    await save(tester);

    expect(find.text('Дайте категории название.'), findsOneComponent);
    expect(closed, 0);
  });

  testComponents('the badge follows the picked look', (tester) async {
    await pump(tester);

    await tapNamed(tester, 'gift');

    final badge =
        find.byType(GlyphBadge).evaluate().first.component as GlyphBadge;
    expect(badge.glyph, BirkaGlyph.gift);
  });

  testComponents('starts on the kind it was opened with, and can change', (
    tester,
  ) async {
    await pump(tester, kind: CategoryKind.income);

    await typeName(tester, 'Премия');
    await save(tester);

    expect(repository.added.single.kind, CategoryKind.income);
  });

  testComponents('offers to go inside another category', (tester) async {
    repository = FakeCategoriesRepository([category('Еда')]);
    await pump(tester);

    await typeName(tester, 'Кафе');
    await tap(tester, 'Еда');
    await save(tester);

    expect(repository.added.single.parentId, 'Еда');
  });

  testComponents('hides the choice of a parent when there are none', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Внутри'), findsNothing);
  });

  testComponents('the cross closes without saving', (tester) async {
    await pump(tester);

    await tester.click(find.byType(GlassIconButton));

    expect(closed, 1);
    expect(repository.added, isEmpty);
  });

  testComponents('a category that is not here closes the form', (tester) async {
    await pump(tester, categoryId: 'nobody');

    expect(closed, 1);
  });

  group('an existing category', () {
    setUp(() {
      repository = FakeCategoriesRepository([
        category('Еда'),
        category('Кафе', parentId: 'Еда'),
      ]);
    });

    testComponents('fills in the form and fixes its kind', (tester) async {
      await pump(tester, categoryId: 'Кафе');

      expect(find.text('Категория'), findsOneComponent);
      expect(nameField().value, 'Кафе');
      expect(find.text('Доходы'), findsNothing);
    });

    testComponents('can be moved to the archive', (tester) async {
      await pump(tester, categoryId: 'Кафе');

      await tap(tester, 'Убрать в архив');

      expect(repository.archived, {'Кафе': true});
      expect(closed, 1);
    });

    testComponents('offers to come back from the archive', (tester) async {
      repository.categories = [category('Старая', archived: true)];
      await pump(tester, categoryId: 'Старая');

      await tap(tester, 'Вернуть из архива');

      expect(repository.archived, {'Старая': false});
    });
  });
}
