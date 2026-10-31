import 'package:get_it/get_it.dart';
import 'package:ledger/ledger.dart';
import 'package:transactions_common/src/data/ledger_transactions_repository.dart';
import 'package:transactions_common/src/domain/transactions_repository.dart';
import 'package:transactions_common/src/presentation/quick_add_cubit.dart';

/// Registers the feature in [getIt], which has to know the [LedgerRepository].
void registerTransactions(GetIt getIt) {
  getIt
    ..registerLazySingleton<TransactionsRepository>(
      () => LedgerTransactionsRepository(getIt()),
    )
    ..registerFactory(() => QuickAddCubit(getIt()));
}
