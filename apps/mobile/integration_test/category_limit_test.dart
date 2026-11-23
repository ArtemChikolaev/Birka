import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_flutter/limits_flutter.dart';
import 'package:money/money.dart';

import 'native_journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('category limit survives saving, crossing it and reopening', (
    tester,
  ) async {
    Future<void> openLimits(String expected, String step) async {
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

    Future<void> spend(String digits, String preview) async {
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
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

    await withNativeLedger(
      tester,
      name: 'category-limit',
      seed: (ledger) async {
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
      },
      journey: (reopen) async {
        await openLimits('₽1,850 left', 'Starting limit');
        await spend('1850', 'Cafe: ₽0 of ₽12,000 left');
        await openLimits('₽0 left', 'After saving ₽1,850');
        await spend('1', 'Cafe: ₽1 over the limit');
        await openLimits('₽1 over', 'After saving ₽1');
        await reopen();
        await openLimits('₽1 over', 'After reopening SQLite');
      },
    );
  });
}
