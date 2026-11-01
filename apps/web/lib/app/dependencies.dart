import 'package:accounts_common/accounts_common.dart';
import 'package:birka_web/app/browser_settings_store.dart';
import 'package:categories_common/categories_common.dart';
import 'package:database/database.dart';
import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:ledger/ledger.dart';
import 'package:overview_common/overview_common.dart';
import 'package:rates/rates.dart';
import 'package:reports_common/reports_common.dart';
import 'package:settings_common/settings_common.dart' show Settings;
import 'package:transactions_common/transactions_common.dart';

/// Puts the objects of the app into [getIt]: the one place that knows every
/// implementation (ADR 0006).
void registerDependencies(GetIt getIt, QueryExecutor executor) {
  final database = BirkaDatabase(executor);
  final rates = RatesRepository(database);
  final settings = Settings.readFrom(const BrowserSettingsStore());
  getIt
    ..registerSingleton(database)
    ..registerSingleton(LedgerRepository(database))
    ..registerSingleton(rates)
    ..registerSingleton(BaseCurrency(settings.baseCurrency))
    ..registerSingleton(RatesUpdater(rates, CbrMirror(http.Client())));
  registerAccounts(getIt);
  registerCategories(getIt);
  registerOverview(getIt);
  registerReports(getIt);
  registerTransactions(getIt);
}
