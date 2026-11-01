import 'package:l10n/l10n.dart';
import 'package:meta/meta.dart';
import 'package:settings_common/src/domain/settings_store.dart';

/// What a person picked for this device.
@immutable
final class Settings {
  /// Creates the settings.
  const Settings({this.language, this.hideAmountsOnLaunch = false});

  /// Reads the settings from [store]. What is missing or unknown stays at its
  /// default.
  factory Settings.readFrom(SettingsStore store) {
    final language = store.read(_languageKey);
    return Settings(
      language: AppLocale.values
          .where((locale) => locale.languageCode == language)
          .firstOrNull,
      hideAmountsOnLaunch: store.read(_hideAmountsKey) == _on,
    );
  }

  static const _languageKey = 'language';
  static const _hideAmountsKey = 'hide-amounts-on-launch';
  static const _sameAsDevice = 'device';
  static const _on = 'on';
  static const _off = 'off';

  /// The language of the app, or `null` to follow the device.
  final AppLocale? language;

  /// Whether the amounts are hidden when the app opens. The eye can show them
  /// until it closes.
  final bool hideAmountsOnLaunch;

  /// Keeps the settings in [store].
  Future<void> writeTo(SettingsStore store) async {
    await store.write(_languageKey, language?.languageCode ?? _sameAsDevice);
    await store.write(_hideAmountsKey, hideAmountsOnLaunch ? _on : _off);
  }

  /// Turns the strings to [language], or to [device] when none is picked.
  void applyLanguage({required String device}) {
    LocaleSettings.setLocaleRawSync(language?.languageCode ?? device);
  }
}
