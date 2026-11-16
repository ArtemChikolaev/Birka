import 'package:get_it/get_it.dart';
import 'package:limits_common/src/data/ledger_limits_repository.dart';
import 'package:limits_common/src/domain/limits_repository.dart';
import 'package:limits_common/src/presentation/limit_form_cubit.dart';
import 'package:limits_common/src/presentation/limit_suggest_cubit.dart';
import 'package:limits_common/src/presentation/limits_cubit.dart';

/// Registers the limits in [getIt]; the host registers the ledger, the rates,
/// the base currency and the month start before (ADR 0033).
void registerLimits(GetIt getIt) {
  getIt
    ..registerLazySingleton<LimitsRepository>(
      () => LedgerLimitsRepository(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactory(() => LimitsCubit(getIt()))
    // The form takes the category of the limit it changes, or of a new one.
    ..registerFactoryParam<LimitFormCubit, String?, void>(
      (id, _) => LimitFormCubit(getIt(), categoryId: id),
    )
    ..registerFactory(() => LimitSuggestCubit(getIt()));
}
