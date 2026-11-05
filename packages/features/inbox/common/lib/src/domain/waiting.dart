import 'package:inbox_common/src/domain/transfer_pairs.dart';
import 'package:ledger/ledger.dart';
import 'package:rates/rates.dart';

/// What waits in the inbox among [transactions] (ADR 0022): the transfers
/// to link by [rates], but the pairs of [dismissed], and the operations
/// without a category that are in none of them, the earliest first.
({List<Transaction> waiting, List<TransferPair> pairs}) waitingIn(
  List<Transaction> transactions, {
  required RateBook rates,
  required Set<String> dismissed,
}) {
  final pairs = transferPairs(transactions, rates: rates, dismissed: dismissed);
  final paired = {
    for (final pair in pairs) ...[pair.out.id, pair.into.id],
  };
  return (
    waiting: [
      for (final transaction in transactions)
        if (_waits(transaction) && !paired.contains(transaction.id))
          transaction,
    ]..sort(_byDay),
    pairs: pairs,
  );
}

/// Whether [transaction] is spending or earning with a part of no category.
bool _waits(Transaction transaction) =>
    (transaction.kind == TransactionKind.expense ||
        transaction.kind == TransactionKind.income) &&
    transaction.allocations.any((it) => it.categoryId == null);

int _byDay(Transaction a, Transaction b) {
  final byDay = a.occurredOn.compareTo(b.occurredOn);
  return byDay != 0 ? byDay : a.id.compareTo(b.id);
}
