import 'package:ledger/src/civil_date.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// What kind of event a transaction is.
enum TransactionKind {
  /// Money spent: one negative entry.
  expense,

  /// Money earned: one positive entry.
  income,

  /// Money moved between two accounts: two entries with opposite signs.
  transfer,

  /// A correction of a balance: one entry without categories.
  adjustment,
}

/// How far a transaction has come.
enum TransactionStatus {
  /// It is expected and does not count towards balances yet.
  planned,

  /// It happened and the bank has not settled it yet.
  pending,

  /// It happened.
  cleared,

  /// It has been checked against a statement.
  reconciled,
}

/// Where a transaction came from.
enum TransactionSource {
  /// The user entered it.
  manual,

  /// A statement file.
  import,

  /// A notification from a bank.
  notification,

  /// A recurring payment.
  recurring,

  /// A connection to a bank.
  bank,
}

/// How a transaction moves money on an account.
@immutable
final class Entry {
  /// Creates an entry.
  const Entry({required this.accountId, required this.amount});

  /// The account the money moves on.
  final String accountId;

  /// The signed amount in the currency of the account.
  final Money amount;
}

/// The part of a transaction that goes to a category.
@immutable
final class Allocation {
  /// Creates an allocation.
  const Allocation({required this.categoryId, required this.amount});

  /// The category.
  final String categoryId;

  /// The positive amount.
  final Money amount;
}

/// A transaction in the ledger.
@immutable
final class Transaction {
  /// Creates a transaction.
  const Transaction({
    required this.id,
    required this.kind,
    required this.occurredOn,
    required this.note,
    required this.status,
    required this.source,
    required this.entries,
    required this.allocations,
    this.occurredAt,
  });

  /// The id.
  final String id;

  /// What kind of event it is.
  final TransactionKind kind;

  /// The day it happened.
  final CivilDate occurredOn;

  /// The moment it happened, when it is known.
  final DateTime? occurredAt;

  /// The note of the user.
  final String note;

  /// How far it has come.
  final TransactionStatus status;

  /// Where it came from.
  final TransactionSource source;

  /// How it moves money, with what leaves an account first.
  final List<Entry> entries;

  /// The categories it goes to.
  final List<Allocation> allocations;
}
