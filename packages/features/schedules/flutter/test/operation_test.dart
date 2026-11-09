import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_flutter/schedules_flutter.dart';

import 'fakes.dart';

/// The subscription of the board, which the statement of the card brought on
/// 12 November and which no payment has yet.
Transaction plus({List<Allocation>? allocations}) => Transaction(
  id: 'plus',
  kind: TransactionKind.expense,
  occurredOn: CivilDate(2026, 11, 12),
  note: 'Яндекс Плюс',
  status: TransactionStatus.cleared,
  source: TransactionSource.import,
  entries: [Entry(accountId: 'card', amount: -rub(449))],
  allocations:
      allocations ?? [Allocation(categoryId: 'home', amount: rub(449))],
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('the row on the card of an operation', () {
    late List<String> opened;
    late int made;

    Future<FakeSchedulesRepository> pump(
      WidgetTester tester, {
      Transaction? operation,
    }) async {
      opened = [];
      made = 0;
      final repository = FakeSchedulesRepository()
        ..operations = [operation ?? plus()];
      final cubit = OperationScheduleCubit(repository, 'plus');
      addTearDown(cubit.close);
      await tester.pumpWidget(
        phone(
          cubit,
          Scaffold(
            body: ListView(
              children: [
                OperationScheduleRow(
                  onMake: () => made++,
                  onOpen: opened.add,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repository;
    }

    testWidgets('offers to make the operation a payment on its day', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Сделать регулярным'), findsOneWidget);
      expect(find.text('Повторять каждый месяц 12-го'), findsOneWidget);

      await tester.tap(find.text('Сделать регулярным'));
      expect(made, 1);
    });

    testWidgets('turns into its payment once it is one and says so', (
      tester,
    ) async {
      final repository = await pump(tester);

      await repository.add(
        ScheduleDraft(
          kind: TransactionKind.expense,
          name: 'Яндекс Плюс',
          accountId: 'card',
          amount: rub(449),
          every: ScheduleEvery.month,
          next: CivilDate(2026, 12, 12),
          madeFrom: 'plus',
        ),
      );
      // The toast comes in the frame after the one that shows the payment.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text('Регулярный платёж'), findsOneWidget);
      expect(
        find.text('Яндекс Плюс · каждый месяц 12-го'),
        findsOneWidget,
      );
      expect(
        find.text('Добавили в регулярные: «Яндекс Плюс»'),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Регулярный платёж'));
      expect(opened, ['new']);
    });

    testWidgets('waits with its payment and toast until the form leaves the '
        'card', (
      tester,
    ) async {
      final repository = FakeSchedulesRepository()..operations = [plus()];
      final cubit = OperationScheduleCubit(repository, 'plus');
      addTearDown(cubit.close);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: BirkaTheme.dark(),
          home: BlocProvider.value(
            value: cubit,
            child: Scaffold(
              body: ListView(
                children: [
                  OperationScheduleRow(onMake: () {}, onOpen: (_) {}),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        navigator.currentState!.push(
          CupertinoSheetRoute<void>(builder: (_) => const SizedBox.expand()),
        ),
      );
      await tester.pumpAndSettle();

      await repository.add(
        ScheduleDraft(
          kind: TransactionKind.expense,
          name: 'Яндекс Плюс',
          accountId: 'card',
          amount: rub(449),
          every: ScheduleEvery.month,
          next: CivilDate(2026, 12, 12),
          madeFrom: 'plus',
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      const toast = 'Добавили в регулярные: «Яндекс Плюс»';
      expect(find.text(toast), findsNothing);

      navigator.currentState!.pop();
      await tester.pump();
      await tester.pump(BirkaMotion.slow);
      expect(find.text(toast), findsNothing);
      expect(find.text('Сделать регулярным'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text(toast), findsOneWidget);
      expect(find.text('Регулярный платёж'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('stays away for a split', (tester) async {
      await pump(
        tester,
        operation: plus(
          allocations: [
            Allocation(categoryId: 'home', amount: rub(300)),
            Allocation(categoryId: 'fun', amount: rub(149)),
          ],
        ),
      );

      expect(find.text('Сделать регулярным'), findsNothing);
      expect(find.byType(GlassListRow), findsNothing);
    });
  });

  testWidgets('the form of a payment made from an operation starts as it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final repository = FakeSchedulesRepository()..operations = [plus()];
    final cubit = ScheduleFormCubit(repository, from: 'plus');
    addTearDown(cubit.close);
    await tester.pumpWidget(phone(cubit, ScheduleFormPage(onClose: () {})));
    await tester.pumpAndSettle();

    expect(find.text('Из операции 12 ноября'), findsOneWidget);
    expect(find.text('Яндекс Плюс · ${nb('−449 ₽')} · Дом'), findsOneWidget);
    expect(find.text('Яндекс Плюс'), findsOneWidget);
    expect(find.text(nb('449 ₽')), findsOneWidget);
    expect(find.text('12-го'), findsOneWidget);
    expect(find.text('12 декабря, сб'), findsOneWidget);

    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pumpAndSettle();

    final draft = repository.added.single;
    expect(draft.madeFrom, 'plus');
    expect(draft.next, CivilDate(2026, 12, 12));
    expect(draft.onDay, ScheduleOnDay.post);
  });

  testWidgets('the form made from what came every month gives its days, and '
      'a bill whose amount changes gives its amounts', (tester) async {
    tester.view.physicalSize = const Size(780, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final repository = FakeSchedulesRepository()..operations = boardFinds();
    repository.categories.add(
      const Category(
        id: 'subs',
        kind: CategoryKind.expense,
        name: 'Подписки',
        color: '#A78BFA',
        archived: false,
        sortOrder: 1,
      ),
    );
    final cubit = ScheduleFormCubit(repository, from: 'zhku-11');
    addTearDown(cubit.close);
    await tester.pumpWidget(phone(cubit, ScheduleFormPage(onClose: () {})));
    await tester.pumpAndSettle();

    expect(find.text('Нашли в операциях · 3 раза'), findsOneWidget);
    expect(find.text('10 сен, 9 окт, 10 ноя · Подписки'), findsOneWidget);
    expect(find.text(nb('7 120 ₽')), findsOneWidget);
    expect(
      find.text(
        'последняя сумма · бывало от ${nb('6 410 ₽')} до ${nb('7 120 ₽')}',
      ),
      findsOneWidget,
    );
    expect(find.text('10-го'), findsOneWidget);
    expect(find.text('10 декабря, чт'), findsOneWidget);

    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pumpAndSettle();

    final draft = repository.added.single;
    expect(draft.madeFrom, 'zhku-11');
    expect(draft.next, CivilDate(2026, 12, 10));
    expect(draft.onDay, ScheduleOnDay.ask);
  });
}
