import 'package:get_it/get_it.dart';
import 'package:ledger/ledger.dart';
import 'package:overview_common/src/data/ledger_overview_repository.dart';
import 'package:overview_common/src/domain/overview_repository.dart';
import 'package:overview_common/src/presentation/overview_cubit.dart';

/// Registers the feature in [getIt], which has to know the [LedgerRepository].
void registerOverview(GetIt getIt) {
  getIt
    ..registerLazySingleton<OverviewRepository>(
      () => LedgerOverviewRepository(getIt()),
    )
    ..registerFactory(() => OverviewCubit(getIt()));
}
