import 'package:device_settings/device_settings.dart';

/// The settings in memory.
final class FakeSettingsStore implements SettingsStore {
  /// Creates a store that holds [values].
  FakeSettingsStore([Map<String, String>? values]) : values = values ?? {};

  /// What the store holds.
  final Map<String, String> values;

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
