import 'package:device_settings/device_settings.dart';
import 'package:get_it/get_it.dart';
import 'package:inbox_common/src/data/ledger_inbox_repository.dart';
import 'package:inbox_common/src/domain/dismissed_pairs.dart';
import 'package:inbox_common/src/domain/inbox_repository.dart';
import 'package:inbox_common/src/presentation/inbox_cubit.dart';
import 'package:inbox_common/src/presentation/inbox_summary_cubit.dart';

/// Registers the feature in [getIt], which has to know the `LedgerRepository`
/// and the `RatesRepository`, on the [store] of the host. The inbox and the
/// ways to it share one [DismissedPairs].
void registerInbox(GetIt getIt, SettingsStore store) {
  getIt
    ..registerLazySingleton<InboxRepository>(
      () => LedgerInboxRepository(getIt(), getIt()),
    )
    ..registerLazySingleton(() => DismissedPairs(store))
    ..registerFactory(() => InboxCubit(getIt(), getIt()))
    ..registerFactory(() => InboxSummaryCubit(getIt(), getIt()));
}
