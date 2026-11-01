import 'dart:async';

import 'package:birka_mobile/app/app.dart';
import 'package:birka_mobile/app/dependencies.dart';
import 'package:birka_mobile/app/preferences_settings_store.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:rates/rates.dart';
import 'package:settings_common/settings_common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final settings = await PreferencesSettingsStore.open();
  Settings.readFrom(settings).applyLanguage(device: deviceLanguage());
  // Android before 15 keeps apps out of the area of the system bars.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  registerDependencies(GetIt.instance, settings);
  runApp(BirkaApp(getIt: GetIt.instance));
  // The first frame waits for no network (ADR 0012).
  final rates = GetIt.instance<RatesUpdater>();
  unawaited(rates.refresh());
  AppLifecycleListener(onResume: () => unawaited(rates.refresh()));
  // Another base currency needs the rates of other days.
  final choices = GetIt.instance<BaseCurrency>().watch().skip(1);
  unawaited(choices.forEach((_) => rates.refresh()));
}
