import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_flutter/schedules_flutter.dart';

import 'fakes.dart';

void main() {
  var closed = 0;

  setUp(() {
    closed = 0;
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Future<void> pump(
    WidgetTester tester,
    FakeSchedulesRepository repository, {
    String? id,
  }) async {
    tester.view.physicalSize = const Size(780, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final cubit = ScheduleFormCubit(repository, id: id);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      phone(cubit, ScheduleFormPage(onClose: () => closed++)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String row, String text) async {
    await tester.tap(find.text(row));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), text);
    await tester.tap(find.text('ГОТОВО'));
    await tester.pumpAndSettle();
  }

  testWidgets('a salary in halves shows its month, its two days and its '
      'next advance', (tester) async {
    final repository = halvesRepository();
    await pump(tester, repository, id: 'pay');

    expect(find.text('СУММА В МЕСЯЦ'), findsOneWidget);
    expect(find.text(nb('+120 000 ₽')), findsOneWidget);
    expect(
      find.text('по ${nb('60 000 ₽')} авансом и зарплатой'),
      findsOneWidget,
    );
    expect(find.text('Как приходит'), findsOneWidget);
    expect(find.text('Пополам: аванс 20-го, зарплата 5-го.'), findsOneWidget);
    expect(find.text('Повторять каждый'), findsNothing);
    expect(find.text('20-го'), findsOneWidget);
    expect(find.text('5-го'), findsOneWidget);
    expect(find.text('аванс, 20 ноября, пт'), findsOneWidget);

    await type(tester, 'СУММА В МЕСЯЦ', '120 000,01');
    expect(
      find.text('Сумма не делится пополам — поправьте копейки'),
      findsOneWidget,
    );
    await type(tester, 'СУММА В МЕСЯЦ', '120 000');

    await tester.tap(find.text('Одной суммой'));
    await tester.pumpAndSettle();

    expect(find.text('СУММА'), findsOneWidget);
    expect(find.text('Повторять каждый'), findsOneWidget);
    expect(find.text('Вся сумма приходит в один день.'), findsOneWidget);

    await tester.tap(find.text('С авансом'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final saved = repository.updated.single;
    expect(saved.amount, rub(60000));
    expect(saved.advanceDay, 20);
    expect(saved.day, 5);
    expect(saved.next, CivilDate(2026, 11, 20));
  });

  testWidgets('a salary gives its advance a sum of its own in a sheet that '
      'says what the salary brings, and takes the half back', (tester) async {
    final repository = halvesRepository();
    await pump(tester, repository, id: 'pay');

    expect(find.text('Сумма аванса'), findsOneWidget);
    expect(find.text('половина'), findsOneWidget);

    await tester.tap(find.text('Сумма аванса'));
    await tester.pumpAndSettle();
    expect(find.text('₽'), findsOneWidget);
    expect(
      find.text('Зарплатой придёт остальное: ${nb('60 000 ₽')} 5-го.'),
      findsOneWidget,
    );
    expect(find.text('Пополам · ${nb('60 000 ₽')}'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), '40 000');
    await tester.pumpAndSettle();
    expect(
      find.text('Зарплатой придёт остальное: ${nb('80 000 ₽')} 5-го.'),
      findsOneWidget,
    );
    await tester.tap(find.text('ГОТОВО'));
    await tester.pumpAndSettle();

    expect(find.text(nb('40 000 ₽')), findsOneWidget);
    expect(
      find.text('аванс ${nb('40 000 ₽')} и зарплата ${nb('80 000 ₽')}'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Аванс ${nb('40 000 ₽')} 20-го, зарплата ${nb('80 000 ₽')} 5-го.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final saved = repository.updated.single;
    expect(saved.amount, rub(80000));
    expect(saved.advanceAmount, rub(40000));
  });

  testWidgets('the chip of the sheet gives the advance back its half', (
    tester,
  ) async {
    final repository = halvesRepository();
    await pump(tester, repository, id: 'pay');
    await tester.tap(find.text('Сумма аванса'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '40 000');
    await tester.tap(find.text('ГОТОВО'));
    await tester.pumpAndSettle();
    expect(find.text(nb('40 000 ₽')), findsOneWidget);

    await tester.tap(find.text('Сумма аванса'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Пополам · ${nb('60 000 ₽')}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ГОТОВО'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(
      find.text('по ${nb('60 000 ₽')} авансом и зарплатой'),
      findsOneWidget,
    );
    expect(find.text('Пополам: аванс 20-го, зарплата 5-го.'), findsOneWidget);
  });

  testWidgets('a new payment takes a name and an amount and saves', (
    tester,
  ) async {
    final repository = FakeSchedulesRepository();
    await pump(tester, repository);

    expect(find.text('Новый платёж'), findsOneWidget);
    expect(find.text('Например, Аренда'), findsOneWidget);

    await type(tester, 'Название', 'Аренда');
    await type(tester, 'СУММА', '45 000');

    expect(find.text('Аренда'), findsOneWidget);
    expect(find.text(nb('45 000 ₽')), findsOneWidget);
    expect(find.text('18-го'), findsOneWidget);

    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final draft = repository.added.single;
    expect(draft.name, 'Аренда');
    expect(draft.amount, rub(45000));
    expect(draft.kind, TransactionKind.expense);
    expect(draft.next, boardToday);
    expect(closed, 1);
  });

  testWidgets('a changed payment can be deleted after a question', (
    tester,
  ) async {
    final repository = FakeSchedulesRepository();
    await pump(tester, repository, id: 'gym');

    expect(find.text('Спортзал'), findsWidgets);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить платёж'));
    await tester.pumpAndSettle();

    expect(find.text('Удалить «Спортзал»?'), findsOneWidget);
    await tester.tap(find.text('УДАЛИТЬ ПЛАТЁЖ'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(repository.deleted, ['gym']);
    expect(closed, 1);
  });
}
