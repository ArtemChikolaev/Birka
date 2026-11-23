import 'dart:io';

import 'package:backup_flutter/backup_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

import 'account_journey.dart';
import 'cafe_journey.dart';
import 'mac_file_panels.dart';
import 'native_journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a saved file replaces another ledger and survives reopening', (
    tester,
  ) async {
    final folder = await Directory.systemTemp.createTemp('birka-backup-file-');
    addTearDown(() => folder.delete(recursive: true));
    late File copy;
    useMacFilePanels(
      tester,
      open: () => copy,
      save: (name) {
        expect(name, matches(RegExp(r'^birka-\d{4}-\d{2}-\d{2}\.birka$')));
        return copy = File.fromUri(folder.uri.resolve(name));
      },
    );

    await withNativeLedger(
      tester,
      name: 'backup-source',
      seed: seedCafeLedger,
      journey: (_) async {
        await spendAtCafe(tester, '150', 'Cafe: ₽1,700 of ₽12,000 left');
        await tester.tapVisible(find.text('More'));
        await tester.tapVisible(find.text('Data'));
        await tester.tapVisible(find.text('SAVE A COPY'));
        await tester.observeText(find.textContaining('Last copy:'), 'Saved');
        expect(await copy.length(), greaterThan(0));
      },
    );

    final back = find.bySemanticsLabel('Back');
    const marker = 'Destination only';
    Future<void> checkDestination(String step) async {
      await tester.tapVisible(find.text('Accounts'));
      await tester.observeText(find.text(marker), step);
      expect(find.text('Test card'), findsNothing);
      await tester.tapVisible(back);
    }

    Future<void> offerCopy() async {
      await tester.tapVisible(find.text('Data'));
      await tester.tapVisible(find.text('RESTORE FROM A COPY'));
      await tester.observeText(
        find.text(copy.uri.pathSegments.last),
        'Offered',
      );
    }

    await withNativeLedger(
      tester,
      name: 'backup-destination',
      seed: (ledger) async {
        await ledger.addAccount(
          name: marker,
          type: AccountType.debit,
          openingBalance: Money(100, Currency.rub),
        );
      },
      journey: (reopen) async {
        await tester.tapVisible(find.text('More'));
        await checkDestination('Before restore');
        await offerCopy();
        await tester.tapVisible(find.text('CANCEL'));
        await tester.waitForOne(find.text('RESTORE FROM A COPY').hitTestable());
        await reopen();
        await tester.tapVisible(find.text('More'));
        await checkDestination('After cancel');
        await offerCopy();
        await tester.tapVisible(find.text('REPLACE THE RECORDS'));
        // The destination had zero operations. Wait for the updated Data
        // page before closing the database, even if the toast has faded.
        final operations = find.descendant(
          of: find.byType(BackupPage),
          matching: find.text('Operations'),
        );
        final counts = find
            .ancestor(of: operations, matching: find.byType(Column))
            .first;
        await tester.observeText(
          find.descendant(of: counts, matching: find.text('2')),
          'Restored operation count',
        );

        await reopen();
        await observeCafeLimit(tester, '₽1,700 left', 'Reopened limit');
        await tester.tapVisible(back);
        await tester.tapVisible(find.text('More'));
        await tester.tapVisible(find.text('Accounts'));
        await tester.waitForOne(find.text('Test card'));
        expect(find.text(marker), findsNothing);
        await tester.tapVisible(find.text('Test card'));
        await checkAccountHistory(
          tester,
          balance: '₽9,700',
          amounts: ['−₽10,150', '−₽150'],
        );
      },
    );
  });
}
