import 'dart:ui';

import 'package:accounts_common/accounts_common.dart';
import 'package:categories_common/categories_common.dart';
import 'package:database/database.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:ledger/ledger.dart';
import 'package:overview_common/overview_common.dart';
import 'package:reports_common/reports_common.dart';
import 'package:settings_common/settings_common.dart';
import 'package:transactions_common/transactions_common.dart';

/// The language that the device reports.
String deviceLanguage() => PlatformDispatcher.instance.locale.languageCode;

/// Puts the objects of the app into [getIt]: the one place that knows every
/// implementation (ADR 0006). The database opens on its first query, and
/// [settings] are already open, because the language comes first.
void registerDependencies(GetIt getIt, SettingsStore settings) {
  final database = BirkaDatabase(driftDatabase(name: 'birka'));
  getIt
    ..registerSingleton(database)
    ..registerSingleton(LedgerRepository(database));
  registerAccounts(getIt);
  registerCategories(getIt);
  registerOverview(getIt);
  registerReports(getIt);
  registerSettings(getIt, settings, deviceLanguage: deviceLanguage);
  registerTransactions(getIt);
}
