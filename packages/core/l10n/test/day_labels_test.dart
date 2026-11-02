import 'package:l10n/l10n.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('a date reads in the language of the user', () {
    expect(
      dateLabel(year: 2026, month: 10, day: 3, thisYear: 2026),
      'October 3',
    );

    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(dateLabel(year: 2026, month: 3, day: 8, thisYear: 2026), '8 марта');
  });

  test('a date of another year says so', () {
    expect(
      dateLabel(year: 2025, month: 12, day: 31, thisYear: 2026),
      'December 31 2025',
    );
  });

  test('a time has two digits on each side', () {
    expect(timeLabel(DateTime(2026, 10, 31, 8, 5)), '08:05');
    expect(timeLabel(DateTime(2026, 10, 31, 23, 42)), '23:42');
  });

  test('a time follows the clock of the device', () {
    final moment = DateTime(2026, 10, 31, 8, 5);
    expect(timeLabel(moment.toUtc()), '08:05');
  });
}
