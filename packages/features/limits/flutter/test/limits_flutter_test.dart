import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:limits_common/limits_common.dart';
import 'package:limits_common/testing.dart';
import 'package:limits_flutter/limits_flutter.dart';

void main() {
  late MemoryLimitsRepository repository;

  setUp(() {
    repository = MemoryLimitsRepository();
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  /// A text of the screen, read with plain spaces for the no-break ones.
  Finder words(String text) => find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        (widget.data ?? widget.textSpan?.toPlainText())?.replaceAll(
              ' ',
              ' ',
            ) ==
            text,
  );

  Future<void> show(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: BirkaTheme.dark(), home: child),
    );
    await tester.pumpAndSettle();
  }

  group('the page', () {
    final opened = <String>[];
    final added = <String?>[];
    var suggested = 0;

    setUp(() {
      opened.clear();
      added.clear();
      suggested = 0;
    });

    Widget page() => BlocProvider(
      create: (_) => LimitsCubit(repository),
      child: LimitsPage(
        onBack: () {},
        onAdd: added.add,
        onOpen: opened.add,
        onSuggest: () => suggested++,
      ),
    );

    testWidgets('shows what is left of each limit, over first', (
      tester,
    ) async {
      await show(tester, page());
      expect(words('4 из 5'), findsOneWidget);
      expect(words('1 превышен'), findsOneWidget);
      expect(words('13 дней'), findsOneWidget);
      expect(words('с 1 декабря заново'), findsOneWidget);
      expect(words('больше на 1 300 ₽'), findsOneWidget);
      expect(words('осталось 1 850 ₽'), findsOneWidget);
      expect(words('В таком темпе хватит до 21 ноября'), findsOneWidget);
      await tester.tap(find.text('Кафе'));
      expect(opened, ['cafe']);
    });

    testWidgets('sets a limit on a category without one', (tester) async {
      await show(tester, page());
      await tester.scrollUntilVisible(words('6 400 ₽ в ноябре'), 200);
      expect(words('1 997 ₽ · регулярные платежи'), findsOneWidget);
      await tester.tap(find.text('ПОСТАВИТЬ').first);
      expect(added, ['home']);
      await tester.scrollUntilVisible(find.text('Предложить по средним'), 200);
      await tester.tap(find.text('Предложить по средним'));
      expect(suggested, 1);
    });

    testWidgets('a ledger without limits offers them', (tester) async {
      repository.categories = [
        for (final category in boardCategories) withLimit(category, null),
      ];
      await show(tester, page());
      expect(find.text('Лимитов пока нет'), findsOneWidget);
      await tester.tap(find.text('ПРЕДЛОЖИТЬ ПО СРЕДНИМ'));
      expect(suggested, 1);
      await tester.tap(find.text('ПОСТАВИТЬ ВРУЧНУЮ'));
      expect(added, [null]);
    });
  });

  group('the part of the overview', () {
    var opened = 0;
    var suggested = 0;

    setUp(() {
      opened = 0;
      suggested = 0;
    });

    Widget part() => Scaffold(
      body: BlocProvider(
        create: (_) => LimitsCubit(repository),
        child: LimitsOverviewPart(
          onOpen: () => opened++,
          onSuggest: () => suggested++,
        ),
      ),
    );

    testWidgets('shows the three limits that need the person most', (
      tester,
    ) async {
      await show(tester, part());
      expect(find.text('ЛИМИТЫ НА НОЯБРЬ'), findsOneWidget);
      expect(words('превышен 1 · 13 дней'), findsOneWidget);
      expect(find.text('Досуг'), findsOneWidget);
      expect(find.text('Кафе'), findsOneWidget);
      expect(find.text('Поездки'), findsOneWidget);
      expect(find.text('Продукты'), findsNothing);
      expect(
        words('осталось 1 850 ₽ · хватит примерно до 21 ноября'),
        findsOneWidget,
      );
      await tester.tap(find.text('Все лимиты · 5'));
      expect(opened, 1);
    });

    testWidgets('draws its line only once the limits are counted', (
      tester,
    ) async {
      Finder line() => find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox && widget.color == BirkaColors.dark.hairline,
      );
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(theme: BirkaTheme.dark(), home: part()),
      );
      // The limits are still being counted: the card ends with the spending.
      expect(line(), findsNothing);
      await tester.pumpAndSettle();
      expect(line(), findsOneWidget);
      expect(find.text('ЛИМИТЫ НА НОЯБРЬ'), findsOneWidget);
    });

    testWidgets('invites to set limits while there are none', (tester) async {
      repository.categories = [
        for (final category in boardCategories) withLimit(category, null),
      ];
      await show(tester, part());
      await tester.tap(find.text('Предложить по средним тратам'));
      expect(suggested, 1);
    });
  });

  group('the form', () {
    var closed = 0;

    setUp(() => closed = 0);

    Widget form({String? categoryId}) => BlocProvider(
      create: (_) => LimitFormCubit(repository, categoryId: categoryId),
      child: LimitFormPage(onClose: () => closed++),
    );

    testWidgets('takes the average, moves it to euros and saves it', (
      tester,
    ) async {
      await show(tester, form());
      expect(find.text('Новый лимит'), findsOneWidget);
      expect(find.text('Не задана'), findsOneWidget);
      await tester.tap(words('Взять 6 500 ₽'));
      await tester.pumpAndSettle();
      expect(words('6 500 ₽'), findsOneWidget);
      expect(find.text('округлили вверх'), findsOneWidget);
      await tester.tap(find.text('Евро'));
      await tester.pumpAndSettle();
      expect(words('70 €'), findsOneWidget);
      await tester.tap(find.text('СОХРАНИТЬ'));
      await tester.pumpAndSettle();
      expect(words('Лимит на «Дом» — 70 € в месяц'), findsOneWidget);
      expect(closed, 1);
      expect(repository.setLimits.single.$1, 'home');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('a set limit shows its month and can go', (tester) async {
      await show(tester, form(categoryId: 'cafe'));
      expect(find.text('Лимит на «Кафе»'), findsOneWidget);
      expect(words('В ноябре — 10 150 ₽ из 12 000 ₽'), findsOneWidget);
      expect(find.text('как сейчас'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('УБРАТЬ ЛИМИТ'), 200);
      await tester.tap(find.text('УБРАТЬ ЛИМИТ'));
      await tester.pumpAndSettle();
      expect(find.text('Лимит на «Кафе» убрали'), findsOneWidget);
      expect(repository.setLimits, [('cafe', null)]);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('the limits offered from averages', () {
    var closed = 0;

    setUp(() {
      closed = 0;
      repository.categories = [
        for (final category in boardCategories)
          if (category.id != travel.id) withLimit(category, null),
      ];
    });

    Widget sheet() => BlocProvider(
      create: (_) => LimitSuggestCubit(repository),
      child: LimitSuggestPage(onClose: () => closed++, onManual: () {}),
    );

    testWidgets('checks the steady ones and sets the checked', (tester) async {
      await show(tester, sheet());
      expect(find.text('ПОСТАВИТЬ 4 ЛИМИТА'), findsOneWidget);
      expect(words('скачут: от 2 100 ₽ до 11 400 ₽'), findsOneWidget);
      await tester.tap(find.text('Дом'));
      await tester.pumpAndSettle();
      expect(find.text('ПОСТАВИТЬ 5 ЛИМИТОВ'), findsOneWidget);
      await tester.tap(find.text('ПОСТАВИТЬ 5 ЛИМИТОВ'));
      await tester.pumpAndSettle();
      expect(find.text('Поставили 5 лимитов на ноябрь'), findsOneWidget);
      expect(closed, 1);
      expect(repository.setLimits, hasLength(5));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('waits for a full month', (tester) async {
      repository.spending = [
        for (final row in boardSpending)
          if (row.day.month == 11) row,
      ];
      await show(tester, sheet());
      expect(find.text('Пока мало истории'), findsOneWidget);
      expect(find.text('ПОСТАВИТЬ ВРУЧНУЮ'), findsOneWidget);
    });
  });
}
