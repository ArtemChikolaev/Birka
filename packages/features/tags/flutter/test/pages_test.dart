import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:tags_common/tags_common.dart';
import 'package:tags_common/testing.dart';
import 'package:tags_flutter/tags_flutter.dart';

Widget phone<C extends StateStreamableSource<Object?>>(
  C cubit,
  Widget child,
) => MaterialApp(
  theme: BirkaTheme.dark(),
  home: BlocProvider<C>.value(value: cubit, child: child),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('the list of метки', () {
    testWidgets('puts the trip of today first and opens a метка', (
      tester,
    ) async {
      final opened = <String>[];
      final cubit = TagsCubit(FakeTagsRepository());
      addTearDown(cubit.close);
      await tester.pumpWidget(
        phone(
          cubit,
          TagsPage(onBack: () {}, onAdd: () {}, onOpen: opened.add),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('СЕЙЧАС'), findsOneWidget);
      expect(find.text('ПОЕЗДКИ'), findsOneWidget);
      expect(find.text('Тбилиси'), findsOneWidget);
      expect(find.text('Последний день'), findsOneWidget);
      expect(find.text(nb('62 015 ₽')), findsOneWidget);
      expect(find.text('2–9 мая'), findsOneWidget);
      expect(find.text('1 операция'), findsOneWidget);

      await tester.tap(find.text('Тбилиси'));

      expect(opened, ['tbilisi']);
    });

    testWidgets('offers the first метка when there is none', (tester) async {
      var added = 0;
      final cubit = TagsCubit(FakeTagsRepository(tags: [], operations: []));
      addTearDown(cubit.close);
      await tester.pumpWidget(
        phone(
          cubit,
          TagsPage(onBack: () {}, onAdd: () => added++, onOpen: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Меток пока нет'), findsOneWidget);

      await tester.tap(find.widgetWithText(BirkaButton, 'НОВАЯ МЕТКА'));

      expect(added, 1);
    });
  });

  testWidgets('the report of a trip counts it in every currency', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = TagReportCubit(FakeTagsRepository(), 'tbilisi');
    addTearDown(cubit.close);
    await tester.pumpWidget(
      phone(
        cubit,
        TagReportPage(
          onBack: () {},
          onEdit: () {},
          operations: const Text('the operations of the host'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ПОЕЗДКА'), findsOneWidget);
    expect(find.text(nb('62 015 ₽')), findsOneWidget);
    expect(find.text('3–12 ноября · сегодня последний день'), findsOneWidget);
    expect(find.text('На месте в день'), findsOneWidget);
    expect(find.text('≈ ${nb('13 GEL')}'), findsOneWidget);
    expect(find.text('2 там, 2 заранее'), findsOneWidget);
    expect(find.text('Доллары'), findsOneWidget);
    expect(find.text('2 операции на месте'), findsOneWidget);
    expect(find.text('Квартира в Сололаки, 20 октября'), findsOneWidget);
    expect(find.text('94%'), findsOneWidget);
    expect(find.text('6%'), findsOneWidget);
    expect(find.text('the operations of the host'), findsOneWidget);
  });

  group('the form of a метка', () {
    Future<List<TagMarking?>> pump(
      WidgetTester tester,
      TagFormCubit cubit,
    ) async {
      final closed = <TagMarking?>[];
      await tester.pumpWidget(phone(cubit, TagFormPage(onClose: closed.add)));
      await tester.pumpAndSettle();
      return closed;
    }

    testWidgets('of a trip in the past says how many expenses it marks', (
      tester,
    ) async {
      final cubit = TagFormCubit(
        FakeTagsRepository()..toMark = 14,
        name: 'Казань',
      );
      addTearDown(cubit.close);
      final closed = await pump(tester, cubit);

      expect(find.text('Новая метка'), findsOneWidget);
      expect(find.text('Казань'), findsOneWidget);
      expect(
        find.textContaining('За эти дни уже 14 расходов'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(BirkaButton, 'СОХРАНИТЬ'));
      await tester.pumpAndSettle();

      expect(closed.single?.marked, 14);
      expect(find.text('Отметили 14 расходов: «Казань»'), findsOneWidget);
      expect(find.text('Вернуть'), findsOneWidget);
    });

    testWidgets('of a метка without days speaks of putting it on by hand', (
      tester,
    ) async {
      final cubit = TagFormCubit(FakeTagsRepository(), name: 'Новый год');
      addTearDown(cubit.close);
      final closed = await pump(tester, cubit);

      await tester.tap(find.text('МЕТКА'));
      await tester.pumpAndSettle();

      expect(find.text('Даты'), findsNothing);
      expect(find.textContaining('Метку ставите сами'), findsOneWidget);

      await tester.tap(find.widgetWithText(BirkaButton, 'СОХРАНИТЬ'));
      await tester.pumpAndSettle();

      expect(closed.single?.tag.days, isNull);
      expect(find.text('Добавили метку «Новый год»'), findsOneWidget);
    });

    testWidgets('needs a name', (tester) async {
      final cubit = TagFormCubit(FakeTagsRepository());
      addTearDown(cubit.close);
      final closed = await pump(tester, cubit);

      await tester.tap(find.widgetWithText(BirkaButton, 'СОХРАНИТЬ'));
      await tester.pumpAndSettle();

      expect(find.text('Дайте метке название.'), findsOneWidget);
      expect(closed, isEmpty);
    });
  });

  test('a trip of the board marks its days', () {
    expect(
      tbilisi.marks(
        kind: TransactionKind.expense,
        source: TransactionSource.manual,
        day: boardToday,
      ),
      isTrue,
    );
  });
}
