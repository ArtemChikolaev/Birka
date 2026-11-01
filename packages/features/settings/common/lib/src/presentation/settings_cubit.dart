import 'package:bloc/bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_common/src/domain/settings.dart';
import 'package:settings_common/src/domain/settings_store.dart';

/// Changes the settings of this device. The host listens to
/// `LocaleSettings.getLocaleStream()` to redraw in a new language.
class SettingsCubit extends Cubit<Settings> {
  /// Creates the cubit on [_store]. [deviceLanguage] is the language that the
  /// device reports.
  SettingsCubit(this._store, {required String deviceLanguage})
    : _deviceLanguage = deviceLanguage,
      super(Settings.readFrom(_store));

  final SettingsStore _store;
  final String _deviceLanguage;

  /// Picks [language], or follows the device with `null`. The strings turn to
  /// it once it is kept, so that a redraw reads the new value.
  Future<void> languageChanged(AppLocale? language) async {
    if (language == state.language) return;
    final next = Settings(
      language: language,
      hideAmountsOnLaunch: state.hideAmountsOnLaunch,
    );
    emit(next);
    await next.writeTo(_store);
    next.applyLanguage(device: _deviceLanguage);
  }

  /// Sets whether the amounts are hidden from the next launch on.
  Future<void> hideAmountsOnLaunchChanged({required bool hide}) async {
    final next = Settings(
      language: state.language,
      hideAmountsOnLaunch: hide,
    );
    emit(next);
    await next.writeTo(_store);
  }
}
