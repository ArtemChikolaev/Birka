import 'package:device_settings/device_settings.dart';
import 'package:get_it/get_it.dart';
import 'package:inbox_common/src/data/ledger_inbox_repository.dart';
import 'package:inbox_common/src/domain/inbox_repository.dart';
import 'package:inbox_common/src/presentation/inbox_cubit.dart';

/// Registers the feature in [getIt], which has to know the `LedgerRepository`
/// and the `RatesRepository`, on the [store] of the host.
void registerInbox(GetIt getIt, SettingsStore store) {
  getIt
    ..registerLazySingleton<InboxRepository>(
      () => LedgerInboxRepository(getIt(), getIt()),
    )
    ..registerFactory(() => InboxCubit(getIt(), store));
}
