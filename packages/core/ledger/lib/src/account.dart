import 'package:ledger/src/civil_date.dart';
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

/// The abstract art that an account wears in lists.
enum AccountArt {
  /// Green on black.
  emerald,

  /// Gray with a light stripe.
  graphite,

  /// Blue on black.
  sapphire,

  /// Warm brown on black.
  amber,

  /// Violet on black.
  violet,

  /// Pink on black.
  rose,
}

/// Who owes whom on a debt (ADR 0029).
enum DebtSide {
  /// The person lent: the other one owes them, and the account of the debt
  /// holds what is to come back, above zero.
  lent,

  /// The person borrowed: they owe the other one, and the account of the debt
  /// holds what they are to give back, below zero.
  borrowed,
}

/// What a transfer does to a debt, as the person sees it (ADR 0029).
enum DebtMove {
  /// The person lent: money went from their account into the debt.
  lent,

  /// The other one gave back what they owed: money came out of the debt.
  returned,

  /// The person borrowed: money came to them out of the debt.
  borrowed,

  /// The person gave back what they owed: money went into the debt.
  repaid
  ;

  /// What a transfer does to a debt of [side]: one [into] the debt, or one
  /// out of it.
  static DebtMove of(DebtSide side, {required bool into}) =>
      switch ((side, into)) {
        (DebtSide.lent, true) => lent,
        (DebtSide.lent, false) => returned,
        (DebtSide.borrowed, false) => borrowed,
        (DebtSide.borrowed, true) => repaid,
      };

  /// Whether the move brings the debt closer to nought.
  bool get settles => this == returned || this == repaid;
}

/// What a debt keeps besides its money: who owes whom, by what day, and
/// whether the phone reminds of that day (ADR 0029).
@immutable
final class DebtTerms {
  /// Creates the terms of a debt.
  const DebtTerms({required this.side, this.dueOn, this.reminds = false});

  /// Who owes whom.
  final DebtSide side;

  /// The day the debt should come back by, when one was given.
  final CivilDate? dueOn;

  /// Whether the phone reminds of the debt on [dueOn].
  final bool reminds;

  /// The same terms with the given fields changed. [dueOn] takes a function,
  /// so that it can become `null`.
  DebtTerms copyWith({
    DebtSide? side,
    CivilDate? Function()? dueOn,
    bool? reminds,
  }) => DebtTerms(
    side: side ?? this.side,
    dueOn: dueOn == null ? this.dueOn : dueOn(),
    reminds: reminds ?? this.reminds,
  );

  @override
  bool operator ==(Object other) =>
      other is DebtTerms &&
      other.side == side &&
      other.dueOn == dueOn &&
      other.reminds == reminds;

  @override
  int get hashCode => Object.hash(side, dueOn, reminds);

  @override
  String toString() => 'DebtTerms(${side.name}, $dueOn, reminds: $reminds)';
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
    this.lastDigits,
    this.art = AccountArt.emerald,
    this.debt,
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

  /// The last digits of the card, when the user gave them.
  final String? lastDigits;

  /// The art of the account.
  final AccountArt art;

  /// What a debt keeps besides its money, and `null` on every other account.
  /// An account of a debt is named after the person (ADR 0029).
  final DebtTerms? debt;

  /// Whether the account is a debt between the person and someone else.
  bool get isDebt => type == AccountType.debt;

  /// The currency of the account.
  Currency get currency => openingBalance.currency;
}

/// An account with the money on it now.
@immutable
final class AccountBalance {
  /// Creates a pair of [account] and its [balance].
  const AccountBalance(this.account, this.balance);

  /// The account.
  final Account account;

  /// What the account holds now.
  final Money balance;
}
