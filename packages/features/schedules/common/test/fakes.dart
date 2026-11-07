import 'package:device_settings/device_settings.dart';

/// Keeps settings in memory.
final class MemorySettingsStore implements SettingsStore {
  /// The kept values.
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
