import 'package:ask_common/ask_common.dart';
import 'package:ledger/ledger.dart';
import 'package:test/test.dart';

void main() {
  final today = CivilDate(2026, 11, 12);

  String span(AskPeriod period) => '${period.first}..${period.last}';

  test('sets a period against the same stretch before it', () {
    expect(
      span(AskPeriod.month(CivilDate(2026, 10, 1)).before),
      '2026-09-01..2026-09-30',
    );
    expect(
      span(AskPeriod.month(today).upTo(today).before),
      '2026-10-01..2026-10-12',
    );
    expect(
      span(AskPeriod.months(CivilDate(2026, 10, 1), 3).before),
      '2026-05-01..2026-07-31',
    );
    expect(
      span(AskPeriod.year(2026).upTo(today).before),
      '2025-01-01..2025-11-12',
    );
    expect(
      span(AskPeriod.lastDays(today, 30).before),
      '2026-09-14..2026-10-13',
    );
    expect(span(AskPeriod.week(today).before), '2026-11-02..2026-11-08');
    expect(span(AskPeriod.day(today).before), '2026-11-11..2026-11-11');
  });

  test('stops at today and keeps the start of a month', () {
    final month = AskPeriod.month(today).upTo(today);

    expect(span(month), '2026-11-01..2026-11-12');
    expect(month.cut, isTrue);
    expect(month.days, 12);
    expect(AskPeriod.month(CivilDate(2026, 10, 1)).upTo(today).cut, isFalse);
  });

  test('starts months on the day the person picked', () {
    final month = AskPeriod.month(today, start: 25);

    expect(span(month), '2026-10-25..2026-11-24');
    expect(span(month.before), '2026-09-25..2026-10-24');
  });
}
