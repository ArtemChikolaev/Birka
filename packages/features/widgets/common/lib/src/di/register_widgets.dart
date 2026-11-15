import 'package:device_settings/device_settings.dart';
import 'package:get_it/get_it.dart';
import 'package:widgets_common/src/presentation/widgets_cubit.dart';

/// Registers the feature in [getIt], which has to know the `WidgetSums`, the
/// `HomeWidgets` and the `HomeScreen` of the host, on the [store] of the
/// host.
void registerWidgets(GetIt getIt, SettingsStore store) {
  getIt.registerFactory(() => WidgetsCubit(store, getIt(), getIt(), getIt()));
}
