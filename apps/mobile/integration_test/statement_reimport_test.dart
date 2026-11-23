import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'account_journey.dart';
import 'cafe_journey.dart';
import 'mac_file_panels.dart';
import 'native_journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reimporting the same CSV leaves the account unchanged', (
    tester,
  ) async {
    // Make passes the web journey's fixture to this test build. The app
    // can open its own temporary file through the registered file picker.
    const fixture = String.fromEnvironment('BIRKA_TEST_STATEMENT_BASE64');
    expect(
      fixture,
      isNotEmpty,
      reason: 'Use make verify-flutter FLOW=statement-reimport',
    );
    final folder = await Directory.systemTemp.createTemp('birka-statement-');
    addTearDown(() => folder.delete(recursive: true));
    const name = 'statement-reimport.csv';
    final file = await File.fromUri(
      folder.uri.resolve(name),
    ).writeAsBytes(base64.decode(fixture));
    useMacFilePanels(tester, open: () => file);

    Future<void> openStatement() async {
      await tester.tapVisible(find.text('Import'));
      await tester.observeText(
        find.text('Alfa-Bank · told by the columns'),
        'Detected format',
      );
      await tester.waitForOne(find.text(name));
    }

    Future<void> checkCard(String balance, List<String> amounts) async {
      await tester.tapVisible(find.text('Accounts'));
      await tester.tapVisible(find.text('Test card'));
      await checkAccountHistory(tester, balance: balance, amounts: amounts);
    }

    const imported = ['−₽10,150', '+₽1,000', '−₽250'];
    await withNativeLedger(
      tester,
      name: 'statement-reimport',
      seed: seedCafeLedger,
      journey: (reopen) async {
        await tester.tapVisible(find.text('More'));
        await checkCard('₽9,850', ['−₽10,150']);
        await reopen();

        await tester.tapVisible(find.text('More'));
        await openStatement();
        await tester.tapVisible(find.text('A new account'));
        await tester.tapVisible(find.text('Test card'));
        await tester.tapVisible(find.text('IMPORT 2 OPERATIONS'));
        await tester.observeText(
          find.text('Added 2 operations'),
          'First import',
        );
        await tester.tapVisible(find.text('DONE'));
        await checkCard('₽10,600', imported);
        await reopen();

        await tester.tapVisible(find.text('More'));
        await openStatement();
        await tester.observeText(find.text('Test card'), 'Destination');
        await tester.waitForOne(find.text('Already in the ledger'));
        await tester.observeText(find.text('2, skipped'), 'Duplicates');
        final disabled = find.text('NOTHING TO ADD');
        await tester.ensureVisible(disabled);
        await tester.settleJourney();
        expect(
          tester.getSemantics(find.bySemanticsLabel('Nothing to add')),
          containsSemantics(
            isButton: true,
            isEnabled: false,
            hasTapAction: false,
          ),
        );
        await tester.observeText(disabled, 'Disabled action');
        await tester.tapVisible(find.text('CANCEL'));
        await reopen();
        await tester.tapVisible(find.text('More'));
        await checkCard('₽10,600', imported);
      },
    );
  });
}
