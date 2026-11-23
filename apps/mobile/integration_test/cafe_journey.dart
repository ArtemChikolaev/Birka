import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_flutter/limits_flutter.dart';
import 'package:money/money.dart';

import 'native_journey.dart';

/// Creates the same starting amounts as the category-limit web fixture,
/// with the expense in the month displayed by the native app.
Future<void> seedCafeLedger(LedgerRepository ledger) async {
  final account = await ledger.addAccount(
    name: 'Test card',
    type: AccountType.debit,
    openingBalance: Money(2000000, Currency.rub),
  );
  final cafe = await ledger.addCategory(
    kind: CategoryKind.expense,
    name: 'Cafe',
  );
  await ledger.setCategoryLimit(
    cafe.id,
    CategoryLimit(Money(1200000, Currency.rub)),
  );
  await ledger.record(
    TransactionDraft.expense(
      accountId: account.id,
      allocations: [
        Allocation(
          categoryId: cafe.id,
          amount: Money(1015000, Currency.rub),
        ),
      ],
      occurredOn: CivilDate.of(DateTime.now()),
    ),
  );
}

/// Reads the Cafe limit by following the link on Overview.
Future<void> observeCafeLimit(
  WidgetTester tester,
  String expected,
  String step,
) async {
  final link = find.text('All limits · 1');
  await tester.scrollUntilVisible(
    link.hitTestable(),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tapVisible(link);
  await tester.observeText(
    find.descendant(
      of: find.byType(LimitsPage),
      matching: find.text(expected),
    ),
    step,
  );
}

/// Adds an expense from the navigation bar and reads its preview before saving.
Future<void> spendAtCafe(
  WidgetTester tester,
  String digits,
  String preview,
) async {
  await tester.tap(find.bySemanticsLabel('New operation'));
  await tester.pumpAndSettle();
  await tester.waitForOne(find.text('Cafe'));
  await tester.tap(find.text('Cafe'));
  await tester.typeAmount(digits);
  await tester.observeText(find.text(preview), 'Quick-add preview');
  await tester.tapVisible(find.text('SAVE · CAFE'));
  await tester.waitForOne(
    find.bySemanticsLabel('New operation').hitTestable(),
  );
}
