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
    required this.currency,
    required this.art,
    required this.includeInTotals,
    this.balance,
    this.lastDigits,
  });

  /// The name the user sees.
  final String name;

  /// The kind of the account.
  final AccountType type;

  /// The currency, which only a new account can choose.
  final Currency currency;

  /// What the account should hold. A new account starts from it, or from zero
  /// without it. A saved one gets a correction for the difference, and stays as
  /// it is without it.
  final Money? balance;

  /// The art of the account.
  final AccountArt art;

  /// Whether the account counts towards the totals.
  final bool includeInTotals;

  /// The last digits of the card, if there are any.
  final String? lastDigits;
}
