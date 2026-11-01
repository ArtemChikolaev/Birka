import 'package:bloc/bloc.dart';
import 'package:device_settings/device_settings.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Changes the settings of this device. The host listens to
/// `LocaleSettings.getLocaleStream()` to redraw in a new language.
class SettingsCubit extends Cubit<Settings> {
  /// Creates the cubit on [_store]. [deviceLanguage] is the language that the
  /// device reports, and [baseCurrency] is what the screens follow.
  SettingsCubit(
    this._store, {
    required String deviceLanguage,
    required BaseCurrency baseCurrency,
  }) : _deviceLanguage = deviceLanguage,
       _baseCurrency = baseCurrency,
       super(Settings.readFrom(_store));

  final SettingsStore _store;
  final String _deviceLanguage;
  final BaseCurrency _baseCurrency;

  /// Picks [language], or follows the device with `null`. The strings turn to
  /// it once it is kept, so that a redraw reads the new value.
  Future<void> languageChanged(AppLocale? language) async {
    if (language == state.language) return;
    final next = state.copyWith(language: (language,));
    emit(next);
    await next.writeTo(_store);
    next.applyLanguage(device: _deviceLanguage);
  }

  /// Sets whether the amounts are hidden from the next launch on.
  Future<void> hideAmountsOnLaunchChanged({required bool hide}) async {
    final next = state.copyWith(hideAmountsOnLaunch: hide);
    emit(next);
    await next.writeTo(_store);
  }

  /// Shows totals in [currency], or in that of the first account with `null`.
  /// The screens follow at once.
  Future<void> baseCurrencyChanged(Currency? currency) async {
    if (currency == state.baseCurrency) return;
    final next = state.copyWith(baseCurrency: (currency,));
    emit(next);
    _baseCurrency.choose(currency);
    await next.writeTo(_store);
  }
}
