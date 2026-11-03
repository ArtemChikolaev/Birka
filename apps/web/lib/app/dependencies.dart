import 'package:accounts_common/accounts_common.dart';
import 'package:backup_common/backup_common.dart';
import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/browser_settings_store.dart';
import 'package:categories_common/categories_common.dart';
import 'package:database/database.dart';
import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:ledger/ledger.dart';
import 'package:onboarding_common/onboarding_common.dart'
    show registerOnboarding;
import 'package:overview_common/overview_common.dart';
import 'package:rates/rates.dart';
import 'package:reports_common/reports_common.dart';
import 'package:settings_common/settings_common.dart' show Settings;
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
    ..registerSingleton<BackupFiles>(const BrowserBackupFiles())
    ..registerSingleton(
      RatesUpdater(
        rates,
        CbrMirror(http.Client(), inBrowser: true),
        ledger,
        baseCurrency,
      ),
    );
  registerAccounts(getIt);
  registerBackup(getIt, const BrowserSettingsStore());
  registerCategories(getIt);
  registerOnboarding(
    getIt,
    const BrowserSettingsStore(),
    deviceLanguage: () => browserLanguage,
  );
  registerOverview(getIt);
  registerReports(getIt);
  registerTransactions(getIt);
}
