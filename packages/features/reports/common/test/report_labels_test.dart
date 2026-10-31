import 'package:l10n/l10n.dart';
import 'package:reports_common/reports_common.dart';
import 'package:test/test.dart';

void main() {
  final today = CivilDate(2026, 10, 31);

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('a kind has a name', () {
    expect(kindLabel(CategoryKind.expense), 'Расходы');
    expect(kindLabel(CategoryKind.income), 'Доходы');
  });

  test('a month says its year when it is another', () {
    expect(reportMonthLabel(CivilDate(2026, 10, 1), today: today), 'Октябрь');
    expect(
      reportMonthLabel(CivilDate(2025, 12, 1), today: today),
      'Декабрь 2025',
    );
  });

  test('a percent carries its sign', () {
    expect(percentLabel(35), '+35%');
    expect(percentLabel(-4), '−4%');
    expect(percentLabel(0), '0%');
  });

  test('a change names the month before', () {
    expect(
      changeAgainst(16, month: CivilDate(2026, 10, 1)),
      '+16% к сентябрю',
    );
    expect(
      changeAgainst(-3, month: CivilDate(2026, 1, 1)),
      '−3% к декабрю',
    );
  });

  test('a change names it in English too', () {
    LocaleSettings.setLocaleSync(AppLocale.en);

    expect(
      changeAgainst(16, month: CivilDate(2026, 10, 1)),
      '+16% vs September',
    );
    expect(changeAgainst(1, month: CivilDate(2026, 1, 1)), '+1% vs December');
  });

  test('every month has its place in the list', () {
    for (var month = 1; month <= 12; month++) {
      final before = t.transactions.monthNames[(month + 10) % 12];
      final stem = before.substring(0, before.length - 2);
      expect(
        changeAgainst(1, month: CivilDate(2026, month, 1)),
        contains(stem.toLowerCase()),
      );
    }
  });

  test('an average says what it is', () {
    expect(averageLabel('84 тыс. ₽'), 'в среднем 84 тыс. ₽');
  });

  test('a short month stands under its bar', () {
    expect(shortMonthLabel(CivilDate(2026, 10, 1)), 'Окт');
  });

  test('an empty month says what is missing', () {
    expect(emptyLabel(CategoryKind.expense), 'В этом месяце расходов нет.');
    expect(emptyLabel(CategoryKind.income), 'В этом месяце доходов нет.');
  });
}
