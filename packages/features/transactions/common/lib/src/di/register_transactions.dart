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
    // A new operation starts as an expense, or as the kind that a widget
    // of the home screen asks for (ADR 0031).
    ..registerFactoryParam<QuickAddCubit, QuickAddSource?, TransactionKind?>(
      (source, kind) => QuickAddCubit(
        getIt(),
        source: source,
        kind: kind ?? TransactionKind.expense,
      ),
    )
    ..registerFactoryParam<TagOperationsCubit, String, void>(
      (id, _) => TagOperationsCubit(getIt(), id),
    );
}
