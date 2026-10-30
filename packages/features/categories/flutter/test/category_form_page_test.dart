import 'package:categories_common/categories_common.dart';
import 'package:categories_flutter/categories_flutter.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'fake_categories_repository.dart';

void main() {
  late FakeCategoriesRepository repository;
  var closed = 0;

  Future<void> pump(
    WidgetTester tester, {
    String? categoryId,
    CategoryKind kind = CategoryKind.expense,
  }) async {
    tester.view.physicalSize = const Size(780, 2200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider(
          create: (_) => CategoryFormCubit(
            repository,
            categoryId: categoryId,
            kind: kind,
          ),
          child: CategoryFormPage(onClose: () => closed++),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> typeName(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
  }

  setUp(() {
    repository = FakeCategoriesRepository();
    closed = 0;
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('saves a new category with its look and closes', (tester) async {
    await pump(tester);

    await typeName(tester, 'Кафе');
    await tester.tap(find.bySemanticsLabel('cup'));
    await tester.tap(
      find.bySemanticsLabel('Цвет ${categoryColors[1].substring(1)}'),
    );
    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pumpAndSettle();

    final draft = repository.added.single;
    expect(draft.name, 'Кафе');
    expect(draft.icon, 'cup');
    expect(draft.color, categoryColors[1]);
    expect(closed, 1);
  });

  testWidgets('says that the name is missing and stays open', (tester) async {
    await pump(tester);

    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pumpAndSettle();

    expect(find.text('Дайте категории название.'), findsOneWidget);
    expect(closed, 0);
  });

  testWidgets('the badge follows the picked look', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('gift'));
    await tester.pump();

    final badge = tester.widget<GlyphBadge>(find.byType(GlyphBadge).first);
    expect(badge.glyph, BirkaGlyph.gift);
  });

  testWidgets('starts on the kind it was opened with, and can change', (
    tester,
  ) async {
    await pump(tester, kind: CategoryKind.income);

    await typeName(tester, 'Премия');
    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pumpAndSettle();
    expect(repository.added.single.kind, CategoryKind.income);
  });

  testWidgets('offers to go inside another category', (tester) async {
    repository = FakeCategoriesRepository([category('Еда')]);
    await pump(tester);

    await typeName(tester, 'Кафе');
    await tester.tap(find.text('Еда'));
    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pumpAndSettle();

    expect(repository.added.single.parentId, 'Еда');
  });

  testWidgets('hides the choice of a parent when there are none', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Внутри'), findsNothing);
  });

  group('an existing category', () {
    setUp(() {
      repository = FakeCategoriesRepository([
        category('Еда'),
        category('Кафе', parentId: 'Еда'),
      ]);
    });

    testWidgets('fills in the form and fixes its kind', (tester) async {
      await pump(tester, categoryId: 'Кафе');

      expect(find.text('Категория'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, 'Кафе');
      expect(find.text('ДОХОДЫ'), findsNothing);
    });

    testWidgets('can be moved to the archive', (tester) async {
      await pump(tester, categoryId: 'Кафе');

      await tester.tap(find.text('Убрать в архив'));
      await tester.pumpAndSettle();

      expect(repository.archived, {'Кафе': true});
      expect(closed, 1);
    });

    testWidgets('offers to come back from the archive', (tester) async {
      repository.categories = [category('Старая', archived: true)];
      await pump(tester, categoryId: 'Старая');

      await tester.tap(find.text('Вернуть из архива'));
      await tester.pumpAndSettle();

      expect(repository.archived, {'Старая': false});
    });
  });

  testWidgets('the cross closes without saving', (tester) async {
    await pump(tester);
    await tester.tap(find.bySemanticsLabel('Закрыть'));
    expect(closed, 1);
    expect(repository.added, isEmpty);
  });
}
