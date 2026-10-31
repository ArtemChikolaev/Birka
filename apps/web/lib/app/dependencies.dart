import 'package:accounts_common/accounts_common.dart';
import 'package:categories_common/categories_common.dart';
import 'package:database/database.dart';
import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import 'package:ledger/ledger.dart';
import 'package:transactions_common/transactions_common.dart';

/// Puts the objects of the app into [getIt]: the one place that knows every
/// implementation (ADR 0006).
void registerDependencies(GetIt getIt, QueryExecutor executor) {
  final database = BirkaDatabase(executor);
  getIt
    ..registerSingleton(database)
    ..registerSingleton(LedgerRepository(database));
  registerAccounts(getIt);
  registerCategories(getIt);
  registerTransactions(getIt);
}
