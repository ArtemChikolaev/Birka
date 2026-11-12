import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart' show AccountType, TagMark;
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/transactions_flutter.dart';

import 'fake_repository.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  const card = Account(
    id: 'card',
    name: 'Карта в лари',
    type: AccountType.debit,
    openingBalance: Money.zero(Currency.rub),
    includeInTotals: true,
    archived: false,
    sortOrder: 0,
  );

  /// A lunch of each of the last [days] days of the trip, the latest first.
  List<Operation> lunches(int days) => [
    for (var i = 0; i < days; i++)
      testOperation(
        'lunch $i',
        amount: Money(-3800, Currency.rub),
        account: card,
        day: CivilDate(2026, 11, 12 - i),
        note: 'Обед $i',
        tags: {'tbilisi': TagMark.days},
      ),
    testOperation(
      'home',
      amount: Money(-120000, Currency.rub),
      account: card,
      day: CivilDate(2026, 11, 12),
      note: 'Дома',
    ),
  ];

  Future<void> pump(WidgetTester tester, List<Operation> operations) async {
    final cubit = TagOperationsCubit(
      FakeRepository(accountList: const [card], operations: operations),
      'tbilisi',
      now: () => DateTime(2026, 11, 12, 12),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: ListView(
              children: [TagOperations(onOpen: (_) {}, onRepeat: (_) {})],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the latest days and the rest after «all»', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, lunches(5));

    expect(find.text('Обед 0'), findsOneWidget);
    expect(find.text('Обед 2'), findsOneWidget);
    expect(find.text('Обед 3'), findsNothing);
    expect(find.text('Дома'), findsNothing);

    await tester.tap(find.text('Все 5 операций'));
    await tester.pumpAndSettle();

    expect(find.text('Обед 4'), findsOneWidget);
    expect(find.text('Все 5 операций'), findsNothing);
  });

  testWidgets('a few days need no «all»', (tester) async {
    await pump(tester, lunches(2));

    expect(find.text('Обед 1'), findsOneWidget);
    expect(find.textContaining('Все'), findsNothing);
  });
}
