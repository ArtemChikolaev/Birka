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
  });

  test('has no totals without accounts', () {
    final overview = AccountsOverview.of(const []);
    expect(overview.totals, isEmpty);
    expect(overview.countedAccounts, 0);
  });
}
