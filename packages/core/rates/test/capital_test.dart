import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money usd(int minorUnits) => Money(minorUnits, Currency.usd);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);

  AccountBalance balance(
    String name,
    Money amount, {
    bool includeInTotals = true,
  }) => AccountBalance(
    Account(
      id: name,
      name: name,
      type: AccountType.debit,
      openingBalance: Money.zero(amount.currency),
      includeInTotals: includeInTotals,
      archived: false,
      sortOrder: 0,
    ),
    amount,
  );

  final rates = RateBook([
    DayRates(CivilDate(2026, 10, 31), {'USD': Decimal.fromInt(80)}),
  ]);

  test('nothing to count is no capital', () {
    final capital = Capital.of(const [], rates: rates);

    expect(capital.main, isNull);
    expect(capital.others, isEmpty);
    expect(capital.currencies, 0);
  });

  test('follows the first account until a currency is picked', () {
    final capital = Capital.of([
      balance('Card', rub(10000)),
      balance('Dollars', usd(100)),
    ], rates: rates);

    expect(capital.main, rub(18000));
    expect(capital.others, isEmpty);
    expect(capital.currencies, 2);
    expect(capital.converted, isTrue);
  });

  test('turns everything into the picked currency', () {
    final capital = Capital.of(
      [balance('Card', rub(8000)), balance('Dollars', usd(100))],
      rates: rates,
      base: Currency.usd,
    );

    expect(capital.main, usd(200));
  });

  test('one currency goes through no rate', () {
    final capital = Capital.of([
      balance('Card', rub(100)),
      balance('Cash', rub(50)),
    ], rates: rates);

    expect(capital.main, rub(150));
    expect(capital.converted, isFalse);
    expect(capital.currencies, 1);
  });

  test('adds up before it rounds', () {
    final capital = Capital.of(
      [balance('Card', rub(10000000)), balance('Dollars', usd(50000))],
      rates: RateBook([
        DayRates(CivilDate(2026, 10, 31), {
          'USD': Decimal.fromInt(80),
          'EUR': Decimal.fromInt(90),
        }),
      ]),
      base: Currency.eur,
    );

    expect(capital.main, eur(155556));
  });

  test('keeps apart what no rate can reach', () {
    final capital = Capital.of([
      balance('Card', rub(100)),
      balance('Euro', eur(5)),
      balance('Dollars', usd(1)),
    ], rates: rates);

    expect(capital.main, rub(180));
    expect(capital.others, [eur(5)]);
    expect(capital.currencies, 3);
  });

  test('without rates each currency stands apart', () {
    final capital = Capital.of([
      balance('Card', rub(100)),
      balance('Dollars', usd(1)),
    ], rates: const RateBook.empty());

    expect(capital.main, rub(100));
    expect(capital.others, [usd(1)]);
    expect(capital.converted, isFalse);
  });

  test('a picked currency that nothing can reach gives way to the first', () {
    final capital = Capital.of(
      [balance('Card', rub(100))],
      rates: const RateBook.empty(),
      base: Currency.eur,
    );

    expect(capital.main, rub(100));
  });

  test('a picked currency that an account holds stands without rates', () {
    final capital = Capital.of(
      [balance('Card', rub(100)), balance('Euro', eur(5))],
      rates: const RateBook.empty(),
      base: Currency.eur,
    );

    expect(capital.main, eur(5));
    expect(capital.others, [rub(100)]);
  });

  test('an account outside the totals stays out', () {
    final capital = Capital.of([
      balance('Card', rub(100)),
      balance('Loan', usd(100), includeInTotals: false),
    ], rates: rates);

    expect(capital.main, rub(100));
    expect(capital.currencies, 1);
  });

  test('holds at the limit of an amount', () {
    final most = rub(Money.maxMinorUnits);

    final capital = Capital.of([
      balance('First', most),
      balance('Second', most),
    ], rates: rates);

    expect(capital.main, most);
  });
}
