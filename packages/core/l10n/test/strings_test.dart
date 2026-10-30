import 'package:l10n/l10n.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('English is the language to fall back on', () {
    expect(LocaleSettings.currentLocale, AppLocale.en);
    LocaleSettings.setLocaleRawSync('de');
    expect(LocaleSettings.currentLocale, AppLocale.en);
    expect(t.app.overview, 'Overview');
  });

  test('a host picks a language by its code', () {
    LocaleSettings.setLocaleRawSync('ru');
    expect(t.app.overview, 'Обзор');
  });
}
