import 'package:ledger/ledger.dart';
import 'package:transactions_common/src/domain/rank_categories.dart';
import 'package:transactions_common/src/domain/transactions_repository.dart';

/// Reads the choices of quick add from the ledger and writes to it.
final class LedgerTransactionsRepository implements TransactionsRepository {
  /// Creates a repository on [_ledger].
  const LedgerTransactionsRepository(this._ledger);

  final LedgerRepository _ledger;

  @override
  Future<List<Account>> accounts() => _ledger.watchAccounts().first;

  @override
  Future<List<Category>> categories(CategoryKind kind) async {
    final categories = await _ledger.watchCategories(kind).first;
    final recent = await _ledger.watchTransactions().first;
    return rankCategories(categories, recent);
  }

  @override
  Future<String?> lastAccountId() async {
    final latest = await _ledger.watchTransactions(limit: 1).first;
    return latest.firstOrNull?.entries.firstOrNull?.accountId;
  }

  @override
  Future<void> record(TransactionDraft draft) => _ledger.record(draft);
}
