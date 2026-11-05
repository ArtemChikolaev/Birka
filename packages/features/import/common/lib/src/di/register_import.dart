import 'package:device_settings/device_settings.dart';
import 'package:get_it/get_it.dart';
import 'package:import_common/src/data/file_statement_reader.dart';
import 'package:import_common/src/data/ledger_import_repository.dart';
import 'package:import_common/src/domain/import_memory.dart';
import 'package:import_common/src/domain/import_repository.dart';
import 'package:import_common/src/domain/statement_reader.dart';
import 'package:import_common/src/presentation/import_cubit.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Registers the feature in [getIt], which has to know the `LedgerRepository`,
/// the [BaseCurrency] and the `StatementFiles` of the host, on the [store]
/// of the host, which keeps what the next file of a format reuses.
void registerImport(GetIt getIt, SettingsStore store) {
  getIt
    ..registerLazySingleton<ImportRepository>(
      () => LedgerImportRepository(getIt()),
    )
    ..registerLazySingleton<StatementReader>(() => const FileStatementReader())
    ..registerFactory(
      () => ImportCubit(
        getIt(),
        getIt(),
        getIt(),
        currency: getIt<BaseCurrency>().value ?? Currency.rub,
        remembered: ImportMemory(store),
      ),
    );
}
