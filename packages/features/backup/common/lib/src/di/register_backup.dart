import 'package:backup_common/src/data/ledger_backup_repository.dart';
import 'package:backup_common/src/domain/backup_repository.dart';
import 'package:backup_common/src/presentation/backup_cubit.dart';
import 'package:device_settings/device_settings.dart';
import 'package:get_it/get_it.dart';
import 'package:ledger/ledger.dart';

/// Registers the feature in [getIt], which has to know the [LedgerRepository]
/// and the `BackupFiles` of the host, on the [store] of the host.
void registerBackup(GetIt getIt, SettingsStore store) {
  getIt
    ..registerLazySingleton<BackupRepository>(
      () => LedgerBackupRepository(getIt()),
    )
    ..registerFactory(() => BackupCubit(getIt(), getIt(), store));
}
