import 'package:settings_common/settings_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The settings of this device, in its shared preferences (ADR 0011).
final class PreferencesSettingsStore implements SettingsStore {
  PreferencesSettingsStore._(this._preferences);

  /// Opens the preferences and holds them in memory, so that reading is
  /// immediate.
  static Future<PreferencesSettingsStore> open() async {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    return PreferencesSettingsStore._(preferences);
  }

  final SharedPreferencesWithCache _preferences;

  @override
  String? read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}
