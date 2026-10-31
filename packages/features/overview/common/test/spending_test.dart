import 'package:money/money.dart';
import 'package:overview_common/overview_common.dart';
import 'package:test/test.dart';

import 'fake_overview_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);

  test('nothing spent is empty', () {
    final spending = Spending.of(const []);

    expect(spending.isEmpty, isTrue);
    expect(spending.total, isNull);
  });

  test('adds up the categories of the preferred currency', () {
    final spending = Spending.of([
      testTotal('Food', rub(500)),
      testTotal('Cafe', rub(200)),
      testTotal('Food', eur(9)),
    ], preferred: Currency.rub);

    expect(spending.total, rub(700));
    expect(spending.categories.map((row) => row.category.name), [
      'Food',
      'Cafe',
    ]);
    expect(spending.others, [eur(9)]);
  });

  test('adds up the other currencies one by one', () {
    final spending = Spending.of([
      testTotal('Food', rub(500)),
      testTotal('Food', eur(9)),
      testTotal('Cafe', eur(1)),
    ], preferred: Currency.rub);

    expect(spending.others, [eur(10)]);
  });

  group('when nothing went in the preferred currency', () {
    final yen = Currency.custom('JPY', decimalDigits: 0);

    test('takes the currency of the most categories', () {
      final spending = Spending.of([
        testTotal('Food', Money(500000, yen)),
        testTotal('Food', eur(9)),
        testTotal('Cafe', eur(1)),
      ], preferred: Currency.rub);

      expect(spending.total, eur(10));
      expect(spending.others, [Money(500000, yen)]);
    });

    test('never compares amounts in different currencies', () {
      final spending = Spending.of([
        testTotal('Food', Money(50000, yen)),
        testTotal('Food', eur(40000)),
      ], preferred: Currency.rub);

      expect(spending.total, eur(40000));

      final other = Spending.of([
        testTotal('Food', eur(1)),
        testTotal('Food', Money(50000, yen)),
      ], preferred: Currency.rub);

      expect(other.total, eur(1));
    });

    test('on a tie takes the first code', () {
      final spending = Spending.of([
        testTotal('Food', Money(5, Currency.usd)),
        testTotal('Food', eur(9)),
      ]);

      expect(spending.total, eur(9));
      expect(spending.others, [Money(5, Currency.usd)]);
    });
  });

  test('needs no preference for one currency', () {
    expect(Spending.of([testTotal('Food', rub(1))]).total, rub(1));
  });

  test('names three categories and rings them all', () {
    final spending = Spending.of([
      for (var i = 5; i > 0; i--) testTotal('c$i', rub(i)),
    ]);

    expect(spending.top.map((row) => row.category.name), ['c5', 'c4', 'c3']);
    expect(spending.categories, hasLength(5));
  });

  test('stops at the limit of an amount', () {
    final most = Money(Money.maxMinorUnits, Currency.rub);

    expect(
      Spending.of([testTotal('a', most), testTotal('b', most)]).total,
      most,
    );
  });
}
