import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_flutter/schedules_flutter.dart';

import 'fakes.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Future<SchedulesCubit> pump(
    WidgetTester tester,
    FakeSchedulesRepository repository,
    Widget page,
  ) async {
    tester.view.physicalSize = const Size(780, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final cubit = SchedulesCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(phone(cubit, page));
    await tester.pumpAndSettle();
    return cubit;
  }

  group('the card of the overview', () {
    var plans = 0;
    var lists = 0;
    Widget card() => Scaffold(
      body: SingleChildScrollView(
        child: SpendingCard(
          onOpenPlan: () => plans++,
          onOpenList: () => lists++,
        ),
      ),
    );

    setUp(() {
      plans = 0;
      lists = 0;
    });

    testWidgets('says what today may take and the nearest payments', (
      tester,
    ) async {
      await pump(tester, FakeSchedulesRepository(), card());

      expect(find.text('МОЖНО ТРАТИТЬ СЕГОДНЯ'), findsOneWidget);
      expect(find.text(nb('1 124 ₽')), findsOneWidget);
      expect(find.text('из ${nb('1 744 ₽')} на день'), findsOneWidget);
      expect(
        find.text('Потратили ${nb('620 ₽')} · до зарплаты 17 дней'),
        findsOneWidget,
      );
      expect(find.text('Аренда'), findsOneWidget);
      expect(find.text('Интернет'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Спортзал'), findsNothing);
      expect(find.text('25 ноя'), findsOneWidget);

      await tester.tap(find.text('МОЖНО ТРАТИТЬ СЕГОДНЯ'));
      await tester.tap(find.text('Все регулярные · 6'));
      expect((plans, lists), (1, 1));
    });

    testWidgets('turns red and says what tomorrow allows after too much', (
      tester,
    ) async {
      await pump(tester, FakeSchedulesRepository(spentToday: 2100), card());

      expect(find.text('СЕГОДНЯ БОЛЬШЕ ДНЕВНОГО'), findsOneWidget);
      expect(find.text(nb('−356 ₽')), findsOneWidget);
      expect(
        find.text(
          'Потратили ${nb('2 100 ₽')} · завтра можно ${nb('1 721 ₽')} в день',
        ),
        findsOneWidget,
      );
    });

    testWidgets('asks for the payday without a salary', (tester) async {
      final repository = FakeSchedulesRepository()
        ..schedules = [
          for (final it in boardSchedules())
            if (it.kind != TransactionKind.income) it,
        ];
      await pump(tester, repository, card());

      expect(find.text('Сколько можно тратить в день?'), findsOneWidget);
      await tester.tap(find.text('УКАЗАТЬ ДЕНЬ ЗАРПЛАТЫ'));
      expect(plans, 1);
    });

    testWidgets('stays away without accounts', (tester) async {
      final repository = FakeSchedulesRepository()..accounts = const [];
      await pump(tester, repository, card());

      expect(find.text('МОЖНО ТРАТИТЬ СЕГОДНЯ'), findsNothing);
      expect(find.text('Сколько можно тратить в день?'), findsNothing);
    });

    testWidgets('starts the new day when the app comes back after a night', (
      tester,
    ) async {
      final repository = FakeSchedulesRepository();
      await pump(tester, repository, card());

      repository.day = boardToday.addDays(1);
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

      // What was spent yesterday stays in the balance, and a day less is left.
      expect(find.text(nb('1 814 ₽')), findsOneWidget);
      expect(find.text('из ${nb('1 814 ₽')} на день'), findsOneWidget);
      expect(
        find.text('Потратили ${nb('0 ₽')} · до зарплаты 16 дней'),
        findsOneWidget,
      );
    });
  });

  group('the list of payments', () {
    final opened = <String>[];
    final made = <String>[];
    var added = 0;
    Widget page() => SchedulesPage(
      onBack: () {},
      onAdd: () => added++,
      onOpen: opened.add,
      onFind: made.add,
    );

    setUp(() {
      opened.clear();
      made.clear();
      added = 0;
    });

    testWidgets('shows the next 30 days and every payment', (tester) async {
      await pump(tester, FakeSchedulesRepository(), page());

      expect(find.text('БЛИЖАЙШИЕ 30 ДНЕЙ'), findsOneWidget);
      expect(
        find.text('до 5 декабря ${nb('−49 949 ₽')}'),
        findsOneWidget,
      );
      expect(find.text('ВСЕ РЕГУЛЯРНЫЕ · 6'), findsOneWidget);
      expect(find.text('каждый месяц 25-го · спросить'), findsOneWidget);
      expect(find.text('каждый месяц 1-го · проводится сам'), findsOneWidget);
      expect(find.text('Дом · Зарплатная карта'), findsNWidgets(2));
      expect(find.textContaining('≈ ${nb('39 651 ₽')}'), findsOneWidget);

      await tester.tap(find.text('Страховка авто'));
      expect(opened, ['car']);
    });

    testWidgets('leaves out the next 30 days while nothing comes in them', (
      tester,
    ) async {
      // The only payment waits today, and its next time is a month on.
      final repository = FakeSchedulesRepository()
        ..schedules = [
          schedule('rent', 'Аренда', 45000, boardToday, categoryId: 'home'),
        ];
      await pump(tester, repository, page());

      expect(find.text('ЖДЁТ ПОДТВЕРЖДЕНИЯ'), findsOneWidget);
      expect(find.text('БЛИЖАЙШИЕ 30 ДНЕЙ'), findsNothing);
      expect(find.text('ВСЕ РЕГУЛЯРНЫЕ · 1'), findsOneWidget);
    });

    testWidgets('a payment that waits is posted, and a toast says so', (
      tester,
    ) async {
      final repository = FakeSchedulesRepository()
        ..schedules = [
          ...boardSchedules().where((it) => it.id != 'rent'),
          schedule(
            'rent',
            'Аренда',
            45000,
            boardToday,
            categoryId: 'home',
          ),
        ];
      await pump(tester, repository, page());

      expect(find.text('ЖДЁТ ПОДТВЕРЖДЕНИЯ'), findsOneWidget);
      expect(find.text('Аренда · сегодня'), findsOneWidget);

      await tester.tap(find.text('ПРОВЕСТИ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(repository.posted, ['rent']);
      expect(
        find.text('Провели «Аренда» · ${nb('−45 000 ₽')}'),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('ЖДЁТ ПОДТВЕРЖДЕНИЯ'), findsNothing);
      expect(
        find.text('проведён сегодня · следующий 18 декабря'),
        findsOneWidget,
      );
    });

    testWidgets('a payment that a statement brought today says so at the '
        'top and in its row', (tester) async {
      final repository = FakeSchedulesRepository()
        ..imports = [
          LedgerImport(
            id: 'alfa',
            fileName: 'alfa.xlsx',
            firstDay: CivilDate(2026, 11, 1),
            lastDay: boardToday,
            importedAt: DateTime(2026, 11, 18, 9),
            transactions: 40,
            accountIds: const {'card'},
            format: 'alfa',
          ),
        ]
        ..schedules = [
          ...boardSchedules().where((it) => it.id != 'rent'),
          doneAs(
            schedule(
              'rent',
              'Аренда',
              45000,
              CivilDate(2026, 11, 17),
              categoryId: 'home',
            ),
            ScheduleDone.found,
            at: boardToday,
            importId: 'alfa',
          ),
        ];
      await pump(tester, repository, page());

      expect(find.text('ЖДЁТ ПОДТВЕРЖДЕНИЯ'), findsNothing);
      expect(
        find.text('Нашли «Аренда» в выписке Альфа-Банка'),
        findsOneWidget,
      );
      expect(
        find.text(
          '17 ноября · ${nb('−45 000 ₽')} · '
          'отметили платёж проведённым, копии не будет',
        ),
        findsOneWidget,
      );
      expect(
        find.text('нашли в выписке · следующий 17 декабря'),
        findsOneWidget,
      );
    });

    testWidgets('names the advance and shows the salary of a month', (
      tester,
    ) async {
      await pump(tester, halvesRepository(), page());

      expect(find.text('Аванс'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text(nb('+120 000 ₽')), findsOneWidget);
      expect(find.text(nb('+60 000 ₽')), findsNWidgets(2));
      expect(
        find.text('аванс 20-го и зарплата 5-го · спросить'),
        findsOneWidget,
      );
      // 29 600 ₽ in the morning and the advance of 60 000 ₽, less 49 949 ₽.
      expect(
        find.textContaining('≈ ${nb('39 651 ₽')} с авансом'),
        findsOneWidget,
      );
    });

    testWidgets('a payment that waits can be skipped', (tester) async {
      final repository = FakeSchedulesRepository()
        ..schedules = [
          schedule('rent', 'Аренда', 45000, boardToday, categoryId: 'home'),
        ];
      await pump(tester, repository, page());

      await tester.tap(find.text('ПРОПУСТИТЬ'));
      await tester.pump();

      expect(repository.skipped, ['rent']);
      expect(
        find.text('Пропустили «Аренда» · спросим 18 декабря'),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('shows what came every month, and a tap makes it a payment', (
      tester,
    ) async {
      await pump(
        tester,
        FakeSchedulesRepository()..history = boardFinds(),
        page(),
      );

      expect(find.text('ПОХОЖЕ НА РЕГУЛЯРНЫЕ · 3'), findsOneWidget);
      expect(find.text('12-го · 4 раза подряд'), findsOneWidget);
      expect(find.text(nb('−449 ₽')), findsOneWidget);
      // A bill whose amount changes comes at about what it costs.
      expect(find.text('около 10-го · 3 раза'), findsOneWidget);
      expect(find.text(nb('≈ −6 800 ₽')), findsOneWidget);
      expect(find.text('21-го · 3 раза подряд'), findsOneWidget);
      expect(
        find.text(
          'Повторялись каждый месяц. Нажмите, чтобы добавить, или ✕, если '
          'повтор случайный.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('ЖКУ Москва'));
      expect(made, ['zhku-11']);
    });

    testWidgets('✕ keeps a find away until «Вернуть» brings it back', (
      tester,
    ) async {
      final repository = FakeSchedulesRepository()..history = boardFinds();
      await pump(tester, repository, page());

      await tester.tap(find.bySemanticsLabel('Не регулярный: Облако Mail.ru'));
      await tester.pumpAndSettle();

      expect(find.text('Облако Mail.ru'), findsNothing);
      expect(find.text('ПОХОЖЕ НА РЕГУЛЯРНЫЕ · 2'), findsOneWidget);
      expect(find.text('Не будем предлагать «Облако Mail.ru»'), findsOneWidget);
      expect(repository.dismissed, hasLength(1));

      await tester.tap(find.text('Вернуть'));
      await tester.pumpAndSettle();

      expect(find.text('Облако Mail.ru'), findsOneWidget);
      expect(find.text('ПОХОЖЕ НА РЕГУЛЯРНЫЕ · 3'), findsOneWidget);
      expect(repository.dismissed, isEmpty);
    });

    testWidgets('a find leaves once the form that made it a payment has gone '
        'down, and a toast says so', (tester) async {
      final repository = FakeSchedulesRepository()..history = boardFinds();
      await pump(tester, repository, page());
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          CupertinoSheetRoute<void>(builder: (_) => const SizedBox.expand()),
        ),
      );
      await tester.pumpAndSettle();

      // The form saves the payment made of the latest time.
      repository
        ..schedules = [
          ...repository.schedules,
          Schedule(
            id: 'plus',
            kind: TransactionKind.expense,
            name: 'Яндекс Плюс',
            accountId: 'card',
            amount: rub(449),
            every: ScheduleEvery.month,
            day: 12,
            next: CivilDate(2026, 12, 12),
            onDay: ScheduleOnDay.post,
            reminder: ScheduleReminder.none,
            madeFrom: 'plus-11',
          ),
        ]
        ..changed();
      await tester.pump();
      navigator.pop();
      await tester.pump();
      await tester.pump(BirkaMotion.slow);

      // The find stays while the sheet goes down.
      expect(find.text('ПОХОЖЕ НА РЕГУЛЯРНЫЕ · 3'), findsOneWidget);
      expect(find.text('ВСЕ РЕГУЛЯРНЫЕ · 6'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('ПОХОЖЕ НА РЕГУЛЯРНЫЕ · 2'), findsOneWidget);
      expect(find.text('ВСЕ РЕГУЛЯРНЫЕ · 7'), findsOneWidget);
      expect(find.text('Добавили в регулярные: «Яндекс Плюс»'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('without payments the finds stand over the empty page', (
      tester,
    ) async {
      await pump(
        tester,
        FakeSchedulesRepository()
          ..schedules = const []
          ..history = boardFinds(),
        page(),
      );

      expect(find.text('НАШЛИ В ВАШИХ ОПЕРАЦИЯХ · 3'), findsOneWidget);
      expect(find.text('Регулярных платежей пока нет'), findsOneWidget);
    });

    testWidgets('without payments it offers to add one', (tester) async {
      await pump(
        tester,
        FakeSchedulesRepository()..schedules = const [],
        page(),
      );

      expect(find.text('Регулярных платежей пока нет'), findsOneWidget);
      await tester.tap(find.text('ДОБАВИТЬ ПЛАТЁЖ'));
      expect(added, 1);
    });
  });

  group('the money until the salary', () {
    final salaries = <String>[];
    var newSalaries = 0;
    var monthStarts = 0;
    Widget page() => PaydayPage(
      onBack: () {},
      onOpenSalary: salaries.add,
      onAddSalary: () => newSalaries++,
      onMonthStart: () => monthStarts++,
    );

    setUp(() {
      salaries.clear();
      newSalaries = 0;
      monthStarts = 0;
    });

    testWidgets('shows the sum in the open', (tester) async {
      await pump(tester, FakeSchedulesRepository(), page());

      expect(find.text('${nb('1 744 ₽')} в день'), findsOneWidget);
      expect(find.text('до зарплаты 5 декабря · 17 дней'), findsOneWidget);
      expect(find.text(nb('89 600 ₽')), findsOneWidget);
      expect(find.text('4 платежа до зарплаты'), findsOneWidget);
      expect(find.text(nb('−49 949 ₽')), findsOneWidget);
      expect(find.text(nb('−10 000 ₽')), findsOneWidget);
      expect(find.text('Остаётся на 17 дней'), findsOneWidget);
      expect(find.text(nb('29 651 ₽')), findsOneWidget);
      expect(find.text('из платежа «Зарплата»'), findsOneWidget);
      expect(find.text('5-е число'), findsOneWidget);

      await tester.tap(find.text('День зарплаты'));
      expect(salaries, ['pay']);
    });

    testWidgets('takes the advance of the salary in the open', (
      tester,
    ) async {
      await pump(tester, halvesRepository(), page());

      expect(find.text('${nb('1 744 ₽')} в день'), findsOneWidget);
      expect(find.text('до зарплаты 5 декабря · 17 дней'), findsOneWidget);
      expect(find.text(nb('29 600 ₽')), findsOneWidget);
      expect(find.text('Аванс 20 ноября'), findsOneWidget);
      expect(find.text(nb('+60 000 ₽')), findsOneWidget);
      expect(find.text(nb('29 651 ₽')), findsOneWidget);
      expect(
        find.text(
          'До аванса 20 ноября хватает: ${nb('19 600 ₽')} на 2 дня',
        ),
        findsOneWidget,
      );
      expect(find.text('Аванс и зарплата'), findsOneWidget);
      expect(find.text('20-го и 5-го'), findsOneWidget);
    });

    testWidgets('counts other accounts and until the end of the month', (
      tester,
    ) async {
      final repository = FakeSchedulesRepository();
      await pump(tester, repository, page());

      // Wise is in another currency, so its switch does not move.
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.map((it) => it.value), [true, true, false, false]);
      expect(switches.last.onChanged, isNull);
      expect(find.text('другая валюта, пока не считаем'), findsOneWidget);

      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      expect(repository.settings.accounts, {'card'});

      await tester.tap(find.text('Конца месяца'));
      await tester.pumpAndSettle();
      expect(repository.settings.until, SpendUntil.monthEnd);
      expect(find.text('День зарплаты'), findsNothing);
    });

    testWidgets('asks when the months start, and offers the payday', (
      tester,
    ) async {
      const hint =
          'Зарплата приходит 5-го: месяц можно начинать с этого дня, тогда '
          'ноябрь — с 5 ноября по 4 декабря.';
      final repository = FakeSchedulesRepository();
      await pump(tester, repository, page());
      await tester.scrollUntilVisible(
        find.text(hint),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Начало месяца'), findsOneWidget);
      expect(find.text('для обзора и отчётов'), findsOneWidget);
      expect(find.text('1 число'), findsOneWidget);
      await tester.tap(find.text('Начало месяца'));
      expect(monthStarts, 1);

      // Once the months start on the payday, the hint has nothing to offer.
      repository
        ..monthStart = 5
        ..changed();
      await tester.pumpAndSettle();
      expect(find.text('5 число'), findsOneWidget);
      expect(find.text(hint), findsNothing);
    });

    testWidgets('offers to add a salary when no income brings one', (
      tester,
    ) async {
      final repository = FakeSchedulesRepository()
        ..schedules = [
          for (final it in boardSchedules())
            if (it.kind != TransactionKind.income) it,
        ];
      await pump(tester, repository, page());

      expect(find.text('Сколько можно тратить в день?'), findsOneWidget);
      await tester.tap(find.text('добавьте регулярное поступление'));
      expect(newSalaries, 1);
    });
  });
}
