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
