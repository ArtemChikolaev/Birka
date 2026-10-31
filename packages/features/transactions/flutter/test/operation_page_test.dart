import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart' show AccountType;
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/transactions_flutter.dart';

import 'fake_repository.dart';

void main() {
  const space = '\u00A0';
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final now = DateTime(2026, 10, 31, 9, 30);
  final card = testAccount('Карта');
  final euro = testAccount('Евро', currency: Currency.eur);
  final cafe = testCategory('Кафе');

  late FakeRepository repository;
  var closed = 0;
  var edited = 0;
  var repeated = 0;

  Future<void> pump(WidgetTester tester, [String id = 'coffee']) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider(
          create: (_) => OperationCubit(repository, id, now: () => now),
          child: OperationPage(
            onClose: () => closed++,
            onEdit: () => edited++,
            onRepeat: () => repeated++,
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

  setUp(() {
    repository = FakeRepository(
      operations: [
        testOperation(
          'coffee',
          amount: rub(-25000),
          account: card,
          category: cafe,
          at: DateTime(2026, 10, 31, 8, 42),
          note: 'Капучино',
        ),
      ],
    );
    closed = 0;
    edited = 0;
    repeated = 0;
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('shows what happened', (tester) async {
    await pump(tester);

    expect(find.text('ОПЕРАЦИЯ'), findsOneWidget);
    expect(find.text('−250$space₽'), findsOneWidget);
    expect(find.text('Капучино'), findsOneWidget);
    expect(find.text('Сегодня, 08:42 · Вручную'), findsOneWidget);
    expect(find.text('Карта'), findsOneWidget);
    expect(find.text('Кафе'), findsOneWidget);
    expect(find.text('31 октября'), findsOneWidget);
  });

  testWidgets('without a moment there is only the day', (tester) async {
    repository.operations = [
      testOperation(
        'coffee',
        amount: rub(-25000),
        account: card,
        category: cafe,
        day: CivilDate(2026, 10, 30),
      ),
    ];
    await pump(tester);

    expect(find.text('Вчера · Вручную'), findsOneWidget);
  });

  testWidgets('a transfer between currencies shows both sides', (tester) async {
    repository.operations = [
      testOperation(
        'move',
        amount: rub(-900000),
        account: card,
        toAccount: euro,
        received: Money(10000, Currency.eur),
        kind: TransactionKind.transfer,
      ),
    ];
    await pump(tester, 'move');

    expect(find.text('9${space}000$space₽ → 100$space€'), findsOneWidget);
    expect(find.text('Откуда'), findsOneWidget);
    expect(find.text('Куда'), findsOneWidget);
    expect(find.text('Евро'), findsOneWidget);
  });

  testWidgets('the card digits follow the account', (tester) async {
    const digits = Account(
      id: 'c',
      name: 'Карта',
      type: AccountType.debit,
      openingBalance: Money.zero(Currency.rub),
      lastDigits: '4568',
      includeInTotals: true,
      archived: false,
      sortOrder: 0,
    );
    repository.operations = [
      testOperation('coffee', amount: rub(-100), account: digits),
    ];
    await pump(tester);

    expect(find.text('Карта · •• 4568'), findsOneWidget);
  });

  testWidgets('leads to changing and to repeating', (tester) async {
    await pump(tester);

    await tapText(tester, 'Изменить');
    await tester.tap(find.bySemanticsLabel('Повторить'));
    await tester.pumpAndSettle();

    expect(edited, 1);
    expect(repeated, 1);
  });

  testWidgets('a correction cannot be changed, only deleted', (tester) async {
    repository.operations = [
      testOperation(
        'fix',
        amount: rub(5000),
        account: card,
        kind: TransactionKind.adjustment,
      ),
    ];
    await pump(tester, 'fix');

    expect(find.text('Изменить'), findsNothing);
    expect(find.bySemanticsLabel('Повторить'), findsNothing);
    expect(find.bySemanticsLabel('Удалить'), findsOneWidget);
  });

  testWidgets('a delete asks first and then leaves', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Удалить'));
    await tester.pumpAndSettle();
    await tapText(tester, 'ОТМЕНА');
    expect(closed, 0);
    expect(repository.operations, hasLength(1));

    await tester.tap(find.bySemanticsLabel('Удалить'));
    await tester.pumpAndSettle();
    await tapText(tester, 'УДАЛИТЬ');

    expect(repository.operations, isEmpty);
    expect(closed, 1);
  });

  testWidgets('a failed delete says so and stays', (tester) async {
    repository.failure = Exception('disk full');
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Удалить'));
    await tester.pumpAndSettle();
    await tapText(tester, 'УДАЛИТЬ');

    expect(
      find.text('Не удалось удалить. Попробуйте ещё раз.'),
      findsOneWidget,
    );
    expect(closed, 0);
  });

  testWidgets('an operation that went away closes the card', (tester) async {
    await pump(tester);

    repository.operations = const [];
    await tester.pumpAndSettle();

    expect(closed, 1);
  });

  testWidgets('the way back closes it', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Назад'));

    expect(closed, 1);
  });

  testWidgets('a failure offers another try', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester);

    expect(find.text('Не удалось прочитать операции.'), findsOneWidget);

    repository.readFailure = null;
    await tapText(tester, 'ПОВТОРИТЬ');

    expect(find.text('Капучино'), findsOneWidget);
  });
}
