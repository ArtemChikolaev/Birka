import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// The accounts as a screen shows them.
@immutable
final class AccountsOverview {
  /// Creates an overview of [active] and [archived] accounts.
  const AccountsOverview({
    required this.active,
    required this.archived,
    required this.totals,
    required this.countedAccounts,
  });

  /// Sorts [accounts] into active and archived ones and adds up the totals in
  /// [base] at [rates].
  factory AccountsOverview.of(
    List<AccountBalance> accounts, {
    RateBook rates = const RateBook.empty(),
    Currency? base,
  }) {
    final counted = [
      for (final row in accounts)
        if (row.account.includeInTotals && !row.account.archived) row,
    ];
    final capital = Capital.of(counted, rates: rates, base: base);
    return AccountsOverview(
      active: [
        for (final row in accounts)
          if (!row.account.archived) row,
      ],
      archived: [
        for (final row in accounts)
          if (row.account.archived) row,
      ],
      totals: [?capital.main, ...capital.others],
      countedAccounts: counted.length,
    );
  }

  /// The accounts in everyday use. The first one is the main account.
  final List<AccountBalance> active;

  /// The accounts that were put away.
  final List<AccountBalance> archived;

  /// What the counted accounts come to, and after it the amounts that no rate
  /// can add to it yet.
  final List<Money> totals;

  /// How many accounts the totals cover.
  final int countedAccounts;
}
