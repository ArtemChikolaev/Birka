import 'package:device_settings/device_settings.dart';
import 'package:get_it/get_it.dart';
import 'package:ledger/ledger.dart';
import 'package:onboarding_common/src/data/ledger_onboarding_repository.dart';
import 'package:onboarding_common/src/domain/onboarding_repository.dart';
import 'package:onboarding_common/src/presentation/onboarding_cubit.dart';
import 'package:rates/rates.dart';

/// Registers the feature in [getIt], which has to know the [LedgerRepository]
/// and the [BaseCurrency], on the [store] of the host and the language that
/// the device reports at the moment.
void registerOnboarding(
  GetIt getIt,
  SettingsStore store, {
  required String Function() deviceLanguage,
}) {
  getIt
    ..registerLazySingleton<OnboardingRepository>(
      () => LedgerOnboardingRepository(getIt()),
    )
    ..registerFactory(
      () => OnboardingCubit(
        getIt(),
        store,
        deviceLanguage: deviceLanguage(),
        baseCurrency: getIt(),
      ),
    );
}
