import 'package:accounts_common/accounts_common.dart';
import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:money/money.dart';
import 'package:test/test.dart';

import 'fake_accounts_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);
  AccountBalance row(Account account, Money balance) =>
      AccountBalance(account, balance);

  test('adds the accounts up per currency, in their order', () {
    final overview = AccountsOverview.of([
      row(account('Card', rub(0)), rub(41230000)),
      row(account('Euro', eur(0)), eur(214000)),
      row(account('Cash', rub(0)), rub(1850000)),
    ]);

    expect(overview.totals, [rub(43080000), eur(214000)]);
    expect(overview.countedAccounts, 3);
  });

  test('leaves out what does not count towards the totals', () {
    final overview = AccountsOverview.of([
      row(account('Card', rub(0)), rub(100)),
      row(account('Loan', rub(0), includeInTotals: false), rub(-5000)),
      row(account('Old', rub(0), archived: true), rub(700)),
    ]);

    expect(overview.totals, [rub(100)]);
    expect(overview.countedAccounts, 1);
    expect(overview.holdings, [
      (balance: rub(100), accounts: 1, exceedsRange: false),
    ]);
    expect(overview.showByCurrency, isFalse);
  });

  test('sorts archived accounts out of the everyday ones', () {
    final overview = AccountsOverview.of([
      row(account('Card', rub(0)), rub(100)),
      row(account('Old', rub(0), archived: true), rub(700)),
    ]);

    expect(overview.active.map((r) => r.account.name), ['Card']);
    expect(overview.archived.map((r) => r.account.name), ['Old']);
  });

  test('adds currencies up once a rate joins them', () {
    final overview = AccountsOverview.of(
      [
        row(account('Card', rub(0)), rub(100000)),
        row(account('Euro', eur(0)), eur(100)),
      ],
      rates: RateBook([
        DayRates(CivilDate(2026, 10, 31), {'EUR': Decimal.fromInt(90)}),
      ]),
    );

    expect(overview.totals, [rub(109000)]);
    expect(overview.holdings.map((part) => part.balance), [
      rub(100000),
      eur(100),
    ]);
    expect(overview.showByCurrency, isTrue);
  });

  test('shows the totals in the picked currency', () {
    final overview = AccountsOverview.of(
      [row(account('Card', rub(0)), rub(9000))],
      rates: RateBook([
        DayRates(CivilDate(2026, 10, 31), {'EUR': Decimal.fromInt(90)}),
      ]),
      base: Currency.eur,
    );

    expect(overview.totals, [eur(100)]);
    expect(overview.holdings.single.balance, rub(9000));
    expect(overview.showByCurrency, isTrue);
  });

  test('keeps a zero balance and counts both contributing accounts', () {
    final overview = AccountsOverview.of([
      row(account('Cash', rub(0)), rub(150)),
      row(account('Card', rub(0)), rub(-150)),
      row(account('Travel', eur(0)), eur(-40)),
    ]);
    expect(overview.holdings, [
      (balance: rub(0), accounts: 2, exceedsRange: false),
      (balance: eur(-40), accounts: 1, exceedsRange: false),
    ]);
    expect(overview.showByCurrency, isTrue);
  });

  test('marks a bound even when only one currency contributes', () {
    final most = rub(Money.maxMinorUnits);
    final overview = AccountsOverview.of([
      row(account('Loan', rub(0)), -most),
      row(account('Credit', rub(0)), rub(-1)),
    ]);
    expect(overview.showByCurrency, isTrue);
    expect(overview.holdings.single.exceedsRange, isTrue);
    expect(holdingAmount(overview.holdings.single), startsWith('< '));
  });

  test('has no totals without accounts', () {
    final overview = AccountsOverview.of(const []);
    expect(overview.totals, isEmpty);
    expect(overview.countedAccounts, 0);
    expect(overview.showByCurrency, isFalse);
  });
}
