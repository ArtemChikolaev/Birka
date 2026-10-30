import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

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

  /// Sorts [accounts] into active and archived ones and adds up the totals.
  factory AccountsOverview.of(List<AccountBalance> accounts) {
    final counted = [
      for (final row in accounts)
        if (row.account.includeInTotals && !row.account.archived) row,
    ];
    final totals = <String, Money>{};
    for (final row in counted) {
      final code = row.balance.currency.code;
      final total = totals[code];
      totals[code] = total == null ? row.balance : total + row.balance;
    }
    return AccountsOverview(
      active: [
        for (final row in accounts)
          if (!row.account.archived) row,
      ],
      archived: [
        for (final row in accounts)
          if (row.account.archived) row,
      ],
      totals: totals.values.toList(growable: false),
      countedAccounts: counted.length,
    );
  }

  /// The accounts in everyday use. The first one is the main account.
  final List<AccountBalance> active;

  /// The accounts that were put away.
  final List<AccountBalance> archived;

  /// What the counted accounts hold, one amount per currency, in the order of
  /// the accounts. Adding currencies up has to wait for exchange rates.
  final List<Money> totals;

  /// How many accounts the totals cover.
  final int countedAccounts;
}
