import 'package:debts_common/debts_common.dart';
import 'package:debts_common/testing.dart';
import 'package:debts_flutter/debts_flutter.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

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

  group('the list of debts', () {
    testWidgets('adds up who owes whom and opens a person', (tester) async {
      final opened = <String>[];
      final cubit = DebtsCubit(FakeDebtsRepository());
      addTearDown(cubit.close);
      await tester.pumpWidget(
        phone(
          cubit,
          DebtsPage(onBack: () {}, onAdd: () {}, onOpen: opened.add),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(nb('12 768 ₽')), findsOneWidget);
      expect(find.text('2 человека'), findsOneWidget);
      expect(find.text(nb('4 000 ₽')), findsNWidgets(2));
      expect(find.text('МНЕ ДОЛЖНЫ'), findsOneWidget);
      expect(find.text('МОИ ДОЛГИ'), findsOneWidget);
      expect(find.text('срок сегодня'), findsOneWidget);
      expect(find.text(nb(r'120 $')), findsOneWidget);
      expect(find.text('≈ ${nb('9 768 ₽')}'), findsOneWidget);
      expect(find.text('до 1 декабря'), findsOneWidget);
      expect(find.text('из ${nb('5 000 ₽')}'), findsOneWidget);
      expect(find.text('Ира'), findsNothing);

      await tester.tap(find.text('ЗАКРЫТЫЕ · 2'));
      await tester.pumpAndSettle();
      expect(find.text('Ира'), findsOneWidget);
      expect(find.text('вернули 2 ноября'), findsOneWidget);

      await tester.tap(find.text('Маша'));
      expect(opened, ['masha']);
    });

    testWidgets('offers the first debt when there is none', (tester) async {
      var added = 0;
      final cubit = DebtsCubit(FakeDebtsRepository(debts: [], transfers: []));
      addTearDown(cubit.close);
      await tester.pumpWidget(
        phone(
          cubit,
          DebtsPage(onBack: () {}, onAdd: () => added++, onOpen: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Долгов нет'), findsOneWidget);
      await tester.tap(find.widgetWithText(BirkaButton, 'ЗАПИСАТЬ ДОЛГ'));
      expect(added, 1);
    });
  });

  group('the card of a debt', () {
    testWidgets('says what came back and opens the return', (tester) async {
      var returns = 0;
      var more = 0;
      final cubit = DebtsCubit(FakeDebtsRepository());
      addTearDown(cubit.close);
      await tester.pumpWidget(
        phone(
          cubit,
          DebtPage(
            id: 'masha',
            onBack: () {},
            onEdit: () {},
            onReturn: () => returns++,
            onMore: () => more++,
            onOpenStep: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(nb('3 000 ₽')), findsOneWidget);
      expect(
        find.text('осталось вернуть вам из ${nb('5 000 ₽')}'),
        findsOneWidget,
      );
      expect(find.text('Вернули ${nb('2 000 ₽')}'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(
        find.text('Срок 1 декабря · напомним в этот день'),
        findsOneWidget,
      );
      expect(find.text('Возврат'), findsNWidgets(2));
      expect(find.text('10 ноября · Зарплатная карта'), findsOneWidget);
      expect(find.text('3 ноября · Наличные · на билеты'), findsOneWidget);

      await tester.tap(find.byType(GlassActionTile).first);
      await tester.tap(find.text('Ещё в долг'));
      expect((returns, more), (1, 1));
    });

    testWidgets('of a settled debt has nothing to take back', (tester) async {
      var returns = 0;
      final cubit = DebtsCubit(FakeDebtsRepository());
      addTearDown(cubit.close);
      await tester.pumpWidget(
        phone(
          cubit,
          DebtPage(
            id: 'ira',
            onBack: () {},
            onEdit: () {},
            onReturn: () => returns++,
            onMore: () {},
            onOpenStep: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('вернули всё · 2 ноября'), findsOneWidget);
      expect(find.text('Долг закрыт'), findsOneWidget);
      expect(find.text('Новый долг'), findsOneWidget);
      await tester.tap(find.byType(GlassActionTile).first);
      expect(returns, 0);
    });
  });

  group('the form of a debt', () {
    testWidgets('lends to someone new and says what it wrote', (tester) async {
      final repository = FakeDebtsRepository();
      final cubit = DebtFormCubit(repository);
      addTearDown(cubit.close);
      final closed = <String?>[];
      await tester.pumpWidget(phone(cubit, DebtFormPage(onClose: closed.add)));
      await tester.pumpAndSettle();

      expect(find.text('Новый долг'), findsOneWidget);
      expect(find.textContaining('Долг — не трата'), findsOneWidget);

      await tester.tap(find.text('Другой'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Лена');
      await tester.tap(find.text('ГОТОВО'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Сумма'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2500');
      await tester.tap(find.text('ГОТОВО'));
      await tester.pumpAndSettle();
      expect(find.text(nb('2 500 ₽')), findsOneWidget);

      await tester.tap(find.widgetWithText(BirkaButton, 'СОХРАНИТЬ'));
      await tester.pumpAndSettle();

      expect(repository.debts.last.name, 'Лена');
      expect(closed, [repository.debts.last.id]);
      expect(find.text('Записали: Лена, ${nb('2 500 ₽')}'), findsOneWidget);
    });

    testWidgets('waits for who a namesake is, or for their chip', (
      tester,
    ) async {
      final cubit = DebtFormCubit(
        FakeDebtsRepository(
          people: [
            for (final person in peopleOf(boardDebts()))
              person.id == 'p-masha'
                  ? person.copyWith(about: 'коллега')
                  : person,
          ],
        ),
      );
      addTearDown(cubit.close);
      await tester.pumpWidget(phone(cubit, DebtFormPage(onClose: (_) {})));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Другой'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'маша');
      await tester.pump();
      await tester.tap(find.text('ГОТОВО'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сумма'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2500');
      await tester.tap(find.text('ГОТОВО'));
      await tester.pumpAndSettle();

      const twin =
          'Маша уже есть — коллега. Если это тот же человек, выберите его '
          'выше; если другой — напишите, кто это.';
      expect(find.text(twin), findsOneWidget);
      final save = find.widgetWithText(BirkaButton, 'СОХРАНИТЬ');
      expect(tester.widget<BirkaButton>(save).onPressed, isNull);

      await tester.tap(find.text('Маша'));
      await tester.pumpAndSettle();
      expect(find.text(twin), findsNothing);
      expect(tester.widget<BirkaButton>(save).onPressed, isNotNull);
    });

    testWidgets('of more money keeps to its person and its side', (
      tester,
    ) async {
      final cubit = DebtFormCubit(FakeDebtsRepository(), debtId: 'sasha');
      addTearDown(cubit.close);
      await tester.pumpWidget(phone(cubit, DebtFormPage(onClose: (_) {})));
      await tester.pumpAndSettle();

      expect(find.text('Занять ещё · Саша'), findsOneWidget);
      expect(find.text('ОДОЛЖИТЬ'), findsNothing);
      expect(find.text('На счёт'), findsOneWidget);
      expect(find.text('20 ноября'), findsOneWidget);
      expect(find.text('Напомнить в срок'), findsOneWidget);
    });
  });

  group('the return', () {
    testWidgets('takes back a part and says what is left', (tester) async {
      final repository = FakeDebtsRepository();
      final cubit = DebtReturnCubit(repository, 'masha');
      addTearDown(cubit.close);
      var closed = 0;
      await tester.pumpWidget(
        phone(cubit, DebtReturnPage(onClose: () => closed++)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Возврат · Маша'), findsOneWidget);
      expect(find.text('Всё · ${nb('3 000 ₽')}'), findsOneWidget);
      expect(find.text('Зарплатная карта'), findsOneWidget);

      await tester.tap(find.text('Часть'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1000');
      await tester.tap(find.text('ГОТОВО'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Останется ${nb('2 000 ₽')} до 1 декабря. Деньги придут на счёт, '
          'но не в доходы.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(BirkaButton, 'СОХРАНИТЬ'));
      await tester.pumpAndSettle();

      expect(closed, 1);
      expect(
        find.text('Возврат ${nb('1 000 ₽')} · осталось ${nb('2 000 ₽')}'),
        findsOneWidget,
      );
      expect(repository.transfers.last.entries.first.accountId, 'masha');
    });
  });

  group('the terms', () {
    testWidgets('rename the person', (tester) async {
      final repository = FakeDebtsRepository();
      final cubit = DebtTermsCubit(repository, 'sasha');
      addTearDown(cubit.close);
      var closed = 0;
      await tester.pumpWidget(
        phone(cubit, DebtTermsPage(onClose: () => closed++)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Изменить долг'), findsOneWidget);
      await tester.tap(find.text('Саша'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Саша Н.');
      await tester.tap(find.text('ГОТОВО'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(BirkaButton, 'СОХРАНИТЬ'));
      await tester.pumpAndSettle();

      expect(closed, 1);
      expect(
        repository.debts.firstWhere((debt) => debt.id == 'sasha').name,
        'Саша Н.',
      );
    });
  });

  testWidgets('the row of «Ещё» says what others owe and what is owed', (
    tester,
  ) async {
    var opened = 0;
    final cubit = DebtsCubit(FakeDebtsRepository());
    addTearDown(cubit.close);
    await tester.pumpWidget(
      phone(
        cubit,
        Scaffold(body: DebtsMoreRow(onOpen: () => opened++)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Долги'), findsOneWidget);
    expect(
      find.text('Мне должны ${nb('12 768 ₽')} · мои ${nb('4 000 ₽')}'),
      findsOneWidget,
    );
    await tester.tap(find.text('Долги'));
    expect(opened, 1);
  });

  test('a debt shows the initial of its person', () {
    expect(InitialBadge.letterOf(boardDebts().first.name), 'Д');
    expect(boardDebts().first.debt?.side, DebtSide.lent);
  });
}
