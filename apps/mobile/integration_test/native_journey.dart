import 'dart:io';

import 'package:birka_mobile/app/app.dart';
import 'package:birka_mobile/app/dependencies.dart';
import 'package:database/database.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:settings_common/settings_common.dart';

/// Device preferences for this run. The installed app's settings stay private.
final class _Settings implements SettingsStore {
  final _values = <String, String>{};

  @override
  String? read(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

/// Runs Birka with a new SQLite ledger and the real host registrations.
/// The callback can unmount the app and reopen the same on-disk ledger.
Future<void> withNativeLedger(
  WidgetTester tester, {
  required String name,
  required Future<void> Function(LedgerRepository) seed,
  required Future<void> Function(Future<void> Function() reopen) journey,
}) async {
  final folder = await Directory.systemTemp.createTemp('birka-$name-');
  final settings = _Settings();
  final getIt = GetIt.asNewInstance();
  final locale = LocaleSettings.currentLocale;
  LocaleSettings.setLocaleSync(AppLocale.en);

  void openDatabase() {
    final executor = driftDatabase(
      name: name,
      native: DriftNativeOptions(
        databaseDirectory: () async => folder,
        tempDirectoryPath: () async => folder.path,
      ),
    );
    registerDependencies(getIt, settings, BirkaDatabase(executor));
  }

  Future<void> closeApp() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.settleJourney();
    await getIt.reset();
  }

  Future<void> openApp() async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.settleJourney();
  }

  try {
    openDatabase();
    await seed(getIt<LedgerRepository>());
    await openApp();
    await journey(() async {
      await closeApp();
      openDatabase();
      await openApp();
    });
  } finally {
    try {
      await closeApp();
    } finally {
      LocaleSettings.setLocaleSync(locale);
      await folder.delete(recursive: true);
    }
  }
}

/// Actions used by native verification journeys.
extension NativeJourneyActions on WidgetTester {
  /// Lets a route or a save animation complete within a bounded wait.
  Future<void> settleJourney() async {
    await pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    ).timeout(const Duration(seconds: 12));
  }

  /// Waits for an asynchronously loaded control or value.
  Future<void> waitForOne(Finder finder) async {
    final timer = Stopwatch()..start();
    while (finder.evaluate().isEmpty &&
        timer.elapsed < const Duration(seconds: 10)) {
      await pump(
        const Duration(milliseconds: 100),
      ).timeout(const Duration(seconds: 10));
    }
    expect(finder, findsOneWidget);
  }

  /// Brings a control into view and taps it where it receives pointers.
  Future<void> tapVisible(Finder target) async {
    await waitForOne(target);
    await Scrollable.ensureVisible(element(target), alignment: 0.5);
    await settleJourney();
    await tap(target.hitTestable());
    await settleJourney();
  }

  /// Records the text rendered at this step in the verification report.
  Future<void> observeText(Finder label, String step) async {
    await waitForOne(label);
    final text = widget<Text>(label);
    debugPrint('$step: ${text.data ?? text.textSpan!.toPlainText()}');
  }

  /// Enters an amount on the sheet's keypad.
  Future<void> typeAmount(String digits) async {
    for (final digit in digits.split('')) {
      await tapVisible(
        find.descendant(
          of: find.byType(GlassKeypad),
          matching: find.text(digit),
        ),
      );
    }
  }
}
