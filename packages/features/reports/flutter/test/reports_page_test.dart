import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:reports_common/reports_common.dart';
import 'package:reports_flutter/reports_flutter.dart';

final class _FakeRepository implements ReportsRepository {
  Currency? main = Currency.rub;
  final rows = <(CategoryKind, CivilDate), List<CategoryTotal>>{};
  final totals = <CategoryKind, List<MonthTotal>>{};
  List<CivilDate> monthList = const [];
  Exception? readFailure;

  Stream<T> _read<T>(T value) => Stream.multi((controller) {
    if (readFailure case final failure?) {
      controller.addError(failure);
    } else {
      controller.add(value);
    }
  });

  @override
  Stream<Currency?> watchMainCurrency() => _read(main);

  @override
  Stream<List<CategoryTotal>> watchTotals(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  }) => _read(rows[(kind, from)] ?? const []);

  @override
  Stream<List<MonthTotal>> watchMonthTotals(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  }) => _read(totals[kind] ?? const []);

  @override
  Future<List<CivilDate>> months() async => monthList;
}

CategoryTotal _total(
  String name,
  Money total, {
  CategoryKind kind = CategoryKind.expense,
}) => CategoryTotal(
  Category(
    id: name,
    kind: kind,
    name: name,
    archived: false,
    sortOrder: 0,
    color: '#4ade80',
  ),
  total,
);

void main() {
  const space = ' ';
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final october = CivilDate(2026, 10, 1);
  final september = CivilDate(2026, 9, 1);

  late _FakeRepository repository;
  late DateTime now;
  late ValueNotifier<bool> hidden;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 2800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      HiddenAmounts(
        notifier: hidden,
        child: MaterialApp(
          theme: BirkaTheme.dark(),
          home: Scaffold(
            body: BlocProvider(
              create: (_) => ReportsCubit(repository, now: () => now),
              child: const ReportsPage(),
            ),
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

  Color colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.color!;

  setUp(() {
    now = DateTime(2026, 10, 31, 9, 30);
    hidden = ValueNotifier(false);
    repository = _FakeRepository();
    repository.rows[(CategoryKind.expense, october)] = [
      _total('Продукты', rub(2430000)),
      _total('Кафе', rub(1285000)),
    ];
    repository.rows[(CategoryKind.expense, september)] = [
      _total('Продукты', rub(2531250)),
      _total('Кафе', rub(951900)),
    ];
    repository.rows[(CategoryKind.income, october)] = [
      _total('Зарплата', rub(21000000), kind: CategoryKind.income),
    ];
    repository.rows[(CategoryKind.income, september)] = [
      _total('Зарплата', rub(20000000), kind: CategoryKind.income),
    ];
    repository.totals[CategoryKind.expense] = [
      MonthTotal(september, rub(3483150)),
      MonthTotal(october, rub(3715000)),
    ];
    repository.monthList = [october, september];
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    hidden.dispose();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('shows the month with the change against the last one', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Отчёты'), findsOneWidget);
    expect(find.text('Октябрь'), findsOneWidget);
    expect(find.byType(BirkaRing), findsOneWidget);
    expect(find.text('37${space}150$space₽'), findsOneWidget);
    expect(find.text('+7% к сентябрю'), findsOneWidget);
  });

  testWidgets('shows each category with its change and its bar', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Продукты'), findsOneWidget);
    expect(find.text('24${space}300$space₽'), findsOneWidget);
    expect(find.text('−4%'), findsOneWidget);
    expect(find.text('Кафе'), findsOneWidget);
    expect(find.text('+35%'), findsOneWidget);
    final bars = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .map((bar) => bar.widthFactor!)
        .toList();
    expect(bars.first, 1);
    expect(bars.last, closeTo(0.53, 0.01));
  });

  testWidgets('more expenses read as bad news', (tester) async {
    await pump(tester);

    expect(colorOf(tester, '+35%'), BirkaColors.dark.negative);
    expect(colorOf(tester, '−4%'), BirkaColors.dark.positive);
  });

  testWidgets('more income reads as good news', (tester) async {
    await pump(tester);

    await tapText(tester, 'ДОХОДЫ');

    expect(find.text('Зарплата'), findsOneWidget);
    expect(colorOf(tester, '+5%'), BirkaColors.dark.positive);
  });

  testWidgets('shows the last months with their average', (tester) async {
    await pump(tester);

    expect(find.text('ПО МЕСЯЦАМ'), findsOneWidget);
    expect(find.text('в среднем 36$spaceтыс.$space₽'), findsOneWidget);
    expect(find.text('Май'), findsOneWidget);
    expect(find.text('Окт'), findsOneWidget);
    expect(find.text('37k'), findsOneWidget);
    final bars = tester.widget<BirkaBars>(find.byType(BirkaBars)).bars;
    expect(bars, hasLength(6));
    expect(bars.last.highlighted, isTrue);
    expect(bars.first.highlighted, isFalse);
  });

  testWidgets('another month can be picked', (tester) async {
    await pump(tester);

    await tapText(tester, 'Октябрь');
    await tapText(tester, 'Сентябрь');

    expect(find.text('34${space}831,50$space₽'), findsOneWidget);
  });

  testWidgets('a month of another year says which', (tester) async {
    repository.monthList = [CivilDate(2025, 12, 1)];
    await pump(tester);

    await tapText(tester, 'Октябрь');

    expect(find.text('Декабрь 2025'), findsOneWidget);
  });

  testWidgets('a month with nothing says so and keeps the bars', (
    tester,
  ) async {
    now = DateTime(2026, 11, 15);
    await pump(tester);

    expect(find.text('В этом месяце расходов нет.'), findsOneWidget);
    expect(find.byType(BirkaRing), findsNothing);
    expect(find.byType(BirkaBars), findsOneWidget);
  });

  testWidgets('without any operations there are no bars', (tester) async {
    repository
      ..rows.clear()
      ..totals.clear();
    await pump(tester);

    await tapText(tester, 'ДОХОДЫ');

    expect(find.text('В этом месяце доходов нет.'), findsOneWidget);
    expect(find.byType(BirkaBars), findsNothing);
  });

  testWidgets('other currencies stand apart', (tester) async {
    repository.rows[(CategoryKind.expense, october)] = [
      _total('Продукты', rub(100)),
      _total('Кафе', Money(500, Currency.eur)),
    ];
    await pump(tester);

    expect(find.text('5$space€'), findsOneWidget);
  });

  testWidgets('hidden amounts hide the figures and the average', (
    tester,
  ) async {
    await pump(tester);

    hidden.value = true;
    await tester.pumpAndSettle();

    expect(find.text('37${space}150$space₽'), findsNothing);
    expect(find.text('37k'), findsNothing);
    expect(find.text('в среднем •••$space₽'), findsOneWidget);
    expect(find.text('+35%'), findsOneWidget);
  });

  testWidgets('a failure offers another try', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester);

    expect(find.text('Не удалось прочитать отчёт.'), findsOneWidget);

    repository.readFailure = null;
    await tapText(tester, 'ПОВТОРИТЬ');

    expect(find.byType(BirkaRing), findsOneWidget);
  });

  testWidgets('coming back in a new month follows the calendar', (
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
  });

  testWidgets('the largest amounts fit a small phone', (tester) async {
    final most = Money(Money.maxMinorUnits, Currency.rub);
    repository.rows[(CategoryKind.expense, october)] = [
      _total('Очень длинное название категории расходов', most),
      _total('Кафе', most),
    ];
    repository.totals[CategoryKind.expense] = [MonthTotal(october, most)];
    await pump(tester);
    tester.view.physicalSize = const Size(640, 1136);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
