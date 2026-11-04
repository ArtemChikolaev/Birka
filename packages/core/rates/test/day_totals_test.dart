import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money usd(int minorUnits) => Money(minorUnits, Currency.usd);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);
  final yen = Currency.iso('JPY');

  final monday = CivilDate(2026, 10, 26);
  final friday = CivilDate(2026, 10, 30);
  final rates = RateBook([
    DayRates(monday, {'USD': Decimal.fromInt(70)}),
    DayRates(friday, {
      'USD': Decimal.fromInt(90),
      'EUR': Decimal.parse('100.33'),
    }),
  ]);

  CategoryDayTotal row(
    String name,
    Money total,
    CivilDate day, {
    int sortOrder = 0,
  }) => CategoryDayTotal(
    Category(
      id: name,
      kind: CategoryKind.expense,
      name: name,
      archived: false,
      sortOrder: sortOrder,
    ),
    day,
    total,
  );

  group('totals in a currency', () {
    test('keep what waits for a category apart, after a total its size', () {
      final totals = totalsIn(Currency.rub, [
        CategoryDayTotal(null, monday, rub(200)),
        row('Food', rub(500), monday, sortOrder: 9),
        CategoryDayTotal(null, friday, rub(300)),
        row('Cafe', rub(9000), friday),
      ], rates);

      expect(totals.map((it) => (it.category?.name, it.total)), [
        ('Cafe', rub(9000)),
        ('Food', rub(500)),
        (null, rub(500)),
      ]);
      expect(categoryKey(totals.last.category), '');
      expect(categoryKey(totals.first.category), 'Cafe');
    });

    test('take the rate of each day', () {
      final totals = totalsIn(Currency.rub, [
        row('Food', usd(100), monday),
        row('Food', usd(100), friday),
      ], rates);

      expect(totals.single.category?.name, 'Food');
      expect(totals.single.total, rub(16000));
    });

    test('are whole once a rate stands behind them', () {
      final totals = totalsIn(Currency.rub, [
        row('Food', eur(1234), friday),
        row('Food', rub(50), friday),
      ], rates);

      expect(totals.single.total, rub(123900));
    });

    test('round the exact sum and not a sum in kopecks', () {
      final exact = RateBook([
        DayRates(friday, {'USD': Decimal.parse('83.9497')}),
      ]);

      final totals = totalsIn(Currency.rub, [
        row('Food', usd(1000), friday),
      ], exact);

      expect(totals.single.total, rub(83900));
    });

    test('keep the cents of less than one unit', () {
      final totals = totalsIn(Currency.usd, [
        row('Food', rub(3000), friday),
      ], rates);

      expect(totals.single.total, usd(33));
    });

    test('leave out what a rate turned into nothing', () {
      final totals = totalsIn(Currency.usd, [
        row('Food', rub(1), friday),
        row('Cafe', usd(100), friday),
      ], rates);

      expect(totals.single.category?.name, 'Cafe');
    });

    test('leave what never took a rate as it is', () {
      final totals = totalsIn(Currency.rub, [
        row('Food', rub(12345), monday),
        row('Food', rub(5), friday),
      ], rates);

      expect(totals.single.total, rub(12350));
    });

    test('keep an amount without a rate in its own currency', () {
      final totals = totalsIn(Currency.rub, [
        row('Food', Money(500, yen), friday),
        row('Food', usd(100), friday),
      ], rates);

      expect(totals.map((total) => total.total), [
        Money(500, yen),
        rub(9000),
      ]);
    });

    test('go to no currency without a target', () {
      final totals = totalsIn(null, [
        row('Food', rub(100), friday),
        row('Food', usd(100), friday),
      ], rates);

      expect(totals.map((total) => total.total), [rub(100), usd(100)]);
    });

    test('put the biggest of each currency first, then the order', () {
      final totals = totalsIn(Currency.rub, [
        row('Tea', rub(100), friday, sortOrder: 2),
        row('Cafe', rub(100), friday, sortOrder: 1),
        row('Food', usd(100), friday),
        row('Eur', rub(1), friday),
        row('Dollar', usd(1), monday),
      ], const RateBook.empty());

      expect(totals.map((total) => total.category?.name), [
        'Cafe',
        'Tea',
        'Eur',
        'Food',
        'Dollar',
      ]);
    });
  });

  group('month totals in a currency', () {
    final september = CivilDate(2026, 9, 1);
    final october = CivilDate(2026, 10, 1);

    test('add up each month, the earliest first', () {
      final totals = monthTotalsIn(Currency.rub, [
        row('Food', usd(100), friday),
        row('Food', rub(50), CivilDate(2026, 10, 1)),
        row('Food', rub(70), CivilDate(2026, 9, 30)),
      ], rates);

      expect(totals.map((total) => total.month), [september, october]);
      expect(totals.map((total) => total.total), [rub(70), rub(9100)]);
    });

    test('are the sum of the categories of the month', () {
      final rows = [
        row('Food', eur(1234), friday),
        row('Cafe', eur(1234), friday),
        row('Tea', rub(55), friday),
      ];

      final categories = totalsIn(Currency.rub, rows, rates);
      final month = monthTotalsIn(Currency.rub, rows, rates).single;

      expect(
        month.total.minorUnits,
        categories.fold(0, (sum, row) => sum + row.total.minorUnits),
      );
    });

    test('leave out a month that a rate turned into nothing', () {
      final totals = monthTotalsIn(Currency.usd, [
        row('Food', rub(1), friday),
      ], rates);

      expect(totals, isEmpty);
    });

    test('keep an amount without a rate in its own currency', () {
      final totals = monthTotalsIn(Currency.rub, [
        row('Food', Money(500, yen), friday),
        row('Food', usd(100), friday),
      ], rates);

      expect(totals.map((total) => total.total), [
        Money(500, yen),
        rub(9000),
      ]);
    });
  });
}
