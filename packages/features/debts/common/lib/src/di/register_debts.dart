import 'package:debts_common/src/data/ledger_debts_repository.dart';
import 'package:debts_common/src/domain/debts_repository.dart';
import 'package:debts_common/src/presentation/debt_form_cubit.dart';
import 'package:debts_common/src/presentation/debt_return_cubit.dart';
import 'package:debts_common/src/presentation/debt_terms_cubit.dart';
import 'package:debts_common/src/presentation/debts_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:ledger/ledger.dart';

/// Registers the feature in [getIt], which has to know the `LedgerRepository`,
/// the `RatesRepository` and the `BaseCurrency` of the host. [reminders]
/// says whether this host reminds of debts: the site does not.
void registerDebts(GetIt getIt, {bool reminders = true}) {
  getIt
    ..registerLazySingleton<DebtsRepository>(
      () => LedgerDebtsRepository(getIt(), getIt(), getIt()),
    )
    ..registerFactory(() => DebtsCubit(getIt()))
    // The form of a new debt takes no id; «Ещё в долг» on a card gives the
    // debt, whose side the form then follows.
    ..registerFactoryParam<DebtFormCubit, String?, DebtSide?>(
      (id, side) => DebtFormCubit(
        getIt(),
        debtId: id,
        side: side ?? DebtSide.lent,
        reminders: reminders,
      ),
    )
    ..registerFactoryParam<DebtReturnCubit, String, void>(
      (id, _) => DebtReturnCubit(getIt(), id),
    )
    ..registerFactoryParam<DebtTermsCubit, String, void>(
      (id, _) => DebtTermsCubit(getIt(), id, reminders: reminders),
    );
}
