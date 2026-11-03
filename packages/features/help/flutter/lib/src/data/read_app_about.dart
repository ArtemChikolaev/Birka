import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:help_common/help_common.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Reads what the letters say about the app on this device. A part that the
/// system keeps to itself shows as `?` instead of failing the help.
Future<AppAbout> readAppAbout() async {
  var version = '?';
  var build = '?';
  try {
    final package = await PackageInfo.fromPlatform();
    version = package.version;
    build = package.buildNumber;
  } on Object {
    // The letter still goes, with less in it.
  }
  return AppAbout(
    version: version,
    build: build,
    system: await _system(),
    locale: PlatformDispatcher.instance.locale.toLanguageTag(),
  );
}

/// `Android 14`, `iOS 26.0` or `macOS 15.1`.
Future<String> _system() async {
  final device = DeviceInfoPlugin();
  try {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android ${(await device.androidInfo).version.release}';
      case TargetPlatform.iOS:
        final info = await device.iosInfo;
        return '${info.systemName} ${info.systemVersion}';
      case TargetPlatform.macOS:
        final info = await device.macOsInfo;
        return 'macOS ${info.majorVersion}.${info.minorVersion}';
      case TargetPlatform.fuchsia ||
          TargetPlatform.linux ||
          TargetPlatform.windows:
        return defaultTargetPlatform.name;
    }
  } on Object {
    return defaultTargetPlatform.name;
  }
}
