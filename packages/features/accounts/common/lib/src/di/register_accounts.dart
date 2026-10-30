import 'package:accounts_common/src/data/ledger_accounts_repository.dart';
import 'package:accounts_common/src/domain/accounts_repository.dart';
import 'package:accounts_common/src/presentation/account_form_cubit.dart';
import 'package:accounts_common/src/presentation/accounts_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:ledger/ledger.dart';

/// Registers the feature in [getIt], which has to know the [LedgerRepository].
void registerAccounts(GetIt getIt) {
  getIt
    ..registerLazySingleton<AccountsRepository>(
      () => LedgerAccountsRepository(getIt()),
    )
    ..registerFactory(() => AccountsCubit(getIt()))
    ..registerFactoryParam<AccountFormCubit, String?, void>(
      (accountId, _) => AccountFormCubit(getIt(), accountId: accountId),
    );
}
