import 'dart:async';

import 'package:birka_web/app/browser.dart';
import 'package:birka_web/main.client.options.dart';
import 'package:jaspr/client.dart';

void main() {
  Jaspr.initializeApp(options: defaultClientOptions);
  // What nothing caught goes to the console, but not from a page that has
  // left and closed its database.
  runZonedGuarded(() => runApp(const ClientApp()), reportError);
}
