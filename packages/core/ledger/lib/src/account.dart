import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// What kind of place money lives in.
enum AccountType {
  /// Cash in a wallet.
  cash,

  /// A debit card or a current account.
  debit,

  /// A credit card.
  credit,

  /// A savings account.
  savings,

  /// A term deposit.
  deposit,

  /// A loan taken.
  loan,

  /// Money that someone owes or is owed.
  debt,

  /// A brokerage account.
  investment,

  /// A crypto wallet.
  crypto,
}

/// Where money lives. Its currency never changes.
@immutable
final class Account {
  /// Creates an account.
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.includeInTotals,
    required this.archived,
    required this.sortOrder,
  });

  /// The id.
  final String id;

  /// The name the user sees.
  final String name;

  /// The kind of the account.
  final AccountType type;

  /// The balance before the first entry. Its currency is the currency of the
  /// account.
  final Money openingBalance;

  /// Whether the account counts towards the capital.
  final bool includeInTotals;

  /// Whether the account is hidden from everyday lists.
  final bool archived;

  /// The place of the account in lists.
  final int sortOrder;

  /// The currency of the account.
  Currency get currency => openingBalance.currency;
}
