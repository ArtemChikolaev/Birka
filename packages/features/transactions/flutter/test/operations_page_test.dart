import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/transactions_flutter.dart';

import 'fake_repository.dart';

void main() {
  const space = '\u00A0';
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final card = testAccount('Карта');
  final cash = testAccount('Наличные');
  final cafe = testCategory('Кафе');
  final food = testCategory('Продукты');
  final salary = testCategory('Зарплата', kind: CategoryKind.income);

  late FakeRepository repository;
  late DateTime now;
  late List<String> opened;
  late List<String> repeated;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: Scaffold(
          body: BlocProvider(
            create: (_) => OperationsCubit(repository, now: () => now),
            child: OperationsPage(onOpen: opened.add, onRepeat: repeated.add),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> swipe(WidgetTester tester, String row) async {
    await tester.drag(find.text(row), const Offset(-300, 0));
    await tester.pumpAndSettle();
  }

  Finder glyph(BirkaGlyph glyph) => find.byWidgetPredicate(
    (widget) => widget is BirkaIcon && widget.glyph == glyph,
  );

  setUp(() {
    now = DateTime(2026, 10, 31, 9, 30);
    repository = FakeRepository(
      accountList: [card, cash],
      operations: [
        testOperation(
          'coffee',
          amount: rub(-25000),
          account: card,
          category: cafe,
          note: 'Кофейня у дома',
        ),
        testOperation(
          'bread',
          amount: rub(-13000),
          account: cash,
          category: food,
        ),
        testOperation(
          'pay',
          amount: rub(10000000),
          account: card,
          category: salary,
          day: CivilDate(2026, 10, 30),
        ),
        testOperation(
          'move',
          amount: rub(-500000),
          account: card,
          toAccount: cash,
          kind: TransactionKind.transfer,
          day: CivilDate(2026, 10, 3),
        ),
        testOperation(
          'old',
          amount: rub(-100),
          account: card,
          category: food,
          day: CivilDate(2026, 9, 15),
          note: 'Сентябрь',
        ),
      ],
    );
    opened = [];
    repeated = [];
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('shows the month day by day with its totals', (tester) async {
    await pump(tester);

    expect(find.text('Октябрь'), findsOneWidget);
    expect(find.text('СЕГОДНЯ'), findsOneWidget);
    expect(find.text('ВЧЕРА'), findsOneWidget);
    expect(find.text('3 ОКТЯБРЯ'), findsOneWidget);
    expect(find.text('−380$space₽'), findsOneWidget);
    expect(find.text('Кофейня у дома'), findsOneWidget);
    expect(find.text('Кафе · Карта'), findsOneWidget);
    expect(find.text('Продукты'), findsOneWidget);
    expect(find.text('Наличные'), findsOneWidget);
    expect(find.text('Перевод'), findsOneWidget);
    expect(find.text('Карта → Наличные'), findsOneWidget);
    expect(find.textContaining('−380$space₽'), findsWidgets);
    expect(find.textContaining('+100${space}000$space₽'), findsWidgets);
    expect(find.text('Сентябрь'), findsNothing);
  });

  testWidgets('a row opens its operation', (tester) async {
    await pump(tester);

    await tapText(tester, 'Кофейня у дома');

    expect(opened, ['coffee']);
  });

  testWidgets('a filter narrows the list', (tester) async {
    await pump(tester);

    await tester.ensureVisible(find.text('Переводы'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Переводы');

    expect(find.text('Карта → Наличные'), findsOneWidget);
    expect(find.text('Кофейня у дома'), findsNothing);
  });

  testWidgets('the search narrows it, and the cross brings it back', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'кофей');
    await tester.pumpAndSettle();
    expect(find.text('Кофейня у дома'), findsOneWidget);
    expect(find.text('Продукты'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Очистить поиск'));
    await tester.pumpAndSettle();
    expect(find.text('Продукты'), findsOneWidget);
  });

  testWidgets('says when nothing is found', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'такси');
    await tester.pumpAndSettle();

    expect(find.text('Ничего не нашлось'), findsOneWidget);
    expect(find.text('Пока нет операций'), findsNothing);
  });

  testWidgets('an empty month says so', (tester) async {
    repository.operations = const [];
    await pump(tester);

    expect(find.text('Пока нет операций'), findsOneWidget);
    expect(find.text('Ничего не нашлось'), findsNothing);
  });

  testWidgets('another month can be picked', (tester) async {
    repository.monthList = [CivilDate(2026, 10, 1), CivilDate(2026, 9, 1)];
    await pump(tester);

    await tapText(tester, 'Октябрь');
    await tapText(tester, 'Сентябрь');

    expect(find.text('Сентябрь'), findsWidgets);
    expect(find.text('Кофейня у дома'), findsNothing);
    expect(find.text('Сентябрь'), findsNWidgets(2));
  });

  testWidgets('a month of another year says which', (tester) async {
    repository.monthList = [CivilDate(2025, 12, 1)];
    await pump(tester);

    await tapText(tester, 'Октябрь');

    expect(find.text('Декабрь 2025'), findsOneWidget);
  });

  testWidgets('coming back on the next day finds the new month', (
    tester,
  ) async {
    await pump(tester);

    now = DateTime(2026, 11, 1, 8);
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Ноябрь'), findsOneWidget);
    expect(find.text('Пока нет операций'), findsOneWidget);
  });

  testWidgets('a swipe offers to repeat', (tester) async {
    await pump(tester);

    await swipe(tester, 'Кофейня у дома');
    await tester.tap(glyph(BirkaGlyph.copy).first);
    await tester.pumpAndSettle();

    expect(repeated, ['coffee']);
  });

  testWidgets('a swipe offers to delete, and asks first', (tester) async {
    await pump(tester);

    await swipe(tester, 'Кофейня у дома');
    await tester.tap(glyph(BirkaGlyph.trash).first);
    await tester.pumpAndSettle();
    expect(find.text('Удалить операцию?'), findsOneWidget);

    await tapText(tester, 'ОТМЕНА');
    expect(repository.operations, hasLength(5));

    await swipe(tester, 'Кофейня у дома');
    await tester.tap(glyph(BirkaGlyph.trash).first);
    await tester.pumpAndSettle();
    await tapText(tester, 'УДАЛИТЬ');

    expect(repository.operations, hasLength(4));
    expect(find.text('Кофейня у дома'), findsNothing);
  });

  testWidgets('a failed delete says so', (tester) async {
    await pump(tester);
    repository.failure = Exception('disk full');

    await swipe(tester, 'Кофейня у дома');
    await tester.tap(glyph(BirkaGlyph.trash).first);
    await tester.pumpAndSettle();
    await tapText(tester, 'УДАЛИТЬ');

    expect(
      find.text('Не удалось удалить. Попробуйте ещё раз.'),
      findsOneWidget,
    );
    expect(find.text('Кофейня у дома'), findsOneWidget);
  });

  testWidgets('a failure offers another try', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester);

    expect(find.text('Не удалось прочитать операции.'), findsOneWidget);

    repository.readFailure = null;
    await tapText(tester, 'ПОВТОРИТЬ');

    expect(find.text('Кофейня у дома'), findsOneWidget);
  });

  testWidgets('a correction has no way to repeat it', (tester) async {
    repository.operations = [
      testOperation(
        'fix',
        amount: rub(5000),
        account: card,
        kind: TransactionKind.adjustment,
      ),
    ];
    await pump(tester);

    expect(find.text('Корректировка'), findsOneWidget);
    expect(glyph(BirkaGlyph.check), findsOneWidget);
    expect(glyph(BirkaGlyph.copy), findsNothing);
    expect(glyph(BirkaGlyph.trash), findsOneWidget);
  });

  testWidgets('the largest amounts shrink to fit their rows', (tester) async {
    final most = Money(Money.maxMinorUnits, Currency.rub);
    repository.operations = [
      testOperation(
        'a',
        amount: -most,
        account: card,
        note:
            'Очень длинная '
            'заметка об операции, которая не влезает в одну строку',
      ),
      testOperation('b', amount: most, account: card),
      testOperation('c', amount: Money(-100, Currency.eur), account: card),
      testOperation('d', amount: Money(-100, Currency.usd), account: card),
    ];
    await pump(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a long list under the bar', (tester) async {
    repository.operations = [
      for (var i = 0; i < 40; i++)
        testOperation(
          'row$i',
          amount: rub(-100),
          account: card,
          note: 'Строка $i',
          day: CivilDate(2026, 10, 1 + i % 28),
        ),
    ];
    await pump(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -4000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
