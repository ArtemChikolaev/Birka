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

  test('Russian counts none as it counts five', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);

    expect(
      [
        for (final n in [0, 1, 2, 5, 21]) t.tags.operations(n: n),
      ],
      ['0 операций', '1 операция', '2 операции', '5 операций', '21 операция'],
    );
    expect(t.ask.fact.accounts(n: 0), '0 счетов');
    expect(t.backup.accountsCount(n: 0, count: '0'), '0 счетов');
    expect(t.tags.report.forDays(n: 0), 'за 0 дней');
  });
}
