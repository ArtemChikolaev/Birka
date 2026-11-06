import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

Schedule rent({
  ScheduleEvery every = ScheduleEvery.month,
  int day = 25,
  CivilDate? next,
}) => Schedule(
  id: 'rent',
  kind: TransactionKind.expense,
  name: 'Rent',
  accountId: 'card',
  categoryId: 'home',
  amount: Money(4500000, Currency.rub),
  every: every,
  day: day,
  next: next ?? CivilDate(2026, 11, 25),
  onDay: ScheduleOnDay.ask,
  reminder: ScheduleReminder.dayBefore,
);

void main() {
  group('the time after', () {
    test('is the same day of the next month', () {
      final schedule = rent();

      expect(schedule.after(CivilDate(2026, 11, 25)), CivilDate(2026, 12, 25));
      expect(schedule.after(CivilDate(2026, 12, 25)), CivilDate(2027, 1, 25));
    });

    test('takes the last day of a shorter month and comes back after it', () {
      final schedule = rent(day: 31, next: CivilDate(2026, 10, 31));

      final november = schedule.after(CivilDate(2026, 10, 31));
      final december = schedule.after(november);
      final february = schedule.after(schedule.after(december));

      expect(november, CivilDate(2026, 11, 30));
      expect(december, CivilDate(2026, 12, 31));
      expect(february, CivilDate(2027, 2, 28));
    });

    test('of a time moved off its day is on the day of the rule', () {
      final schedule = rent();

      expect(schedule.after(CivilDate(2026, 11, 27)), CivilDate(2026, 12, 25));
    });

    test('is a week later for a weekly payment', () {
      final schedule = rent(every: ScheduleEvery.week);

      expect(schedule.after(CivilDate(2026, 11, 25)), CivilDate(2026, 12, 2));
      expect(schedule.after(CivilDate(2026, 12, 30)), CivilDate(2027, 1, 6));
    });

    test('is the same day of the next year for a yearly payment', () {
      final schedule = rent(
        every: ScheduleEvery.year,
        day: 29,
        next: CivilDate(2028, 2, 29),
      );

      final next = schedule.after(CivilDate(2028, 2, 29));

      expect(next, CivilDate(2029, 2, 28));
      expect(schedule.after(CivilDate(2031, 2, 28)), CivilDate(2032, 2, 29));
    });
  });

  test('lists its times up to a day, both ends included', () {
    final schedule = rent();

    expect(schedule.timesUntil(CivilDate(2027, 1, 25)), [
      CivilDate(2026, 11, 25),
      CivilDate(2026, 12, 25),
      CivilDate(2027, 1, 25),
    ]);
    expect(schedule.timesUntil(CivilDate(2026, 11, 24)), isEmpty);
  });

  test('waits from its day on', () {
    final schedule = rent();

    expect(schedule.isDue(CivilDate(2026, 11, 24)), isFalse);
    expect(schedule.isDue(CivilDate(2026, 11, 25)), isTrue);
    expect(schedule.isDue(CivilDate(2026, 12, 3)), isTrue);
  });

  test('moves on to another time and keeps the rest', () {
    final schedule = rent();

    final moved = schedule.movedTo(CivilDate(2026, 12, 25));

    expect(moved.next, CivilDate(2026, 12, 25));
    expect(moved, isNot(schedule));
    expect(moved.movedTo(schedule.next), schedule);
    expect(moved.movedTo(schedule.next).hashCode, schedule.hashCode);
  });
}
