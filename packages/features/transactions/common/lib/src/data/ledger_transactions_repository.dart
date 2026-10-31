import 'package:ledger/ledger.dart';
import 'package:transactions_common/src/data/combine_latest.dart';
import 'package:transactions_common/src/domain/operation.dart';
import 'package:transactions_common/src/domain/rank_categories.dart';
import 'package:transactions_common/src/domain/transactions_repository.dart';

/// Reads operations and the choices of quick add from the ledger, and writes
/// to it.
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

  @override
  Stream<List<Operation>> watchOperations(CivilDate month) {
    final last = CivilDate.of(DateTime.utc(month.year, month.month + 1, 0));
    return combineLatest(
      _ledger.watchTransactions(from: month, to: last, limit: null),
      _watchNames(),
      (transactions, names) => [
        for (final transaction in transactions) names.operationOf(transaction),
      ],
    );
  }

  @override
  Stream<Operation?> watchOperation(String id) => combineLatest(
    _ledger.watchTransaction(id),
    _watchNames(),
    (transaction, names) =>
        transaction == null ? null : names.operationOf(transaction),
  );

  @override
  Future<List<CivilDate>> months() => _ledger.months();

  @override
  Future<void> amend(String id, TransactionDraft draft) =>
      _ledger.amend(id, draft);

  @override
  Future<void> delete(String id) => _ledger.delete(id);

  /// Every account and category, archived ones too, since old operations keep
  /// them. Following them keeps a list right after a change of a name.
  Stream<_Names> _watchNames() => combineLatest(
    _ledger.watchAccounts(includeArchived: true),
    combineLatest(
      _ledger.watchCategories(CategoryKind.expense, includeArchived: true),
      _ledger.watchCategories(CategoryKind.income, includeArchived: true),
      (expenses, income) => [...expenses, ...income],
    ),
    _Names.new,
  );
}

/// What operations name.
final class _Names {
  _Names(List<Account> accounts, List<Category> categories)
    : _accounts = {for (final account in accounts) account.id: account},
      _categories = {for (final category in categories) category.id: category};

  final Map<String, Account> _accounts;
  final Map<String, Category> _categories;

  Operation operationOf(Transaction transaction) => Operation.of(
    transaction,
    accounts: _accounts,
    categories: _categories,
  );
}
