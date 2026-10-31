import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart' show AccountType;
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/transactions_jaspr.dart';

import 'fake_repository.dart';

void main() {
  const space = ' ';
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final now = DateTime(2026, 10, 31, 9, 30);
  final card = testAccount('Карта');
  final euro = testAccount('Евро', currency: Currency.eur);
  final cafe = testCategory('Кафе');

  late FakeRepository repository;
  var closed = 0;

  Future<void> pump(ComponentTester tester, [String id = 'coffee']) async {
    tester.pumpComponent(
      BlocProvider(
        create: (_) => OperationCubit(repository, id, now: () => now),
        child: OperationPage(
          onClose: () => closed++,
          editHref: 'edit',
          repeatHref: 'repeat',
        ),
      ),
    );
    await tester.pump();
  }

  List<String?> links() => [
    for (final element in find.tag('a').evaluate())
      (element.component as DomComponent).attributes?['href'],
  ];

  Future<void> tap(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
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
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('shows what happened', (tester) async {
    await pump(tester);

    expect(find.text('Операция'), findsOneComponent);
    expect(find.text('−250$space₽'), findsOneComponent);
    expect(find.text('Капучино'), findsOneComponent);
    expect(find.text('Сегодня, 08:42 · Вручную'), findsOneComponent);
    expect(find.text('Карта'), findsOneComponent);
    expect(find.text('Кафе'), findsOneComponent);
    expect(find.text('31 октября'), findsOneComponent);
  });

  testComponents('without a moment there is only the day', (tester) async {
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

    expect(find.text('Вчера · Вручную'), findsOneComponent);
  });

  testComponents('a transfer between currencies shows both sides', (
    tester,
  ) async {
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

    expect(find.text('9${space}000$space₽ → 100$space€'), findsOneComponent);
    expect(find.text('Откуда'), findsOneComponent);
    expect(find.text('Куда'), findsOneComponent);
    expect(find.text('Евро'), findsOneComponent);
  });

  testComponents('the card digits follow the account', (tester) async {
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

    expect(find.text('Карта · •• 4568'), findsOneComponent);
  });

  testComponents('leads to changing and to repeating', (tester) async {
    await pump(tester);

    expect(links(), ['edit', 'repeat']);
  });

  testComponents('a correction cannot be changed, only deleted', (
    tester,
  ) async {
    repository.operations = [
      testOperation(
        'fix',
        amount: rub(5000),
        account: card,
        kind: TransactionKind.adjustment,
      ),
    ];
    await pump(tester, 'fix');

    expect(links(), isEmpty);
    expect(find.text('Удалить'), findsOneComponent);
  });

  testComponents('a delete asks first and then leaves', (tester) async {
    await pump(tester);

    await tap(tester, 'Удалить');
    expect(find.text('Удалить операцию?'), findsOneComponent);
    expect(find.text('−250$space₽ · Капучино'), findsOneComponent);
    await tap(tester, 'Отмена');
    expect(find.text('Удалить операцию?'), findsNothing);
    expect(closed, 0);
    expect(repository.operations, hasLength(1));

    await tap(tester, 'Удалить');
    await tap(tester, 'Удалить');
    await tester.pump();

    expect(repository.operations, isEmpty);
    expect(closed, 1);
  });

  testComponents('a failed delete says so and stays', (tester) async {
    repository.failure = Exception('disk full');
    await pump(tester);

    await tap(tester, 'Удалить');
    await tap(tester, 'Удалить');
    await tester.pump();

    expect(
      find.text('Не удалось удалить. Попробуйте ещё раз.'),
      findsOneComponent,
    );
    expect(find.text('Удалить операцию?'), findsNothing);
    expect(closed, 0);
  });

  testComponents('an operation that went away closes the card', (tester) async {
    await pump(tester);

    repository.operations = const [];
    await tester.pump();

    expect(closed, 1);
  });

  testComponents('the way back closes it', (tester) async {
    await pump(tester);

    await tester.click(find.byType(GlassIconButton));

    expect(closed, 1);
  });

  testComponents('a failure offers another try', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester);

    expect(find.text('Не удалось прочитать операции.'), findsOneComponent);

    repository.readFailure = null;
    await tap(tester, 'Повторить');
    await tester.pump();

    expect(find.text('Капучино'), findsOneComponent);
  });
}
