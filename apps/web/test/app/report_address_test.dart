import 'package:birka_web/app/report_address.dart';
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:test/test.dart';

void main() {
  test('a month of the reports goes to the address and comes back', () {
    expect(reportAddress(CivilDate(2026, 10, 1)), 'reports/#2026-10');
    expect(reportMonthIn('2026-10'), CivilDate(2026, 10, 1));
  });

  test('any other fragment asks for no month', () {
    expect(reportMonthIn(''), isNull);
    expect(reportMonthIn('2026-13'), isNull);
    expect(reportMonthIn('new'), isNull);
  });
}
