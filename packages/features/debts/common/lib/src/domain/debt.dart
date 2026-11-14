import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// One transfer of a debt: money that went into it or came out of it
/// (ADR 0029).
@immutable
final class DebtStep {
  /// Creates a step.
  const DebtStep({
    required this.transactionId,
    required this.day,
    required this.move,
    required this.amount,
    required this.onAccount,
    this.account,
    this.note = '',
  });

  /// The transfer.
  final String transactionId;

  /// The day of the transfer.
  final CivilDate day;

  /// What it did to the debt.
  final DebtMove move;

  /// How much the debt moved, above zero, in the currency of the debt.
  final Money amount;

  /// What it did to the account of the person, with its sign.
  final Money onAccount;

  /// That account, or `null` when the ledger no longer has it.
  final Account? account;

  /// The note of the transfer.
  final String note;

  @override
  bool operator ==(Object other) =>
      other is DebtStep &&
      other.transactionId == transactionId &&
      other.day == day &&
      other.move == move &&
      other.amount == amount &&
      other.onAccount == onAccount &&
      other.account?.id == account?.id &&
      other.account?.name == account?.name &&
      other.note == note;

  @override
  int get hashCode => Object.hash(
    transactionId,
    day,
    move,
    amount,
    onAccount,
    account?.id,
    account?.name,
    note,
  );

  @override
  String toString() => 'DebtStep(${move.name}, $amount, $day)';
}

/// A debt between the person and someone else, named after the other one,
/// with its steps (ADR 0029).
///
/// A debt goes in rounds: a round starts when money goes out while nothing is
/// owed, and ends when what is owed comes back to nought. [total] and
/// [settled] speak of the latest round.
@immutable
final class Debt {
  /// Creates a debt.
  const Debt({
    required this.account,
    required this.left,
    required this.total,
    required this.settled,
    this.since,
    this.closedOn,
    this.steps = const [],
  });

  /// Works out the debt of [account] from its [transactions], in any order,
  /// with [accounts] to name the accounts of the person.
  factory Debt.of(
    Account account,
    Iterable<Transaction> transactions, {
    required Map<String, Account> accounts,
  }) {
    final side = account.debt?.side ?? DebtSide.lent;
    final currency = account.currency;
    final sign = side == DebtSide.lent ? 1 : -1;
    final ordered =
        transactions
            .where(
              (transaction) =>
                  transaction.status != TransactionStatus.planned &&
                  transaction.entries.any(
                    (entry) => entry.accountId == account.id,
                  ),
            )
            .toList()
          ..sort((a, b) {
            final byDay = a.occurredOn.compareTo(b.occurredOn);
            // UUIDv7 ids sort by the moment they were written.
            return byDay != 0 ? byDay : a.id.compareTo(b.id);
          });
    var owed = account.openingBalance.minorUnits * sign;
    var total = owed > 0 ? owed : 0;
    var settled = 0;
    CivilDate? since;
    CivilDate? closedOn;
    final steps = <DebtStep>[];
    for (final transaction in ordered) {
      final entry = transaction.entries.firstWhere(
        (entry) => entry.accountId == account.id,
      );
      final other = transaction.entries
          .where((entry) => entry.accountId != account.id)
          .firstOrNull;
      final move = DebtMove.of(side, into: entry.amount.isPositive);
      final amount = entry.amount.minorUnits.abs();
      if (move.settles) {
        owed -= amount;
        settled += amount;
        if (owed <= 0) closedOn = transaction.occurredOn;
      } else {
        // Money lent once all came back starts a new round. What came back
        // beyond it, as a return dated before the money it returns, counts
        // as returned in the new one.
        if (owed <= 0) {
          total = 0;
          settled = -owed;
          since = transaction.occurredOn;
          closedOn = null;
        }
        since ??= transaction.occurredOn;
        owed += amount;
        total += amount;
      }
      steps.add(
        DebtStep(
          transactionId: transaction.id,
          day: transaction.occurredOn,
          move: move,
          amount: Money(amount, currency),
          onAccount: other?.amount ?? Money.zero(currency),
          account: other == null ? null : accounts[other.accountId],
          note: transaction.note,
        ),
      );
    }
    return Debt(
      account: account,
      left: Money(owed > 0 ? owed : 0, currency),
      total: Money(total, currency),
      settled: Money(settled > total ? total : settled, currency),
      since: since,
      closedOn: owed > 0 ? null : closedOn,
      steps: steps.reversed.toList(),
    );
  }

  /// The account of the debt, named after the other person.
  final Account account;

  /// What is still to come back, nought once all of it has.
  final Money left;

  /// What the latest round came to: all that went out in it.
  final Money total;

  /// What came back of [total].
  final Money settled;

  /// The first day of the latest round.
  final CivilDate? since;

  /// The day the debt came back to nought, while nothing is owed.
  final CivilDate? closedOn;

  /// Its steps, the latest first.
  final List<DebtStep> steps;

  /// The id of the debt, which is the id of its account.
  String get id => account.id;

  /// The name of the other person.
  String get name => account.name;

  /// Who owes whom.
  DebtSide get side => account.debt?.side ?? DebtSide.lent;

  /// The day the debt should come back by.
  CivilDate? get dueOn => account.debt?.dueOn;

  /// Whether the phone reminds of it on [dueOn].
  bool get reminds => account.debt?.reminds ?? false;

  /// The currency of the debt.
  Currency get currency => account.currency;

  /// Whether nothing is owed any more.
  bool get closed => !left.isPositive;

  /// Whether the debt has anything to show: a debt whose steps were all
  /// deleted is no longer there for the person.
  bool get shown => steps.isNotEmpty || left.isPositive;

  /// What part of [total] came back, from 0 to 1.
  double get share => total.isPositive
      ? (settled.minorUnits / total.minorUnits).clamp(0, 1).toDouble()
      : (closed ? 1 : 0);

  /// Whether [dueOn] is [today] or behind it while something is owed.
  bool isDue(CivilDate today) {
    final due = dueOn;
    return !closed && due != null && due.compareTo(today) <= 0;
  }

  @override
  bool operator ==(Object other) =>
      other is Debt &&
      other.account.id == account.id &&
      other.account.name == account.name &&
      other.account.art == account.art &&
      other.account.debt == account.debt &&
      other.left == left &&
      other.total == total &&
      other.settled == settled &&
      other.since == since &&
      other.closedOn == closedOn &&
      _sameSteps(other.steps, steps);

  @override
  int get hashCode => Object.hash(
    account.id,
    account.name,
    account.art,
    account.debt,
    left,
    total,
    settled,
    since,
    closedOn,
    Object.hashAll(steps),
  );

  @override
  String toString() => 'Debt($name, ${side.name}, $left of $total)';
}

bool _sameSteps(List<DebtStep> a, List<DebtStep> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The debts of [debtAccounts] from the [transactions] that move them, with
/// [accounts] to name the accounts of the person. A debt with nothing to
/// show is left out.
List<Debt> debtsOf(
  Iterable<Account> debtAccounts,
  Iterable<Transaction> transactions, {
  required Map<String, Account> accounts,
}) {
  final byAccount = <String, List<Transaction>>{};
  for (final transaction in transactions) {
    for (final entry in transaction.entries) {
      (byAccount[entry.accountId] ??= []).add(transaction);
    }
  }
  return [
    for (final account in debtAccounts)
      if (Debt.of(
            account,
            byAccount[account.id] ?? const [],
            accounts: accounts,
          )
          case final debt when debt.shown)
        debt,
  ];
}
