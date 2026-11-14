import 'dart:ui';

import 'package:accounts_common/accounts_common.dart';
import 'package:ask_common/ask_common.dart';
import 'package:backup_common/backup_common.dart';
import 'package:backup_flutter/backup_flutter.dart';
import 'package:categories_common/categories_common.dart';
import 'package:database/database.dart';
import 'package:debts_common/debts_common.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:help_common/help_common.dart';
import 'package:help_flutter/help_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:import_common/import_common.dart';
import 'package:import_flutter/import_flutter.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:ledger/ledger.dart';
import 'package:notifications_common/notifications_common.dart';
import 'package:onboarding_common/onboarding_common.dart'
    show OnboardingRepository, onboardingNeeded, registerOnboarding;
import 'package:overview_common/overview_common.dart';
import 'package:rates/rates.dart';
import 'package:reports_common/reports_common.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_flutter/schedules_flutter.dart'
    show DeviceReminderCalendar, LocalReminderChannel;
import 'package:settings_common/settings_common.dart';
import 'package:tags_common/tags_common.dart';
import 'package:transactions_common/transactions_common.dart';

/// The notifications of the phone. One serves the whole life of the app, as
/// a ledger opens anew, so that the tap that opened the app opens the
/// payments once (ADR 0025).
final ReminderChannel _reminders = LocalReminderChannel();

/// The language that the device reports.
String deviceLanguage() => PlatformDispatcher.instance.locale.languageCode;

/// Opens the ledger that [settings] point to, the one of the device or of its
/// demo, with every object of the app on it, after closing whatever [getIt]
/// held. A demo that has just come on fills first (ADR 0019). Says whether a
/// new device starts with the onboarding.
Future<bool> openLedger(GetIt getIt, SettingsStore settings) async {
  await getIt.reset();
  final name = databaseNameIn(settings);
  registerDependencies(getIt, settings, databaseName: name);
  await settleDemo(
    settings,
    getIt<LedgerRepository>(),
    opened: name,
    now: DateTime.now(),
  );
  return onboardingNeeded(settings, getIt<OnboardingRepository>());
}

/// Puts the objects of the app into [getIt]: the one place that knows every
/// implementation (ADR 0006). The database [databaseName] opens on its first
/// query, and [settings] are already open, because the language comes first.
void registerDependencies(
  GetIt getIt,
  SettingsStore settings, {
  required String databaseName,
}) {
  final database = BirkaDatabase(driftDatabase(name: databaseName));
  final ledger = LedgerRepository(database);
  final rates = RatesRepository(database);
  final kept = Settings.readFrom(settings);
  final baseCurrency = BaseCurrency(kept.baseCurrency);
  getIt
    ..registerSingleton(database, dispose: (database) => database.close())
    ..registerSingleton(ledger)
    ..registerSingleton(rates)
    ..registerSingleton(baseCurrency)
    ..registerSingleton(MonthStart(kept.monthStart))
    ..registerSingleton(
      RatesUpdater(rates, CbrMirror(http.Client()), ledger, baseCurrency),
    )
    ..registerSingleton<BackupFiles>(const FilePickerBackupFiles())
    ..registerSingleton<StatementFiles>(const FilePickerStatementFiles())
    ..registerSingleton<HelpLinks>(const UrlLauncherHelpLinks())
    ..registerSingleton<ReminderChannel>(_reminders)
    ..registerSingleton<ReminderCalendar>(DeviceReminderCalendar(settings));
  registerAccounts(getIt);
  registerAsk(getIt);
  registerBackup(getIt, settings);
  registerCategories(getIt);
  registerDebts(getIt);
  registerHelp(getIt, about: readAppAbout);
  registerImport(getIt, settings);
  registerInbox(getIt, settings);
  registerNotifications(getIt);
  registerOnboarding(getIt, settings, deviceLanguage: deviceLanguage);
  registerOverview(getIt);
  registerReports(getIt);
  registerSchedules(getIt, settings);
  registerSettings(getIt, settings, deviceLanguage: deviceLanguage);
  registerTags(getIt);
  registerTransactions(getIt);
}
