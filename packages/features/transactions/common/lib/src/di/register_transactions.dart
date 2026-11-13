import 'package:get_it/get_it.dart';
import 'package:ledger/ledger.dart';
import 'package:transactions_common/src/data/ledger_transactions_repository.dart';
import 'package:transactions_common/src/domain/operations_focus.dart';
import 'package:transactions_common/src/domain/transactions_repository.dart';
import 'package:transactions_common/src/presentation/account_cubit.dart';
import 'package:transactions_common/src/presentation/operation_cubit.dart';
import 'package:transactions_common/src/presentation/operations_cubit.dart';
import 'package:transactions_common/src/presentation/quick_add_cubit.dart';
import 'package:transactions_common/src/presentation/tag_operations_cubit.dart';

/// Registers the feature in [getIt], which has to know the [LedgerRepository].
void registerTransactions(GetIt getIt) {
  getIt
    ..registerLazySingleton<TransactionsRepository>(
      () => LedgerTransactionsRepository(getIt()),
    )
    // The list of an answer of «Спросить» starts focused on its operations.
    ..registerFactoryParam<OperationsCubit, OperationsFocus?, void>(
      (focus, _) => OperationsCubit(getIt(), focus: focus),
    )
    ..registerFactoryParam<AccountCubit, String, void>(
      (id, _) => AccountCubit(getIt(), id),
    )
    ..registerFactoryParam<OperationCubit, String, void>(
      (id, _) => OperationCubit(getIt(), id),
    )
    ..registerFactoryParam<QuickAddCubit, QuickAddSource?, void>(
      (source, _) => QuickAddCubit(getIt(), source: source),
    )
    ..registerFactoryParam<TagOperationsCubit, String, void>(
      (id, _) => TagOperationsCubit(getIt(), id),
    );
}
