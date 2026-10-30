import 'package:ledger/src/civil_date.dart';
import 'package:ledger/src/transaction.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// A transaction before it enters the ledger.
///
/// Each constructor keeps the rules of its kind (ADR 0009), so a draft cannot
/// break them. The amount of an expense comes from its allocations, for
/// example, so the two cannot disagree. Throws an [ArgumentError] on anything
/// that the rules forbid.
@immutable
final class TransactionDraft {
  const TransactionDraft._({
    required this.kind,
    required this.entries,
    required this.allocations,
    required this.occurredOn,
    required this.occurredAt,
    required this.note,
    required this.status,
    required this.source,
  });

  /// Money spent from [accountId], which is the sum of [allocations].
  factory TransactionDraft.expense({
    required String accountId,
    required List<Allocation> allocations,
    required CivilDate occurredOn,
    DateTime? occurredAt,
    String note = '',
    TransactionStatus status = TransactionStatus.cleared,
    TransactionSource source = TransactionSource.manual,
  }) {
    return TransactionDraft._(
      kind: TransactionKind.expense,
      entries: [Entry(accountId: accountId, amount: -_sumOf(allocations))],
      allocations: List.unmodifiable(allocations),
      occurredOn: occurredOn,
      occurredAt: occurredAt,
      note: note,
      status: status,
      source: source,
    );
  }

  /// Money earned on [accountId], which is the sum of [allocations].
  factory TransactionDraft.income({
    required String accountId,
    required List<Allocation> allocations,
    required CivilDate occurredOn,
    DateTime? occurredAt,
    String note = '',
    TransactionStatus status = TransactionStatus.cleared,
    TransactionSource source = TransactionSource.manual,
  }) {
    return TransactionDraft._(
      kind: TransactionKind.income,
      entries: [Entry(accountId: accountId, amount: _sumOf(allocations))],
      allocations: List.unmodifiable(allocations),
      occurredOn: occurredOn,
      occurredAt: occurredAt,
      note: note,
      status: status,
      source: source,
    );
  }

  /// Money moved between accounts: [sent] leaves [fromAccountId] and
  /// [received] arrives on [toAccountId].
  ///
  /// In one currency the two are equal. Between currencies they keep what
  /// actually happened, and the rate follows from them.
  factory TransactionDraft.transfer({
    required String fromAccountId,
    required Money sent,
    required String toAccountId,
    required Money received,
    required CivilDate occurredOn,
    DateTime? occurredAt,
    String note = '',
    TransactionStatus status = TransactionStatus.cleared,
    TransactionSource source = TransactionSource.manual,
  }) {
    if (fromAccountId == toAccountId) {
      throw ArgumentError('A transfer needs two different accounts');
    }
    if (!sent.isPositive || !received.isPositive) {
      throw ArgumentError('A transfer moves a positive amount');
    }
    if (sent.currency == received.currency && sent != received) {
      throw ArgumentError('$sent cannot arrive as $received');
    }
    return TransactionDraft._(
      kind: TransactionKind.transfer,
      entries: [
        Entry(accountId: fromAccountId, amount: -sent),
        Entry(accountId: toAccountId, amount: received),
      ],
      allocations: const [],
      occurredOn: occurredOn,
      occurredAt: occurredAt,
      note: note,
      status: status,
      source: source,
    );
  }

  /// A correction of the balance of [accountId] by [change], up or down.
  factory TransactionDraft.adjustment({
    required String accountId,
    required Money change,
    required CivilDate occurredOn,
    DateTime? occurredAt,
    String note = '',
    TransactionStatus status = TransactionStatus.cleared,
    TransactionSource source = TransactionSource.manual,
  }) {
    if (change.isZero) {
      throw ArgumentError('An adjustment changes the balance');
    }
    return TransactionDraft._(
      kind: TransactionKind.adjustment,
      entries: [Entry(accountId: accountId, amount: change)],
      allocations: const [],
      occurredOn: occurredOn,
      occurredAt: occurredAt,
      note: note,
      status: status,
      source: source,
    );
  }

  /// What kind of event it is.
  final TransactionKind kind;

  /// How it moves money.
  final List<Entry> entries;

  /// The categories it goes to.
  final List<Allocation> allocations;

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

  static Money _sumOf(List<Allocation> allocations) {
    if (allocations.isEmpty) {
      throw ArgumentError('Name at least one category');
    }
    final amounts = allocations.map((allocation) => allocation.amount);
    if (amounts.any((amount) => !amount.isPositive)) {
      throw ArgumentError('An allocation is a positive amount');
    }
    return amounts.reduce((sum, amount) => sum + amount);
  }
}
