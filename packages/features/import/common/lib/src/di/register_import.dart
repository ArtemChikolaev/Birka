import 'package:get_it/get_it.dart';
import 'package:import_common/src/data/file_statement_reader.dart';
import 'package:import_common/src/data/ledger_import_repository.dart';
import 'package:import_common/src/domain/import_repository.dart';
import 'package:import_common/src/domain/statement_reader.dart';
import 'package:import_common/src/presentation/import_cubit.dart';

/// Registers the feature in [getIt], which has to know the `LedgerRepository`
/// and the `StatementFiles` of the host.
void registerImport(GetIt getIt) {
  getIt
    ..registerLazySingleton<ImportRepository>(
      () => LedgerImportRepository(getIt()),
    )
    ..registerLazySingleton<StatementReader>(() => const FileStatementReader())
    ..registerFactory(() => ImportCubit(getIt(), getIt(), getIt()));
}
