import 'package:ask_common/src/data/ledger_ask_repository.dart';
import 'package:ask_common/src/domain/ask_repository.dart';
import 'package:ask_common/src/presentation/ask_cubit.dart';
import 'package:get_it/get_it.dart';

/// Registers the feature in [getIt], which has to know the `LedgerRepository`,
/// the `RatesRepository`, the `BaseCurrency`, the `MonthStart` and the
/// `SettingsStore` of the host.
void registerAsk(GetIt getIt) {
  getIt
    ..registerLazySingleton<AskRepository>(
      () => LedgerAskRepository(getIt(), getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactory(() => AskCubit(getIt()));
}
