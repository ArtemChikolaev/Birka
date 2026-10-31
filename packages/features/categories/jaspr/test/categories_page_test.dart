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
  Future<void> pump(
    ComponentTester tester,
    FakeCategoriesRepository repository, {
    String? note,
  }) async {
    tester.pumpComponent(
      BlocProvider(
        create: (_) => CategoriesCubit(repository),
        child: CategoriesPage(
          addHrefOf: (kind) => 'add/${kind.name}',
          hrefOf: (id) => 'open/$id',
          note: note,
        ),
      ),
    );
    await tester.pump();
  }

  List<String?> links() => [
    for (final element in find.tag('a').evaluate())
      (element.component as DomComponent).attributes?['href'],
  ];

  Future<void> tap(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
  }

  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('without categories it offers the ready set', (tester) async {
    final repository = FakeCategoriesRepository();
    await pump(tester, repository);

    expect(find.text('Пока нет категорий'), findsOneComponent);
    await tap(tester, 'Добавить готовый набор');

    expect(repository.added.first.name, 'Продукты');
    expect(
      repository.added.map((draft) => draft.kind),
      everyElement(CategoryKind.expense),
    );
  });

  testComponents('without categories it also lets you make your own', (
    tester,
  ) async {
    await pump(tester, FakeCategoriesRepository());

    expect(links(), ['add/expense', 'add/expense']);
  });

  testComponents('shows subcategories under their parent with their number', (
    tester,
  ) async {
    await pump(
      tester,
      FakeCategoriesRepository([
        category('Еда'),
        category('Кафе', parentId: 'Еда'),
        category('Продукты', parentId: 'Еда'),
      ]),
    );

    expect(find.text('Еда'), findsOneComponent);
    expect(find.text('2 подкатегории'), findsOneComponent);
    expect(find.text('Кафе'), findsOneComponent);
    expect(find.byType(GlyphBadge), findsNComponents(3));
    final indented = find.byComponentPredicate(
      (component) => component is GlassListRow && component.indented,
    );
    expect(indented, findsNComponents(2));
  });

  testComponents('the switch shows the other kind, and adding follows it', (
    tester,
  ) async {
    await pump(
      tester,
      FakeCategoriesRepository([
        category('Еда'),
        category('Зарплата', kind: CategoryKind.income),
      ]),
    );
    expect(find.text('Зарплата'), findsNothing);

    await tap(tester, 'Доходы');
    await tester.pump();

    expect(find.text('Зарплата'), findsOneComponent);
    expect(find.text('Еда'), findsNothing);
    expect(links(), contains('add/income'));
  });

  testComponents('the rows are links to their categories', (tester) async {
    await pump(
      tester,
      FakeCategoriesRepository([
        category('Еда'),
        category('Кафе', parentId: 'Еда'),
      ]),
    );

    expect(links(), ['add/expense', 'open/Еда', 'open/Кафе']);
  });

  testComponents('archived categories go to their own section', (tester) async {
    await pump(
      tester,
      FakeCategoriesRepository([
        category('Еда'),
        category('Старая', archived: true),
      ]),
    );

    expect(find.text('Архив'), findsOneComponent);
    expect(links(), contains('open/Старая'));
  });

  testComponents('a failed read offers to try again', (tester) async {
    final repository = FakeCategoriesRepository([category('Еда')])
      ..broken = true;
    await pump(tester, repository);
    expect(find.text('Не удалось прочитать категории.'), findsOneComponent);

    repository.broken = false;
    await tap(tester, 'Повторить');
    await tester.pump();

    expect(find.text('Еда'), findsOneComponent);
  });

  testComponents('an unknown icon from a newer version still draws', (
    tester,
  ) async {
    await pump(
      tester,
      FakeCategoriesRepository([
        const Category(
          id: 'new',
          kind: CategoryKind.expense,
          name: 'Новая',
          archived: false,
          sortOrder: 0,
          icon: 'hologram',
        ),
      ]),
    );

    final badge =
        find.byType(GlyphBadge).evaluate().single.component as GlyphBadge;
    expect(badge.glyph, BirkaGlyph.more);
  });

  testComponents('a note shows once the categories are here', (tester) async {
    await pump(tester, FakeCategoriesRepository(), note: 'В этом браузере');

    expect(find.text('В этом браузере'), findsOneComponent);
  });
}
