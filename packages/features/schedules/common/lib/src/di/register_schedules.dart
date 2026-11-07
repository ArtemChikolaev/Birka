import 'package:device_settings/device_settings.dart';
import 'package:get_it/get_it.dart';
import 'package:schedules_common/src/data/ledger_schedules_repository.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';
import 'package:schedules_common/src/presentation/reminder_scheduler.dart';
import 'package:schedules_common/src/presentation/reminders_cubit.dart';
import 'package:schedules_common/src/presentation/schedule_form_cubit.dart';
import 'package:schedules_common/src/presentation/schedules_cubit.dart';

/// Registers the feature in [getIt], which has to know the `LedgerRepository`,
/// the `BaseCurrency`, the `MonthStart` and the `ReminderChannel` of the
/// host, on the [store] of the host.
void registerSchedules(GetIt getIt, SettingsStore store) {
  getIt
    ..registerLazySingleton<SchedulesRepository>(
      () => LedgerSchedulesRepository(getIt(), getIt(), getIt(), store),
    )
    ..registerFactory(() => SchedulesCubit(getIt()))
    ..registerLazySingleton(
      () => ReminderScheduler(getIt(), getIt()),
      dispose: (scheduler) => scheduler.stop(),
    )
    ..registerFactory(() => RemindersCubit(getIt(), getIt()))
    ..registerFactoryParam<ScheduleFormCubit, String?, bool?>(
      (id, salary) =>
          ScheduleFormCubit(getIt(), id: id, salary: salary ?? false),
    );
}
