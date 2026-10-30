import 'package:birka_mobile/app/app.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  // Android before 15 keeps apps out of the area of the system bars.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const BirkaApp());
}
