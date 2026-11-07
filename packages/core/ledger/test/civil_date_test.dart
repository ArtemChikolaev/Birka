import 'package:ledger/ledger.dart';
import 'package:test/test.dart';

void main() {
  test('reads and writes YYYY-MM-DD', () {
    final date = CivilDate.parse('2026-02-03');

    expect(date, CivilDate(2026, 2, 3));
    expect(date.toString(), '2026-02-03');
  });

  test('sorts as the calendar does', () {
    final dates = [
      CivilDate(2026, 10, 1),
      CivilDate(2025, 12, 31),
      CivilDate(2026, 2, 28),
    ]..sort();

    expect(dates.map((date) => date.toString()), [
      '2025-12-31',
      '2026-02-28',
      '2026-10-01',
    ]);
  });

  test('takes the date of a moment on the calendar of its own zone', () {
    final moment = DateTime(2026, 10, 31, 23, 59);

    expect(CivilDate.of(moment), CivilDate(2026, 10, 31));
  });

  test('starts a month on a day of the calendar', () {
    expect(CivilDate(2026, 11, 18).monthStart(), CivilDate(2026, 11, 1));
    expect(CivilDate(2026, 11, 18).monthStart(5), CivilDate(2026, 11, 5));
    expect(CivilDate(2026, 11, 4).monthStart(5), CivilDate(2026, 10, 5));
    expect(CivilDate(2027, 1, 3).monthStart(25), CivilDate(2026, 12, 25));
    expect(CivilDate(2026, 11, 5).addMonths(1), CivilDate(2026, 12, 5));
    expect(CivilDate(2026, 1, 25).addMonths(-1), CivilDate(2025, 12, 25));
    expect(CivilDate(2026, 1, 31).addMonths(1), CivilDate(2026, 2, 28));
  });

  test('accepts February 29 only in a leap year', () {
    expect(CivilDate(2028, 2, 29).toString(), '2028-02-29');
    expect(() => CivilDate(2026, 2, 29), throwsArgumentError);
  });

  test('rejects years that the stored form cannot hold', () {
    expect(() => CivilDate(20026, 10, 30), throwsArgumentError);
    expect(() => CivilDate(-1, 10, 30), throwsArgumentError);
    expect(CivilDate.parse('0001-01-01'), CivilDate(1, 1, 1));
    expect(CivilDate(9999, 12, 31).toString(), '9999-12-31');
  });

  test('rejects dates that do not exist and other formats', () {
    expect(() => CivilDate(2026, 13, 1), throwsArgumentError);
    expect(() => CivilDate.parse('2026-02-30'), throwsArgumentError);
    expect(() => CivilDate.parse('30.10.2026'), throwsFormatException);
  });

  test('a month has its nearest neighbours in time among others', () {
    final november = CivilDate(2026, 11, 1);
    final october = CivilDate(2026, 10, 1);
    final may = CivilDate(2026, 5, 1);
    final months = [november, october, may];

    expect(neighbourMonth(months, october, earlier: true), may);
    expect(neighbourMonth(months, october, earlier: false), november);
    expect(neighbourMonth(months, may, earlier: true), isNull);
    expect(neighbourMonth(months, november, earlier: false), isNull);
    expect(
      neighbourMonth(months, CivilDate(2026, 1, 1), earlier: true),
      isNull,
    );
    expect(
      neighbourMonth(months, CivilDate(2026, 1, 1), earlier: false),
      may,
    );
    // A month that left the list still has its neighbours.
    expect(neighbourMonth([november, may], october, earlier: true), may);
    expect(neighbourMonth([november, may], october, earlier: false), november);
  });

  test('moves by days across months and years', () {
    expect(CivilDate(2026, 11, 28).addDays(7), CivilDate(2026, 12, 5));
    expect(CivilDate(2026, 12, 29).addDays(3), CivilDate(2027, 1, 1));
    expect(CivilDate(2026, 3, 1).addDays(-1), CivilDate(2026, 2, 28));
  });

  test('knows its weekday and the days until another date', () {
    // November 18, 2026 is a Wednesday.
    expect(CivilDate(2026, 11, 18).weekday, DateTime.wednesday);
    expect(CivilDate(2026, 11, 18).daysUntil(CivilDate(2026, 12, 5)), 17);
    expect(CivilDate(2026, 12, 5).daysUntil(CivilDate(2026, 11, 18)), -17);
    // A change of clocks in between does not shorten a day.
    expect(CivilDate(2026, 3, 1).daysUntil(CivilDate(2026, 4, 1)), 31);
  });

  test('takes a day of a month, or its last day when the month is shorter', () {
    expect(CivilDate.onDay(2026, 11, 25), CivilDate(2026, 11, 25));
    expect(CivilDate.onDay(2026, 11, 31), CivilDate(2026, 11, 30));
    expect(CivilDate.onDay(2026, 2, 30), CivilDate(2026, 2, 28));
    expect(CivilDate.onDay(2028, 2, 30), CivilDate(2028, 2, 29));
    // A month past December goes on into the next year.
    expect(CivilDate.onDay(2026, 13, 5), CivilDate(2027, 1, 5));
  });
}
