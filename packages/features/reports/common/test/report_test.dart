import 'package:reports_common/reports_common.dart';
import 'package:test/test.dart';

import 'fake_reports_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);
  final october = CivilDate(2026, 10, 1);

  Report report(
    List<CategoryTotal> rows, {
    List<CategoryTotal> previous = const [],
    List<MonthTotal> months = const [],
    Currency? preferred = Currency.rub,
    CivilDate? month,
  }) => Report.of(
    month: month ?? october,
    rows: rows,
    previousRows: previous,
    monthTotals: months,
    preferred: preferred,
  );

  test('adds up the month', () {
    final it = report([
      testTotal('Food', rub(500)),
      testTotal('Cafe', rub(200)),
    ]);

    expect(it.total, rub(700));
    expect(it.isEmpty, isFalse);
  });

  test('measures each category against the biggest one', () {
    final it = report([
      testTotal('Food', rub(800)),
      testTotal('Cafe', rub(200)),
    ]);

    expect(it.lines.map((line) => line.share), [1, 0.25]);
    expect(it.lines.map((line) => line.category.name), ['Food', 'Cafe']);
  });

  test('compares each category with the month before', () {
    final it = report(
      [
        testTotal('Food', rub(960)),
        testTotal('Cafe', rub(1350)),
        testTotal('Home', rub(500)),
      ],
      previous: [
        testTotal('Food', rub(1000)),
        testTotal('Cafe', rub(1000)),
        testTotal('Home', rub(500)),
      ],
    );

    final changes = {
      for (final line in it.lines) line.category.name: line.change,
    };
    expect(changes, {'Food': -4, 'Cafe': 35, 'Home': 0});
  });

  test('a new category has nothing to compare with', () {
    final it = report(
      [testTotal('Food', rub(500))],
      previous: [testTotal('Cafe', rub(500))],
    );

    expect(it.lines.single.change, isNull);
    expect(it.change, 0);
  });

  test('compares the whole month with the one before', () {
    final it = report(
      [testTotal('Food', rub(1160))],
      previous: [testTotal('Food', rub(600)), testTotal('Cafe', rub(400))],
    );

    expect(it.change, 16);
  });

  test('a month after an empty one has nothing to compare with', () {
    expect(report([testTotal('Food', rub(1))]).change, isNull);
  });

  test('follows the preferred currency and keeps the others apart', () {
    final it = report(
      [testTotal('Food', rub(500)), testTotal('Food', eur(9))],
      previous: [testTotal('Food', eur(1))],
      months: [MonthTotal(october, rub(500)), MonthTotal(october, eur(9))],
    );

    expect(it.total, rub(500));
    expect(it.lines.single.change, isNull);
    expect(it.others, [eur(9)]);
    expect(it.months.last.total, rub(500));
  });

  test('without it takes the currency of the most categories', () {
    final it = report([
      testTotal('Food', eur(9)),
      testTotal('Cafe', eur(1)),
      testTotal('Food', Money(500, Currency.usd)),
    ]);

    expect(it.total, eur(10));
    expect(it.others, [Money(500, Currency.usd)]);
  });

  test('adds up the other currencies one by one', () {
    final it = report([
      testTotal('Food', rub(1)),
      testTotal('Food', eur(1)),
      testTotal('Cafe', eur(2)),
    ]);

    expect(it.others, [eur(3)]);
  });

  group('the months', () {
    test('are six, up to the month of the report', () {
      final it = report(
        [testTotal('Food', rub(500))],
        months: [MonthTotal(october, rub(500))],
      );

      expect(it.months.map((month) => month.month), [
        CivilDate(2026, 5, 1),
        CivilDate(2026, 6, 1),
        CivilDate(2026, 7, 1),
        CivilDate(2026, 8, 1),
        CivilDate(2026, 9, 1),
        october,
      ]);
      expect(it.months.last.total, rub(500));
      expect(it.months.first.total, rub(0));
    });

    test('cross a year', () {
      final it = report(const [], month: CivilDate(2026, 2, 1));

      expect(it.months.first.month, CivilDate(2025, 9, 1));
    });

    test('average those with anything in them', () {
      final it = report(
        [testTotal('Food', rub(300))],
        months: [
          MonthTotal(CivilDate(2026, 9, 1), rub(100)),
          MonthTotal(october, rub(300)),
        ],
      );

      expect(it.average, rub(200));
    });

    test('stay after a month with nothing in it', () {
      final it = report(
        const [],
        months: [MonthTotal(CivilDate(2026, 9, 1), rub(100))],
      );

      expect(it.isEmpty, isTrue);
      expect(it.total, isNull);
      expect(it.average, rub(100));
      expect(it.months, hasLength(6));
    });

    test('leave out what is older than six months', () {
      final it = report(
        const [],
        months: [MonthTotal(CivilDate(2026, 4, 1), rub(100))],
      );

      expect(it.months.every((month) => month.total.isZero), isTrue);
      expect(it.average, isNull);
    });
  });

  test('without anything there is nothing to show', () {
    final it = report(const [], preferred: null);

    expect(it.isEmpty, isTrue);
    expect(it.months, isEmpty);
    expect(it.average, isNull);
  });

  test('a month without a currency takes that of the last totals', () {
    final it = report(
      const [],
      preferred: null,
      months: [MonthTotal(CivilDate(2026, 9, 1), eur(5))],
    );

    expect(it.average, eur(5));
  });

  test('a total stops at the limit of an amount', () {
    final most = Money(Money.maxMinorUnits, Currency.rub);

    expect(
      report([testTotal('a', most), testTotal('b', most)]).total,
      most,
    );
  });

  test('a month knows its neighbors', () {
    expect(monthsBefore(CivilDate(2026, 1, 1), 1), CivilDate(2025, 12, 1));
    expect(lastDayOf(CivilDate(2028, 2, 1)), CivilDate(2028, 2, 29));
    expect(lastDayOf(CivilDate(2026, 12, 1)), CivilDate(2026, 12, 31));
  });
}
