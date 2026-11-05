import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:inbox_flutter/inbox_flutter.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

import 'fakes.dart';

void main() {
  late FakeSettingsStore store;
  var imports = 0;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    store = FakeSettingsStore();
    imports = 0;
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Future<FakeInboxRepository> pump(
    WidgetTester tester, [
    FakeInboxRepository? repository,
    CategoryMaker? onNewCategory,
  ]) async {
    tester.view.physicalSize = const Size(780, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final ledger = repository ?? october();
    final cubit = InboxCubit(ledger, DismissedPairs(store));
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider.value(
          value: cubit,
          child: InboxPage(
            onBack: () {},
            onImport: () => imports++,
            onNewCategory: onNewCategory,
            clock: () => DateTime(2026, 11, 4),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ledger;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  testWidgets('shows what waits after which import, with hints', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('3 ждут решения'), findsOneWidget);
    expect(find.text('После импорта Альфа-Банка'), findsOneWidget);
    expect(find.text('Похоже на перевод между вашими счетами'), findsOneWidget);
    expect(find.text('Пополнение с Wise · из выписки'), findsOneWidget);
    expect(find.text('БЕЗ КАТЕГОРИИ · 2'), findsOneWidget);
    expect(find.text('ИП Соколов А. В.'), findsOneWidget);
    expect(find.text('Кафе ?'), findsOneWidget);
    expect(
      find.text('так вы отметили его 3 раза в сентябре'),
      findsOneWidget,
    );
    expect(find.text('Перевод Ивану К.'), findsOneWidget);
  });

  testWidgets('a yes gives the hinted category and says so', (tester) async {
    final ledger = await pump(tester);

    await tapText(tester, 'ДА');

    expect(ledger.categorized, [('soko', 'cafe')]);
    expect(find.text('Кафе: дальше Birka поставит сама'), findsOneWidget);
  });

  testWidgets('another category comes from a sheet with the hint marked', (
    tester,
  ) async {
    final ledger = await pump(tester);

    await tapText(tester, 'Другая');

    expect(find.text('Категория для «ИП Соколов А. В.»'), findsOneWidget);
    expect(find.text('подсказка'), findsOneWidget);
    await tapText(tester, 'Покупки');

    expect(ledger.categorized, [('soko', 'shop')]);
    expect(find.text('Покупки · 1 операция'), findsOneWidget);
  });

  testWidgets('the picked get one category together', (tester) async {
    final ledger = await pump(tester);

    await tester.ensureVisible(find.text('Перевод Ивану К.'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Выбрать «Перевод Ивану К.»'));
    await tester.pumpAndSettle();

    expect(find.text('Выбрана 1 операция'), findsOneWidget);
    await tapText(tester, 'КАТЕГОРИЯ');
    expect(find.text('Категория для выбранных'), findsOneWidget);
    await tapText(tester, 'Покупки');

    expect(ledger.categorized, [('ivan', 'shop')]);
  });

  group('a new category', () {
    late List<CategoryKind> asked;

    CategoryMaker maker({CategoryKind? kind}) => (wanted) async {
      asked.add(wanted);
      return Category(
        id: 'gifts',
        kind: kind ?? wanted,
        name: 'Подарки',
        archived: false,
        sortOrder: 9,
      );
    };

    setUp(() => asked = []);

    testWidgets('is made from the sheet of a row and goes to it', (
      tester,
    ) async {
      final ledger = await pump(tester, null, maker());

      await tapText(tester, 'Другая');
      await tapText(tester, 'Новая категория');

      expect(asked, [CategoryKind.expense]);
      expect(ledger.categorized, [('soko', 'gifts')]);
      expect(find.text('Подарки · 1 операция'), findsOneWidget);
    });

    testWidgets('goes to the picked of its kind', (tester) async {
      final ledger = await pump(tester, null, maker());

      await tester.ensureVisible(find.text('Перевод Ивану К.'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Выбрать «Перевод Ивану К.»'));
      await tester.pumpAndSettle();
      await tapText(tester, 'КАТЕГОРИЯ');
      await tapText(tester, 'Новая категория');

      expect(ledger.categorized, [('ivan', 'gifts')]);
      expect(find.text('Подарки · 1 операция'), findsOneWidget);
    });

    testWidgets('of the other kind leaves the operation as it was', (
      tester,
    ) async {
      final ledger = await pump(
        tester,
        null,
        maker(kind: CategoryKind.income),
      );

      await tapText(tester, 'Другая');
      await tapText(tester, 'Новая категория');

      expect(ledger.categorized, isEmpty);
      expect(find.text('ИП Соколов А. В.'), findsOneWidget);
    });

    testWidgets('is not offered when nothing can make one', (tester) async {
      await pump(tester);

      await tapText(tester, 'Другая');

      expect(find.text('Покупки'), findsOneWidget);
      expect(find.text('Новая категория'), findsNothing);
    });
  });

  testWidgets('a pair becomes a transfer with a word', (tester) async {
    final ledger = await pump(tester);

    await tapText(tester, 'СДЕЛАТЬ ПЕРЕВОДОМ');

    expect(ledger.transfers, hasLength(1));
    expect(find.text('Сделали перевод'), findsOneWidget);
  });

  testWidgets('a pair kept apart stays income', (tester) async {
    await pump(tester);

    await tapText(tester, 'ЭТО ДОХОД');

    expect(store.values[DismissedPairs.key], isNotEmpty);
    expect(find.text('Оставили доходом'), findsOneWidget);
    expect(find.text('Похоже на перевод между вашими счетами'), findsNothing);
  });

  testWidgets('another filter changes the list at once', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Без категории, 2'));
    await tester.pump();

    expect(find.text('Похоже на перевод между вашими счетами'), findsNothing);
    expect(find.text('ИП Соколов А. В.'), findsOneWidget);
  });

  testWidgets('says when everything is sorted and offers a statement', (
    tester,
  ) async {
    await pump(tester, FakeInboxRepository());

    expect(find.text('Всё разобрано'), findsOneWidget);
    await tapText(tester, 'ЗАГРУЗИТЬ ВЫПИСКУ');

    expect(imports, 1);
  });
}
