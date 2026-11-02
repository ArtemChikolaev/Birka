import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/transactions_jaspr.dart';

import 'fake_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final today = DateTime(2026, 10, 31, 12);
  final card = testAccount('Card');
  final cash = testAccount('Cash');

  late FakeRepository repository;
  late List<String> calls;

  Future<void> pump(ComponentTester tester, {String id = 'Card'}) async {
    tester.pumpComponent(
      HiddenAmounts(
        hidden: false,
        onToggle: () {},
        child: BlocProvider(
          create: (_) => AccountCubit(repository, id, now: () => today),
          child: AccountPage(
            onClose: () => calls.add('close'),
            editHref: 'edit',
            hrefOf: (id) => 'open/$id',
          ),
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
    setIsClientForTesting(true);
    addTearDown(resetIsClientForTesting);
    LocaleSettings.setLocaleSync(AppLocale.en);
    calls = [];
    repository =
        FakeRepository(
            operations: [
              testOperation(
                'coffee',
                amount: rub(-25000),
                account: card,
                note: 'Coffee',
              ),
              testOperation(
                'move',
                amount: rub(-500000),
                account: cash,
                toAccount: card,
                kind: TransactionKind.transfer,
                day: CivilDate(2026, 10, 30),
              ),
            ],
          )
          ..balances = [AccountBalance(card, rub(1234500))]
          ..dayChanges = [
            DayChange(CivilDate(2026, 10, 30), rub(500000)),
            DayChange(CivilDate(2026, 10, 31), rub(-25000)),
          ];
  });

  testComponents('shows what the account holds and how it got there', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Account'), findsOneComponent);
    expect(find.text('Card'), findsOneComponent);
    expect(find.text('₽12,345'), findsOneComponent);
    expect(find.byType(BirkaLineChart), findsOneComponent);
    expect(find.text('Operations'), findsOneComponent);
    expect(find.text('Coffee'), findsOneComponent);
  });

  testComponents('says what the period changed', (tester) async {
    await pump(tester);

    expect(find.text('+₽4,750'), findsOneComponent);
    expect(find.text('in October'), findsOneComponent);
    expect(find.byType(BirkaChangePill), findsOneComponent);
  });

  testComponents('a quiet period says no change', (tester) async {
    repository.dayChanges = const [];
    await pump(tester);

    expect(find.byType(BirkaChangePill), findsNothing);
  });

  testComponents('another period moves the caption', (tester) async {
    await pump(tester);

    await tap(tester, 'Year');

    expect(find.text('this year'), findsOneComponent);
  });

  testComponents('a transfer has a sign from this side', (tester) async {
    await pump(tester);

    expect(
      find.descendant(
        of: find.byType(GlassListRow),
        matching: find.text('+₽5,000'),
      ),
      findsOneComponent,
    );
    expect(find.text('Cash → Card'), findsOneComponent);
  });

  testComponents('a day comes to what it did to the account', (tester) async {
    await pump(tester);

    // The row of the transfer and the heading of its day.
    expect(find.text('+₽5,000'), findsNComponents(2));
  });

  testComponents('leads back, to the form and to an operation', (tester) async {
    await pump(tester);

    await tester.click(find.tag('button').first);

    expect(calls, ['close']);
    expect(links(), ['edit', 'open/coffee', 'open/move']);
  });

  testComponents('says when nothing has happened yet', (tester) async {
    repository.operations = const [];
    await pump(tester);

    expect(find.text(t.transactions.noAccountOperations), findsOneComponent);
  });

  testComponents('says when the account is gone, with the way back', (
    tester,
  ) async {
    await pump(tester, id: 'nothing');

    expect(find.text(t.transactions.accountGone), findsOneComponent);
    expect(links(), isEmpty);
    await tester.click(find.tag('button').first);
    expect(calls, ['close']);
  });

  testComponents('says when it cannot read, and reads again', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester);

    expect(find.text(t.transactions.failedToReadOperations), findsOneComponent);

    repository.readFailure = null;
    await tap(tester, t.app.retry);

    expect(find.text('₽12,345'), findsOneComponent);
  });

  testComponents('hides the amounts of the page when they are hidden', (
    tester,
  ) async {
    tester.pumpComponent(
      HiddenAmounts(
        hidden: true,
        onToggle: () {},
        child: BlocProvider(
          create: (_) => AccountCubit(repository, 'Card', now: () => today),
          child: AccountPage(
            onClose: () {},
            editHref: 'edit',
            hrefOf: (id) => 'open/$id',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('+₽5,000'), findsNothing);
    expect(find.text('₽12,345'), findsNothing);
    expect(find.text('Coffee'), findsOneComponent);
  });
}
