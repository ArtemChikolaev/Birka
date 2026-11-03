import 'dart:async';

import 'package:birka_mobile/app/dependencies.dart';
import 'package:birka_mobile/app/preferences_settings_store.dart';
import 'package:birka_mobile/app/root.dart';
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
  final onboarding = await openLedger(GetIt.instance, settings);
  runApp(
    BirkaRoot(
      getIt: GetIt.instance,
      settings: settings,
      onboarding: onboarding,
    ),
  );
  // The rates of whichever ledger stands open.
  AppLifecycleListener(
    onResume: () => unawaited(GetIt.instance<RatesUpdater>().refresh()),
  );
}
