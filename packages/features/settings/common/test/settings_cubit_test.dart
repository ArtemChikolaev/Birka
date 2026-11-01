import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';
import 'package:test/test.dart';

import 'fake_settings_store.dart';

void main() {
  late FakeSettingsStore store;
  late BaseCurrency baseCurrency;
  late SettingsCubit cubit;

  setUp(() {
    store = FakeSettingsStore();
    baseCurrency = BaseCurrency(null);
    cubit = SettingsCubit(
      store,
      deviceLanguage: 'en',
      baseCurrency: baseCurrency,
    );
  });
  tearDown(() async {
    await cubit.close();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  test('starts on what the store holds', () async {
    await cubit.close();
    await const Settings(
      language: AppLocale.ru,
      hideAmountsOnLaunch: true,
    ).writeTo(store);

    cubit = SettingsCubit(
      store,
      deviceLanguage: 'en',
      baseCurrency: baseCurrency,
    );

    expect(cubit.state.language, AppLocale.ru);
    expect(cubit.state.hideAmountsOnLaunch, isTrue);
  });

  test('a new language turns the strings and stays', () async {
    await cubit.languageChanged(AppLocale.ru);

    expect(cubit.state.language, AppLocale.ru);
    expect(LocaleSettings.currentLocale, AppLocale.ru);
    expect(Settings.readFrom(store).language, AppLocale.ru);
  });

  test('the strings turn only after the language is kept', () async {
    AppLocale? kept;
    final subscription = LocaleSettings.getLocaleStream().listen(
      (_) => kept = Settings.readFrom(store).language,
    );

    await cubit.languageChanged(AppLocale.ru);
    await pumpEventQueue();
    await subscription.cancel();

    expect(kept, AppLocale.ru);
  });

  test('going back to the device turns the strings to its language', () async {
    await cubit.languageChanged(AppLocale.ru);

    await cubit.languageChanged(null);

    expect(cubit.state.language, isNull);
    expect(LocaleSettings.currentLocale, AppLocale.en);
    expect(Settings.readFrom(store).language, isNull);
  });

  test('the same language changes nothing', () async {
    var turns = 0;
    final subscription = LocaleSettings.getLocaleStream().listen(
      (_) => turns++,
    );

    await cubit.languageChanged(null);
    await pumpEventQueue();
    await subscription.cancel();

    expect(turns, 0);
    expect(store.values, isEmpty);
  });

  test('hiding the amounts stays and keeps the language', () async {
    await cubit.languageChanged(AppLocale.ru);

    await cubit.hideAmountsOnLaunchChanged(hide: true);

    expect(cubit.state.hideAmountsOnLaunch, isTrue);
    expect(cubit.state.language, AppLocale.ru);
    expect(Settings.readFrom(store).hideAmountsOnLaunch, isTrue);
  });

  test('a new base currency stays and reaches the screens', () async {
    final seen = <Currency?>[];
    final subscription = baseCurrency.watch().listen(seen.add);

    await cubit.baseCurrencyChanged(Currency.eur);
    await pumpEventQueue();
    await subscription.cancel();

    expect(cubit.state.baseCurrency, Currency.eur);
    expect(Settings.readFrom(store).baseCurrency, Currency.eur);
    expect(seen, [null, Currency.eur]);
  });

  test('the first account can be followed again', () async {
    await cubit.baseCurrencyChanged(Currency.eur);

    await cubit.baseCurrencyChanged(null);

    expect(baseCurrency.value, isNull);
    expect(Settings.readFrom(store).baseCurrency, isNull);
  });

  test('a new base currency keeps the other settings', () async {
    await cubit.languageChanged(AppLocale.ru);
    await cubit.hideAmountsOnLaunchChanged(hide: true);

    await cubit.baseCurrencyChanged(Currency.usd);

    expect(cubit.state.language, AppLocale.ru);
    expect(cubit.state.hideAmountsOnLaunch, isTrue);
  });

  test('a new language keeps the base currency', () async {
    await cubit.baseCurrencyChanged(Currency.usd);

    await cubit.languageChanged(AppLocale.ru);

    expect(cubit.state.baseCurrency, Currency.usd);
    expect(Settings.readFrom(store).baseCurrency, Currency.usd);
  });

  test('a new language keeps the amounts hidden', () async {
    await cubit.hideAmountsOnLaunchChanged(hide: true);

    await cubit.languageChanged(AppLocale.ru);

    expect(cubit.state.hideAmountsOnLaunch, isTrue);
    expect(Settings.readFrom(store).hideAmountsOnLaunch, isTrue);
  });
}
