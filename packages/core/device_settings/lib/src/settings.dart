import 'package:device_settings/src/settings_store.dart';
import 'package:l10n/l10n.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// What a person picked for this device.
@immutable
final class Settings {
  /// Creates the settings.
  const Settings({
    this.language,
    this.hideAmountsOnLaunch = false,
    this.baseCurrency,
    this.onboarded = false,
  });

  /// Reads the settings from [store]. What is missing or unknown stays at its
  /// default.
  factory Settings.readFrom(SettingsStore store) {
    final language = store.read(_languageKey);
    final baseCurrency = store.read(_baseCurrencyKey);
    return Settings(
      language: AppLocale.values
          .where((locale) => locale.languageCode == language)
          .firstOrNull,
      hideAmountsOnLaunch: store.read(_hideAmountsKey) == _on,
      baseCurrency: offeredCurrencies
          .where((currency) => currency.code == baseCurrency)
          .firstOrNull,
      onboarded: store.read(_onboardedKey) == _on,
    );
  }

  static const _languageKey = 'language';
  static const _hideAmountsKey = 'hide-amounts-on-launch';
  static const _baseCurrencyKey = 'base-currency';
  static const _onboardedKey = 'onboarded';
  static const _sameAsDevice = 'device';
  static const _firstAccount = 'first-account';
  static const _on = 'on';
  static const _off = 'off';

  /// The language of the app, or `null` to follow the device.
  final AppLocale? language;

  /// Whether the amounts are hidden when the app opens. The eye can show them
  /// until it closes.
  final bool hideAmountsOnLaunch;

  /// The currency that totals are shown in, or `null` to follow the first
  /// account.
  final Currency? baseCurrency;

  /// Whether this device has been through the onboarding or has skipped it.
  final bool onboarded;

  /// A copy with the given fields changed. [language] and [baseCurrency] are
  /// in records, because `null` is a choice for them.
  Settings copyWith({
    (AppLocale?,)? language,
    bool? hideAmountsOnLaunch,
    (Currency?,)? baseCurrency,
    bool? onboarded,
  }) {
    return Settings(
      language: language == null ? this.language : language.$1,
      hideAmountsOnLaunch: hideAmountsOnLaunch ?? this.hideAmountsOnLaunch,
      baseCurrency: baseCurrency == null ? this.baseCurrency : baseCurrency.$1,
      onboarded: onboarded ?? this.onboarded,
    );
  }

  /// Keeps the settings in [store].
  Future<void> writeTo(SettingsStore store) async {
    await store.write(_languageKey, language?.languageCode ?? _sameAsDevice);
    await store.write(_hideAmountsKey, hideAmountsOnLaunch ? _on : _off);
    await store.write(_baseCurrencyKey, baseCurrency?.code ?? _firstAccount);
    await store.write(_onboardedKey, onboarded ? _on : _off);
  }

  /// Turns the strings to [language], or to [device] when none is picked.
  void applyLanguage({required String device}) {
    LocaleSettings.setLocaleRawSync(language?.languageCode ?? device);
  }
}
