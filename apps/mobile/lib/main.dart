import 'dart:async';

import 'package:backup_common/backup_common.dart' show demoStateIn;
import 'package:birka_mobile/app/dependencies.dart';
import 'package:birka_mobile/app/preferences_settings_store.dart';
import 'package:birka_mobile/app/root.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:rates/rates.dart';
import 'package:schedules_common/schedules_common.dart';
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
  // The regular payments that post themselves and whose day came while the
  // app was closed (ADR 0023).
  unawaited(GetIt.instance<SchedulesRepository>().postDue());
  // The rates and the regular payments of whichever ledger stands open.
  AppLifecycleListener(
    onResume: () {
      unawaited(GetIt.instance<RatesUpdater>().refresh());
      unawaited(GetIt.instance<SchedulesRepository>().postDue());
      // A new day drops the reminders that came and plans further ones.
      if (!demoStateIn(settings).isOn) {
        unawaited(GetIt.instance<ReminderScheduler>().refresh());
      }
    },
  );
}
