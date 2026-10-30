import 'dart:ui';

import 'package:birka_mobile/app/app.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  LocaleSettings.setLocaleRawSync(
    PlatformDispatcher.instance.locale.languageCode,
  );
  // Android before 15 keeps apps out of the area of the system bars.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const BirkaApp());
}
