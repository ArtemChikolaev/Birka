import 'package:inbox_common/src/domain/inbox_repository.dart';
import 'package:inbox_common/src/domain/transfer_pairs.dart';
import 'package:ledger/ledger.dart';
import 'package:rates/rates.dart';

/// The inbox on the ledger and the rates of the device.
final class LedgerInboxRepository implements InboxRepository {
  /// Creates the repository on [_ledger] and [_rates].
  LedgerInboxRepository(this._ledger, this._rates);

  final LedgerRepository _ledger;
  final RatesRepository _rates;

  @override
  Stream<List<Transaction>> watchTransactions() =>
      _ledger.watchTransactions(limit: null);

  @override
  Stream<List<Account>> watchAccounts() =>
      _ledger.watchAccounts(includeArchived: true);

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) =>
      _ledger.watchCategories(kind, includeArchived: true);

  @override
  Stream<RateBook> watchRates() => _rates.watchRates();

  @override
  Stream<List<LedgerImport>> watchImports() => _ledger.watchImports();

  @override
  Future<void> categorize(List<(Transaction, String)> choices) =>
      _ledger.atomically(() async {
        for (final (transaction, categoryId) in choices) {
          await _ledger.amend(
            transaction.id,
            _withCategory(transaction, categoryId),
          );
        }
      });

  @override
  Future<String> makeTransfer(TransferPair pair) =>
      _ledger.atomically(() async {
        await _ledger.delete(pair.out.id);
        await _ledger.delete(pair.into.id);
        return _ledger.record(
          TransactionDraft.transfer(
            fromAccountId: pair.fromAccountId,
            sent: pair.sent,
            toAccountId: pair.toAccountId,
            received: pair.received,
            occurredOn: pair.out.occurredOn,
            occurredAt: pair.out.occurredAt,
            note: {
              for (final note in [pair.out.note, pair.into.note])
                if (note.trim().isNotEmpty) note.trim(),
            }.join(' · '),
          ),
        );
      });

  /// [transaction] as it stands, with [categoryId] where it has none.
  static TransactionDraft _withCategory(
    Transaction transaction,
    String categoryId,
  ) {
    final allocations = [
      for (final allocation in transaction.allocations)
        Allocation(
          categoryId: allocation.categoryId ?? categoryId,
          amount: allocation.amount,
        ),
    ];
    final accountId = transaction.entries.single.accountId;
    return switch (transaction.kind) {
      TransactionKind.expense => TransactionDraft.expense(
        accountId: accountId,
        allocations: allocations,
        occurredOn: transaction.occurredOn,
        occurredAt: transaction.occurredAt,
        note: transaction.note,
        status: transaction.status,
        source: transaction.source,
      ),
      TransactionKind.income => TransactionDraft.income(
        accountId: accountId,
        allocations: allocations,
        occurredOn: transaction.occurredOn,
        occurredAt: transaction.occurredAt,
        note: transaction.note,
        status: transaction.status,
        source: transaction.source,
      ),
      TransactionKind.transfer || TransactionKind.adjustment =>
        throw ArgumentError('Only an expense or an income has a category'),
    };
  }
}
