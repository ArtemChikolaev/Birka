import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart'
    show
        AccountArt,
        AccountBalance,
        AccountType,
        DayChange,
        Entry,
        Transaction,
        TransactionSource,
        TransactionStatus;
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart' hide AccountArt;
import 'package:transactions_flutter/transactions_flutter.dart';

import 'fake_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final today = DateTime(2026, 10, 31, 12);
  const card = Account(
    id: 'card',
    name: 'Card',
    type: AccountType.debit,
    openingBalance: Money.zero(Currency.rub),
    includeInTotals: true,
    archived: false,
    sortOrder: 0,
    art: AccountArt.sapphire,
    lastDigits: '4568',
  );
  const cash = Account(
    id: 'cash',
    name: 'Cash',
    type: AccountType.cash,
    openingBalance: Money.zero(Currency.rub),
    includeInTotals: true,
    archived: false,
    sortOrder: 1,
  );

  Operation expense(String id, int amount, {String note = ''}) => Operation(
    transaction: Transaction(
      id: id,
      kind: TransactionKind.expense,
      occurredOn: CivilDate(2026, 10, 31),
      note: note,
      status: TransactionStatus.cleared,
      source: TransactionSource.manual,
      entries: [Entry(accountId: card.id, amount: rub(amount))],
      allocations: const [],
    ),
    account: card,
  );

  Operation transferIn(String id, int amount) => Operation(
    transaction: Transaction(
      id: id,
      kind: TransactionKind.transfer,
      occurredOn: CivilDate(2026, 10, 30),
      note: '',
      status: TransactionStatus.cleared,
      source: TransactionSource.manual,
      entries: [
        Entry(accountId: cash.id, amount: rub(-amount)),
        Entry(accountId: card.id, amount: rub(amount)),
      ],
      allocations: const [],
    ),
    account: cash,
    toAccount: card,
  );

  late FakeRepository repository;
  late List<String> calls;

  Widget page({String id = 'card'}) => MaterialApp(
    theme: BirkaTheme.dark(),
    home: HiddenAmounts(
      notifier: ValueNotifier(false),
      child: BlocProvider(
        create: (_) => AccountCubit(repository, id, now: () => today),
        child: AccountPage(
          onBack: () => calls.add('back'),
          onEdit: () => calls.add('edit'),
          onOpen: (id) => calls.add('open $id'),
          onRepeat: (id) => calls.add('repeat $id'),
        ),
      ),
    ),
  );

  Future<void> pump(WidgetTester tester, {String id = 'card'}) async {
    await tester.pumpWidget(page(id: id));
    await tester.pumpAndSettle();
  }

  void useTallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(402, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    calls = [];
    repository =
        FakeRepository(
            operations: [
              expense('coffee', -25000, note: 'Coffee'),
              transferIn('move', 500000),
            ],
          )
          ..balances = [AccountBalance(card, rub(1234500))]
          ..dayChanges = [
            DayChange(CivilDate(2026, 10, 30), rub(500000)),
            DayChange(CivilDate(2026, 10, 31), rub(-25000)),
          ];
  });

  testWidgets('shows what the account holds and how it got there', (
    tester,
  ) async {
    useTallPhone(tester);
    await pump(tester);

    expect(find.text('CARD'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('₽12,345'), findsOneWidget);
    expect(find.text('Rubles · •• 4568'), findsOneWidget);
    expect(find.byType(BirkaLineChart), findsOneWidget);
    expect(find.text('Operations'.toUpperCase()), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
  });

  testWidgets('keeps the place of its card while it loads', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(page());

    final place = find.byType(BirkaZoomTarget);
    expect(find.byType(AccountCard), findsNothing);
    expect(tester.getSize(place).height, AccountCard.height);
    final element = tester.element(place);

    await tester.pumpAndSettle();

    expect(find.byType(AccountCard), findsOneWidget);
    expect(tester.element(place), same(element));
  });

  testWidgets('rolls the balance down in red after a spend', (tester) async {
    useTallPhone(tester);
    await pump(tester);

    repository
      ..balances = [AccountBalance(card, rub(1200000))]
      ..operations = [
        expense('lunch', -34500, note: 'Lunch'),
        ...repository.operations,
      ];
    // The new balance comes, and the next frame starts the roll.
    await tester.pump();
    await tester.pump();
    await tester.pump(BirkaMotion.roll ~/ 2);

    final rolling = tester.widget<Text>(find.text('₽12,'));
    expect(rolling.style?.color, BirkaColors.dark.negative);

    await tester.pumpAndSettle();

    expect(find.text('₽12,000'), findsOneWidget);
  });

  testWidgets('says what the period changed', (tester) async {
    useTallPhone(tester);
    await pump(tester);

    expect(find.text('+₽4,750'), findsOneWidget);
    expect(find.text('in October'), findsOneWidget);
    expect(find.byType(BirkaChangePill), findsOneWidget);
  });

  testWidgets('a quiet period says no change', (tester) async {
    useTallPhone(tester);
    repository.dayChanges = const [];
    await pump(tester);

    expect(find.byType(BirkaChangePill), findsNothing);
  });

  testWidgets('another period moves the caption', (tester) async {
    useTallPhone(tester);
    await pump(tester);

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();

    expect(find.text('this year'), findsOneWidget);
  });

  testWidgets('a transfer has a sign from this side', (tester) async {
    useTallPhone(tester);
    await pump(tester);

    expect(
      find.descendant(
        of: find.byType(OperationRow),
        matching: find.text('+₽5,000'),
      ),
      findsOneWidget,
    );
    expect(find.text('Cash → Card'), findsOneWidget);
  });

  testWidgets('a day comes to what it did to the account', (tester) async {
    useTallPhone(tester);
    await pump(tester);

    // The row of the transfer and the heading of its day.
    expect(find.text('+₽5,000'), findsNWidgets(2));
  });

  testWidgets('leads back, to the form and to an operation', (tester) async {
    useTallPhone(tester);
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.tap(find.bySemanticsLabel('Edit'));
    await tester.tap(find.text('Coffee'));

    expect(calls, ['back', 'edit', 'open coffee']);
  });

  testWidgets('says when nothing has happened yet', (tester) async {
    useTallPhone(tester);
    repository.operations = const [];
    await pump(tester);

    expect(find.text(t.transactions.noAccountOperations), findsOneWidget);
  });

  testWidgets('says when the account is gone, with the way back', (
    tester,
  ) async {
    await pump(tester, id: 'nothing');

    expect(find.text(t.transactions.accountGone), findsOneWidget);
    expect(find.bySemanticsLabel('Edit'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Back'));
    expect(calls, ['back']);
  });

  testWidgets('says when it cannot read', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester);

    expect(find.text(t.transactions.failedToReadOperations), findsOneWidget);
    expect(find.text(t.app.retry.toUpperCase()), findsOneWidget);
  });

  testWidgets('fits a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pump(tester);

    expect(tester.takeException(), isNull);
  });
}
