import 'package:flutter/services.dart';

const MethodChannel _settings = MethodChannel('birka/settings');

/// Opens the page of Birka in the settings of the phone, where its camera
/// can be allowed (ADR 0032). A phone that cannot open it leaves things as
/// they are.
Future<void> openAppSettings() async {
  try {
    await _settings.invokeMethod<void>('open');
  } on PlatformException {
    // The page of the app did not open; the scanner stays where it is.
  } on MissingPluginException {
    // A host without the channel, such as a test.
  }
}
