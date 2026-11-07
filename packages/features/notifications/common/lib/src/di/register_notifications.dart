import 'package:get_it/get_it.dart';
import 'package:notifications_common/src/data/ledger_notifications_repository.dart';
import 'package:notifications_common/src/domain/notifications_repository.dart';
import 'package:notifications_common/src/presentation/notifications_cubit.dart';
import 'package:notifications_common/src/presentation/notifications_summary_cubit.dart';

/// Registers the feature in [getIt], which has to know the `LedgerRepository`.
void registerNotifications(GetIt getIt) {
  getIt
    ..registerLazySingleton<NotificationsRepository>(
      () => LedgerNotificationsRepository(getIt()),
    )
    ..registerFactory(() => NotificationsCubit(getIt()))
    ..registerFactory(() => NotificationsSummaryCubit(getIt()));
}
