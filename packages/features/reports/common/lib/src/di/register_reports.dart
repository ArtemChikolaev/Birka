import 'package:get_it/get_it.dart';
import 'package:ledger/ledger.dart';
import 'package:reports_common/src/data/ledger_reports_repository.dart';
import 'package:reports_common/src/domain/reports_repository.dart';
import 'package:reports_common/src/presentation/reports_cubit.dart';

/// Registers the feature in [getIt], which has to know the [LedgerRepository],
/// the `RatesRepository` and the `BaseCurrency`.
void registerReports(GetIt getIt) {
  getIt
    ..registerLazySingleton<ReportsRepository>(
      () => LedgerReportsRepository(getIt(), getIt(), getIt()),
    )
    ..registerFactory(() => ReportsCubit(getIt()));
}
