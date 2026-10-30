import 'package:categories_common/categories_common.dart';
import 'package:categories_flutter/categories_flutter.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'fake_categories_repository.dart';

void main() {
  final opened = <String>[];
  final addedKinds = <CategoryKind>[];
  var left = 0;

  Future<void> pump(
    WidgetTester tester,
    FakeCategoriesRepository repository,
  ) async {
    tester.view.physicalSize = const Size(780, 1800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider(
          create: (_) => CategoriesCubit(repository),
          child: CategoriesPage(
            onBack: () => left++,
            onAdd: addedKinds.add,
            onOpen: opened.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    opened.clear();
    addedKinds.clear();
    left = 0;
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('without categories it offers the ready set', (tester) async {
    final repository = FakeCategoriesRepository();
    await pump(tester, repository);

    expect(find.text('Пока нет категорий'), findsOneWidget);
    await tester.tap(find.text('ДОБАВИТЬ ГОТОВЫЙ НАБОР'));
    await tester.pump();

    expect(repository.added, hasLength(categoryPresets.length));
    expect(repository.added.first.name, 'Продукты');
  });

  testWidgets('without categories it also lets you make your own', (
    tester,
  ) async {
    await pump(tester, FakeCategoriesRepository());
    await tester.tap(find.text('СОЗДАТЬ СВОЮ'));
    expect(addedKinds, [CategoryKind.expense]);
  });

  testWidgets('shows subcategories under their parent with their number', (
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

    expect(find.text('Еда'), findsOneWidget);
    expect(find.text('2 подкатегории'), findsOneWidget);
    expect(find.text('Кафе'), findsOneWidget);
    expect(find.byType(GlyphBadge), findsNWidgets(3));
  });

  testWidgets('the switch shows the other kind, and adding follows it', (
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

    await tester.tap(find.text('ДОХОДЫ'));
    await tester.pumpAndSettle();
    expect(find.text('Зарплата'), findsOneWidget);
    expect(find.text('Еда'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Добавить категорию'));
    expect(addedKinds, [CategoryKind.income]);
  });

  testWidgets('rows open their categories, and the back button leaves', (
    tester,
  ) async {
    await pump(
      tester,
      FakeCategoriesRepository([
        category('Еда'),
        category('Кафе', parentId: 'Еда'),
      ]),
    );

    await tester.tap(find.text('Кафе'));
    await tester.tap(find.text('Еда'));
    await tester.tap(find.bySemanticsLabel('Назад'));

    expect(opened, ['Кафе', 'Еда']);
    expect(left, 1);
  });

  testWidgets('archived categories go to their own section', (tester) async {
    await pump(
      tester,
      FakeCategoriesRepository([
        category('Еда'),
        category('Старая', archived: true),
      ]),
    );

    expect(find.text('АРХИВ'), findsOneWidget);
    await tester.tap(find.text('Старая'));
    expect(opened, ['Старая']);
  });

  testWidgets('a failed read offers to try again', (tester) async {
    final repository = FakeCategoriesRepository([category('Еда')])
      ..broken = true;
    await pump(tester, repository);
    expect(find.text('Не удалось прочитать категории.'), findsOneWidget);

    repository.broken = false;
    await tester.tap(find.text('ПОВТОРИТЬ'));
    await tester.pumpAndSettle();
    expect(find.text('Еда'), findsOneWidget);
  });

  testWidgets('an unknown icon from a newer version still draws', (
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

    final badge = tester.widget<GlyphBadge>(find.byType(GlyphBadge));
    expect(badge.glyph, BirkaGlyph.more);
  });
}
