import 'package:device_settings/device_settings.dart';
import 'package:get_it/get_it.dart';
import 'package:schedules_common/src/data/ledger_schedules_repository.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';
import 'package:schedules_common/src/presentation/operation_schedule_cubit.dart';
import 'package:schedules_common/src/presentation/reminder_notices.dart';
import 'package:schedules_common/src/presentation/reminder_scheduler.dart';
import 'package:schedules_common/src/presentation/reminders_cubit.dart';
import 'package:schedules_common/src/presentation/schedule_form_cubit.dart';
import 'package:schedules_common/src/presentation/schedules_cubit.dart';

/// Registers the feature in [getIt], which has to know the `LedgerRepository`,
/// the `BaseCurrency`, the `MonthStart`, the `ReminderChannel` and the
/// `ReminderCalendar` of the host, on the [store] of the host.
void registerSchedules(GetIt getIt, SettingsStore store) {
  getIt
    ..registerLazySingleton<SchedulesRepository>(
      () => LedgerSchedulesRepository(getIt(), getIt(), getIt(), store),
    )
    ..registerFactory(() => SchedulesCubit(getIt()))
    ..registerLazySingleton(
      () => ReminderScheduler(getIt(), getIt(), getIt()),
      dispose: (scheduler) => scheduler.stop(),
    )
    ..registerLazySingleton(
      () => ReminderNotices(getIt()),
      dispose: (notices) => notices.stop(),
    )
    ..registerFactory(() => RemindersCubit(getIt(), getIt(), getIt()))
    // A new payment starts empty, as a salary, or from an operation.
    ..registerFactoryParam<
      ScheduleFormCubit,
      String?,
      ({bool salary, String? from})?
    >(
      (id, start) => ScheduleFormCubit(
        getIt(),
        id: id,
        salary: start?.salary ?? false,
        from: start?.from,
      ),
    )
    ..registerFactoryParam<OperationScheduleCubit, String, void>(
      (id, _) => OperationScheduleCubit(getIt(), id),
    );
}
