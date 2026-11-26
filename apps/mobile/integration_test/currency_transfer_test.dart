import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:transactions_flutter/transactions_flutter.dart';

import 'native_journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('both sides of a cross-currency transfer survive reopening', (
    tester,
  ) async {
    final back = find.bySemanticsLabel('Back');

    Future<void> openAccounts() async {
      await tester.tapVisible(find.text('More'));
      await tester.tapVisible(find.text('Accounts'));
    }

    Future<void> openAccount(String name, String balance) async {
      await tester.tapVisible(find.text(name));
      final card = find.descendant(
        of: find.byType(AccountPage),
        matching: find.byType(AccountCard),
      );
      await tester.observeText(
        find.descendant(of: card, matching: find.text(balance)),
        '$name balance',
      );
    }

    Future<void> checkEntry(String amount) async {
      final row = find.byType(OperationRow);
      await tester.scrollUntilVisible(
        row.hitTestable(),
        180,
        scrollable: find
            .descendant(
              of: find.byType(AccountPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.observeText(
        find.descendant(of: row, matching: find.text(amount)),
        'Saved entry',
      );
      expect(row, findsOneWidget);
    }

    await withNativeLedger(
      tester,
      name: 'currency-transfer',
      seed: (ledger) async {
        await ledger.addAccount(
          name: 'Ruble card',
          type: AccountType.debit,
          openingBalance: Money(1000000, Currency.rub),
        );
        await ledger.addAccount(
          name: 'Dollar card',
          type: AccountType.debit,
          openingBalance: Money(2000, Currency.usd),
        );
      },
      journey: (reopen) async {
        await openAccounts();
        for (final (name, balance) in [
          ('Ruble card', '₽10,000'),
          ('Dollar card', r'$20'),
        ]) {
          await openAccount(name, balance);
          await tester.waitForOne(
            find.text('Nothing has happened on this account yet.'),
          );
          await tester.tapVisible(back);
        }

        await tester.tapVisible(back);
        await tester.tapVisible(find.text('Overview'));
        final newOperation = find.bySemanticsLabel('New operation');
        await tester.tapVisible(newOperation);
        await tester.tapVisible(find.text('TRANSFER'));
        await tester.tapVisible(find.text('Dollar card'));
        await tester.tapVisible(find.text('Leaves'));
        await tester.typeAmount('1234.56');
        await tester.observeText(find.text('₽1,234.56'), 'Leaves');
        await tester.tapVisible(find.text('Arrives'));
        await tester.typeAmount('12.34');
        await tester.observeText(find.text(r'$12.34'), 'Arrives');
        await tester.tapVisible(find.text('SAVE · DOLLAR CARD'));
        await tester.waitForOne(newOperation.hitTestable());

        debugPrint('Reopening the saved ledger');
        await reopen();
        await openAccounts();
        final byCurrency = find.text('By currency');
        await tester.tapVisible(byCurrency);
        for (final (name, amount) in [
          ('Rubles', '₽8,765.44'),
          ('Dollars', r'$32.34'),
        ]) {
          await tester.observeText(
            find.descendant(
              of: find.widgetWithText(GlassListRow, name),
              matching: find.text(amount),
            ),
            '$name in capital',
          );
        }
        await tester.tapVisible(byCurrency);
        await openAccount('Ruble card', '₽8,765.44');
        await checkEntry('−₽1,234.56');
        await tester.tapVisible(back);
        await openAccount('Dollar card', r'$32.34');
        await checkEntry(r'+$12.34');
        await tester.tapVisible(find.byType(OperationRow));
        final detail = find.byType(OperationPage);
        await tester.observeText(
          find.descendant(of: detail, matching: find.text('Transfer')),
          'Operation',
        );
        await tester.observeText(
          find.descendant(
            of: detail,
            matching: find.text(r'₽1,234.56 → $12.34'),
          ),
          'Saved transfer',
        );
      },
    );
  });
}
