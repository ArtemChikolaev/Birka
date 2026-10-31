import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:overview_common/overview_common.dart';
import 'package:test/test.dart';

void main() {
  final today = CivilDate(2026, 10, 31);

  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('a period has a name', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(periodLabel(OverviewPeriod.week), 'Неделя');
    expect(periodLabel(OverviewPeriod.month), 'Месяц');
    expect(periodLabel(OverviewPeriod.year), 'Год');
  });

  test('the title is the month', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(monthTitle(today), 'Октябрь');
  });

  test('a change says what it covers', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(changeCaption(OverviewPeriod.week, today: today), 'за неделю');
    expect(changeCaption(OverviewPeriod.month, today: today), 'за октябрь');
    expect(changeCaption(OverviewPeriod.year, today: today), 'за год');
  });

  test('in English too', () {
    expect(changeCaption(OverviewPeriod.week, today: today), 'this week');
    expect(changeCaption(OverviewPeriod.month, today: today), 'in October');
  });

  test('the capital counts its currencies', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(capitalLabel(1), 'Капитал');
    expect(capitalLabel(2), 'Капитал · 2 валюты');
    expect(capitalLabel(5), 'Капитал · 5 валют');
  });

  test('the spending names its month', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(spendingTitle(today), 'Траты в октябре');
    expect(spendingTitle(CivilDate(2026, 5, 1)), 'Траты в мае');
  });

  test('a change carries its sign', () {
    expect(changeLabel(Money(100, Currency.usd)), r'+$1');
    expect(changeLabel(Money(-100, Currency.usd)), r'−$1');
  });
}
