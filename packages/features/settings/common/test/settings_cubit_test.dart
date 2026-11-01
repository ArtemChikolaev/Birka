import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';
import 'package:test/test.dart';

import 'fake_settings_store.dart';

void main() {
  late FakeSettingsStore store;
  late SettingsCubit cubit;

  setUp(() {
    store = FakeSettingsStore();
    cubit = SettingsCubit(store, deviceLanguage: 'en');
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

    cubit = SettingsCubit(store, deviceLanguage: 'en');

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

  test('a new language keeps the amounts hidden', () async {
    await cubit.hideAmountsOnLaunchChanged(hide: true);

    await cubit.languageChanged(AppLocale.ru);

    expect(cubit.state.hideAmountsOnLaunch, isTrue);
    expect(Settings.readFrom(store).hideAmountsOnLaunch, isTrue);
  });
}
