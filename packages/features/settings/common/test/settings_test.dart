import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';
import 'package:test/test.dart';

import 'fake_settings_store.dart';

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('a device with nothing kept has the defaults', () {
    final settings = Settings.readFrom(FakeSettingsStore());

    expect(settings.language, isNull);
    expect(settings.hideAmountsOnLaunch, isFalse);
  });

  test('comes back the way it was kept', () async {
    final store = FakeSettingsStore();

    await const Settings(
      language: AppLocale.ru,
      hideAmountsOnLaunch: true,
      baseCurrency: Currency.eur,
    ).writeTo(store);
    final settings = Settings.readFrom(store);

    expect(settings.language, AppLocale.ru);
    expect(settings.hideAmountsOnLaunch, isTrue);
    expect(settings.baseCurrency, Currency.eur);
  });

  test('a currency that this version does not offer follows the account', () {
    final store = FakeSettingsStore({'base-currency': 'XXX'});

    expect(Settings.readFrom(store).baseCurrency, isNull);
  });

  test('a base currency goes by its name, and none by what it follows', () {
    expect(baseCurrencyLabel(Currency.eur), 'Euro');
    expect(baseCurrencyLabel(null), 'First account');
    expect(baseCurrencyChoices.first, isNull);
    expect(baseCurrencyChoices, hasLength(10));
  });

  test('the language of the device comes back as no choice', () async {
    final store = FakeSettingsStore();

    await const Settings(language: AppLocale.ru).writeTo(store);
    await const Settings().writeTo(store);

    expect(Settings.readFrom(store).language, isNull);
  });

  test('a language that this version does not know follows the device', () {
    final store = FakeSettingsStore({'language': 'tlh'});

    expect(Settings.readFrom(store).language, isNull);
  });

  test('a picked language wins over the device', () {
    const Settings(language: AppLocale.ru).applyLanguage(device: 'en');

    expect(LocaleSettings.currentLocale, AppLocale.ru);
  });

  test('with no pick the strings follow the device', () {
    const Settings().applyLanguage(device: 'ru');

    expect(LocaleSettings.currentLocale, AppLocale.ru);
  });

  test('the choices start with the device and hold every language', () {
    expect(languageChoices.first, isNull);
    expect(languageChoices.skip(1), AppLocale.values);
  });

  test('a language goes by its own name in every language', () {
    for (final locale in AppLocale.values) {
      LocaleSettings.setLocaleSync(locale);

      expect(languageLabel(AppLocale.en), 'English');
      expect(languageLabel(AppLocale.ru), 'Русский');
    }
  });

  test('the device goes by the words of the language', () {
    expect(languageLabel(null), 'Same as the device');

    LocaleSettings.setLocaleSync(AppLocale.ru);

    expect(languageLabel(null), 'Как на устройстве');
  });
}
