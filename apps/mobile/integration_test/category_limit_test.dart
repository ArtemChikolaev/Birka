import 'dart:io';

import 'package:birka_mobile/app/app.dart';
import 'package:birka_mobile/app/dependencies.dart';
import 'package:database/database.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_flutter/limits_flutter.dart';
import 'package:money/money.dart';
import 'package:settings_common/settings_common.dart';

/// Device preferences for this run. The installed app's settings stay private.
final class _Settings implements SettingsStore {
  final _values = <String, String>{};

  @override
  String? read(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('category limit survives saving, crossing it and reopening', (
    tester,
  ) async {
    final folder = await Directory.systemTemp.createTemp('birka-limits-');
    final settings = _Settings();
    final getIt = GetIt.asNewInstance();
    final locale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);

    void openDatabase() {
      final executor = driftDatabase(
        name: 'category-limit',
        native: DriftNativeOptions(
          databaseDirectory: () async => folder,
          tempDirectoryPath: () async => folder.path,
        ),
      );
      registerDependencies(getIt, settings, BirkaDatabase(executor));
    }

    Future<void> closeApp() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await getIt.reset();
    }

    Future<void> waitFor(Finder finder) async {
      final timer = Stopwatch()..start();
      while (finder.evaluate().isEmpty &&
          timer.elapsed < const Duration(seconds: 10)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(finder, findsOneWidget);
    }

    Future<void> tapVisible(Finder target) async {
      await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(target.hitTestable());
      await tester.pumpAndSettle();
    }

    Future<void> observe(Finder label, String step) async {
      await waitFor(label);
      final text = tester.widget<Text>(label);
      debugPrint('$step: ${text.data ?? text.textSpan!.toPlainText()}');
    }

    Future<void> openLimits(String expected, String step) async {
      final link = find.text('All limits · 1');
      await tester.scrollUntilVisible(
        link.hitTestable(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tapVisible(link);
      await observe(
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
      await waitFor(find.text('Cafe'));
      await tester.tap(find.text('Cafe'));
      for (final digit in digits.split('')) {
        await tester.tap(
          find.descendant(
            of: find.byType(GlassKeypad),
            matching: find.text(digit),
          ),
        );
        await tester.pump();
      }
      await observe(find.text(preview), 'Quick-add preview');
      await tapVisible(find.text('SAVE · CAFE'));
      await waitFor(find.bySemanticsLabel('New operation').hitTestable());
    }

    try {
      openDatabase();
      final ledger = getIt<LedgerRepository>();
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
      await tester.pumpWidget(BirkaApp(getIt: getIt));
      await tester.pumpAndSettle();
      await openLimits('₽1,850 left', 'Starting limit');
      await spend('1850', 'Cafe: ₽0 of ₽12,000 left');
      await openLimits('₽0 left', 'After saving ₽1,850');
      await spend('1', 'Cafe: ₽1 over the limit');
      await openLimits('₽1 over', 'After saving ₽1');
      await closeApp();

      openDatabase();
      await tester.pumpWidget(BirkaApp(getIt: getIt));
      await tester.pumpAndSettle();
      await openLimits('₽1 over', 'After reopening SQLite');
    } finally {
      try {
        await closeApp();
      } finally {
        LocaleSettings.setLocaleSync(locale);
        await folder.delete(recursive: true);
      }
    }
  });
}
