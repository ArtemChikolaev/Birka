import 'package:device_settings/device_settings.dart';
import 'package:get_it/get_it.dart';
import 'package:rates/rates.dart';
import 'package:settings_common/src/presentation/settings_cubit.dart';

/// Registers the feature in [getIt], which has to know the [BaseCurrency] and
/// the [MonthStart], on the [store] of the host and the language that the
/// device reports at the moment.
void registerSettings(
  GetIt getIt,
  SettingsStore store, {
  required String Function() deviceLanguage,
}) {
  getIt
    ..registerSingleton(store)
    ..registerFactory(
      () => SettingsCubit(
        getIt(),
        deviceLanguage: deviceLanguage(),
        baseCurrency: getIt(),
        monthStart: getIt(),
      ),
    );
}
