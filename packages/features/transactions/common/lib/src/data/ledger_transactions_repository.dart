import 'package:device_settings/device_settings.dart';
import 'package:ledger/ledger.dart';
import 'package:rates/rates.dart';
import 'package:transactions_common/src/data/combine_latest.dart';
import 'package:transactions_common/src/domain/month_spending.dart';
import 'package:transactions_common/src/domain/operation.dart';
import 'package:transactions_common/src/domain/rank_categories.dart';
import 'package:transactions_common/src/domain/transactions_repository.dart';

/// Reads operations and the choices of quick add from the ledger, and writes
/// to it.
final class LedgerTransactionsRepository implements TransactionsRepository {
  /// Creates a repository on [_ledger]; [rates] and [monthStart] count the
  /// month of a limit.
  const LedgerTransactionsRepository(
    this._ledger, {
    RatesRepository? rates,
    MonthStart? monthStart,
  }) : _rates = rates,
       _monthStart = monthStart;

  final LedgerRepository _ledger;
  final RatesRepository? _rates;
  final MonthStart? _monthStart;

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
    final entries = latest.firstOrNull?.entries ?? const <Entry>[];
    // A transfer of a debt starts on the debt when money comes back, and the
    // account of the person is the other one (ADR 0029).
    final own = {for (final account in await accounts()) account.id};
    return entries
            .map((entry) => entry.accountId)
            .where(own.contains)
            .firstOrNull ??
        entries.firstOrNull?.accountId;
  }

  @override
  Future<void> record(TransactionDraft draft) => _ledger.record(draft);

  @override
  Stream<List<Operation>> watchOperations(CivilDate month) {
    final last = CivilDate.of(DateTime.utc(month.year, month.month + 1, 0));
    return watchOperationsBetween(month, last);
  }

  @override
  Stream<List<Operation>> watchOperationsBetween(
    CivilDate first,
    CivilDate last,
  ) => combineLatest(
    _ledger.watchTransactions(from: first, to: last, limit: null),
    _watchNames(),
    (transactions, names) => [
      for (final transaction in transactions) names.operationOf(transaction),
    ],
  );

  @override
  Stream<Operation?> watchOperation(String id) => combineLatest(
    _ledger.watchTransaction(id),
    _watchNames(),
    (transaction, names) =>
        transaction == null ? null : names.operationOf(transaction),
  );

  @override
  Future<Operation?> operationOfReceipt(Receipt receipt) async {
    final transaction = await _ledger.transactionOfReceipt(receipt);
    return transaction == null ? null : watchOperation(transaction.id).first;
  }

  @override
  Future<Transaction?> lastOfTill(String drive) => _ledger.lastOfTill(drive);

  @override
  Stream<AccountBalance?> watchAccount(String id) => _ledger
      .watchAccountBalances(includeArchived: true, includeDebts: true)
      .map(
        (rows) => rows.where((row) => row.account.id == id).firstOrNull,
      );

  @override
  Stream<List<DayChange>> watchAccountChanges(
    String id, {
    required CivilDate from,
  }) => _ledger.watchDayChanges(from: from, accountId: id);

  @override
  Stream<List<Operation>> watchAccountOperations(String id) => combineLatest(
    _ledger.watchTransactions(accountId: id),
    _watchNames(),
    (transactions, names) => [
      for (final transaction in transactions) names.operationOf(transaction),
    ],
  );

  @override
  Stream<List<Operation>> watchTagOperations(String id) => combineLatest(
    _ledger.watchTransactions(tagId: id, limit: null),
    _watchNames(),
    (transactions, names) => [
      for (final transaction in transactions) names.operationOf(transaction),
    ],
  );

  @override
  Future<List<Tag>> tags() => _ledger.watchTags().first;

  @override
  Future<List<CivilDate>> months() => _ledger.months();

  @override
  Future<void> amend(String id, TransactionDraft draft) =>
      _ledger.amend(id, draft);

  @override
  Future<void> delete(String id) => _ledger.delete(id);

  /// Old operations keep archived accounts, categories and tags. Following
  /// the catalogs also updates an open search when a name changes.
  Stream<_Names> _watchNames() => combineLatest(
    combineLatest(
      _ledger.watchAccounts(includeArchived: true, includeDebts: true),
      _ledger.watchTags(includeArchived: true),
      (accounts, tags) => (accounts: accounts, tags: tags),
    ),
    combineLatest(
      _ledger.watchCategories(CategoryKind.expense, includeArchived: true),
      _ledger.watchCategories(CategoryKind.income, includeArchived: true),
      (expenses, income) => [...expenses, ...income],
    ),
    (catalog, categories) => _Names(catalog.accounts, categories, catalog.tags),
  );

  @override
  Future<MonthSpending> monthSpending(CivilDate day) async {
    final month = day.monthStart(_monthStart?.day ?? 1);
    final rows = await _ledger
        .watchCategoryDays(
          CategoryKind.expense,
          from: month,
          to: month.addMonths(1).addDays(-1),
        )
        .first;
    final rates = await _rates?.watchRates().first;
    return MonthSpending(
      month: month,
      rows: rows,
      rates: rates ?? const RateBook.empty(),
    );
  }
}

/// What operations name.
final class _Names {
  _Names(List<Account> accounts, List<Category> categories, List<Tag> tags)
    : _accounts = {for (final account in accounts) account.id: account},
      _categories = {for (final category in categories) category.id: category},
      _tagNames = {for (final tag in tags) tag.id: tag.name};

  final Map<String, Account> _accounts;
  final Map<String, Category> _categories;
  final Map<String, String> _tagNames;

  Operation operationOf(Transaction transaction) => Operation.of(
    transaction,
    accounts: _accounts,
    categories: _categories,
    tagNamesById: _tagNames,
  );
}
