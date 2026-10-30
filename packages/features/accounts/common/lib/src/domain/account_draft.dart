import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// What the form hands over to create or change an account.
@immutable
final class AccountDraft {
  /// Creates a draft.
  const AccountDraft({
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.art,
    required this.includeInTotals,
    this.lastDigits,
  });

  /// The name the user sees.
  final String name;

  /// The kind of the account.
  final AccountType type;

  /// The balance before the first entry, in the currency of the account.
  final Money openingBalance;

  /// The art of the account.
  final AccountArt art;

  /// Whether the account counts towards the totals.
  final bool includeInTotals;

  /// The last digits of the card, if there are any.
  final String? lastDigits;
}
