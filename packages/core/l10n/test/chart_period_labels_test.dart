import 'package:l10n/l10n.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('a period has a name', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);

    expect(chartPeriodLabel('week'), 'Неделя');
    expect(chartPeriodLabel('month'), 'Месяц');
    expect(chartPeriodLabel('year'), 'Год');
  });

  test('a change says what it covers', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);

    expect(chartPeriodCaption('week', month: 10), 'за неделю');
    expect(chartPeriodCaption('month', month: 10), 'за октябрь');
    expect(chartPeriodCaption('year', month: 10), 'за год');
  });

  test('in English too', () {
    expect(chartPeriodLabel('year'), 'Year');
    expect(chartPeriodCaption('week', month: 10), 'this week');
    expect(chartPeriodCaption('month', month: 10), 'in October');
  });
}
