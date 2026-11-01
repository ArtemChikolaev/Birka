import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:overview_common/overview_common.dart';
import 'package:test/test.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);
  final today = CivilDate(2026, 10, 31);

  group('a period', () {
    test('of a week starts seven days back', () {
      expect(OverviewPeriod.week.startFrom(today), CivilDate(2026, 10, 24));
    });

    test('of a month starts from the end of the month before', () {
      expect(OverviewPeriod.month.startFrom(today), CivilDate(2026, 9, 30));
      expect(
        OverviewPeriod.month.startFrom(CivilDate(2027, 1, 1)),
        CivilDate(2026, 12, 31),
      );
    });

    test('of a year starts a year back', () {
      expect(OverviewPeriod.year.startFrom(today), CivilDate(2025, 10, 31));
    });

    test('of a year survives a leap day', () {
      expect(
        OverviewPeriod.year.startFrom(CivilDate(2028, 2, 29)),
        CivilDate(2027, 3, 1),
      );
    });

    test('of a week crosses a month', () {
      expect(
        OverviewPeriod.week.startFrom(CivilDate(2026, 11, 3)),
        CivilDate(2026, 10, 27),
      );
    });

    test('never asks for more than a year', () {
      expect(OverviewPeriod.earliest(today), CivilDate(2025, 10, 31));
    });
  });

  group('the history', () {
    List<int> history(
      List<DayChange> changes, {
      Money? now,
      RateBook rates = const RateBook.empty(),
    }) => capitalHistory(
      now: now ?? rub(1000),
      changes: changes,
      rates: rates,
      start: CivilDate(2026, 10, 28),
      today: today,
    );

    test('ends with the capital of today', () {
      expect(history(const []), [1000, 1000, 1000, 1000]);
    });

    test('takes each change back on the way to the start', () {
      expect(
        history([
          DayChange(CivilDate(2026, 10, 29), rub(300)),
          DayChange(CivilDate(2026, 10, 31), rub(-100)),
        ]),
        [800, 1100, 1100, 1000],
      );
    });

    test('a change of the first day stays outside the period', () {
      expect(
        history([DayChange(CivilDate(2026, 10, 28), rub(500))]),
        [1000, 1000, 1000, 1000],
      );
    });

    test('leaves out a change that no rate can turn', () {
      expect(
        history([DayChange(CivilDate(2026, 10, 30), eur(500))]),
        [1000, 1000, 1000, 1000],
      );
    });

    test('turns every change at the latest rate', () {
      expect(
        history(
          [
            DayChange(CivilDate(2026, 10, 30), eur(10)),
            DayChange(CivilDate(2026, 10, 30), rub(100)),
          ],
          rates: RateBook([
            DayRates(today, {'EUR': Decimal.fromInt(90)}),
          ]),
        ),
        [0, 0, 1000, 1000],
      );
    });

    test('crosses a month', () {
      expect(
        capitalHistory(
          now: rub(100),
          changes: [DayChange(CivilDate(2026, 11, 1), rub(40))],
          rates: const RateBook.empty(),
          start: CivilDate(2026, 10, 31),
          today: CivilDate(2026, 11, 2),
        ),
        [60, 100, 100],
      );
    });

    test('of a single day has one value', () {
      expect(
        capitalHistory(
          now: rub(100),
          changes: const [],
          rates: const RateBook.empty(),
          start: today,
          today: today,
        ),
        [100],
      );
    });
  });
}
