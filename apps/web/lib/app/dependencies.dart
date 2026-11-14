import 'package:accounts_common/accounts_common.dart';
import 'package:ask_common/ask_common.dart' show registerAsk;
import 'package:backup_common/backup_common.dart';
import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/browser_settings_store.dart';
import 'package:categories_common/categories_common.dart';
import 'package:database/database.dart';
import 'package:debts_common/debts_common.dart' show registerDebts;
import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:import_common/import_common.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:ledger/ledger.dart';
import 'package:notifications_common/notifications_common.dart'
    show registerNotifications;
import 'package:onboarding_common/onboarding_common.dart'
    show registerOnboarding;
import 'package:overview_common/overview_common.dart';
import 'package:rates/rates.dart';
import 'package:reports_common/reports_common.dart';
import 'package:schedules_common/schedules_common.dart' show registerSchedules;
import 'package:settings_common/settings_common.dart'
    show MonthStart, Settings, SettingsStore;
import 'package:tags_common/tags_common.dart' show registerTags;
import 'package:transactions_common/transactions_common.dart';

/// Puts the objects of the app into [getIt]: the one place that knows every
/// implementation (ADR 0006).
void registerDependencies(GetIt getIt, QueryExecutor executor) {
  final database = BirkaDatabase(executor);
  final ledger = LedgerRepository(database);
  final rates = RatesRepository(database);
  final settings = Settings.readFrom(const BrowserSettingsStore());
  final baseCurrency = BaseCurrency(settings.baseCurrency);
  getIt
    ..registerSingleton(database)
    ..registerSingleton(ledger)
    ..registerSingleton(rates)
    ..registerSingleton(baseCurrency)
    ..registerSingleton(MonthStart(settings.monthStart))
    ..registerSingleton<SettingsStore>(const BrowserSettingsStore())
    ..registerSingleton<BackupFiles>(const BrowserBackupFiles())
    ..registerSingleton<StatementFiles>(const BrowserStatementFiles())
    ..registerSingleton(
      RatesUpdater(
        rates,
        CbrMirror(http.Client(), inBrowser: true),
        ledger,
        baseCurrency,
      ),
    );
  registerAccounts(getIt);
  registerAsk(getIt);
  registerBackup(getIt, const BrowserSettingsStore());
  registerCategories(getIt);
  // The site has no reminders, so a day of a debt turns none on.
  registerDebts(getIt, reminders: false);
  registerImport(getIt, const BrowserSettingsStore());
  registerInbox(getIt, const BrowserSettingsStore());
  registerOnboarding(
    getIt,
    const BrowserSettingsStore(),
    deviceLanguage: () => browserLanguage,
  );
  registerNotifications(getIt);
  registerOverview(getIt);
  registerReports(getIt);
  // The site has no reminders: what needs them is never asked for here.
  registerSchedules(getIt, const BrowserSettingsStore());
  registerTags(getIt);
  registerTransactions(getIt);
}
