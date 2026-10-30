import 'package:database/database.dart';
import 'package:drift/drift.dart';
import 'package:ledger/src/account.dart';
import 'package:ledger/src/category.dart';
import 'package:ledger/src/civil_date.dart';
import 'package:ledger/src/ledger_exception.dart';
import 'package:ledger/src/transaction.dart';
import 'package:ledger/src/transaction_draft.dart';
import 'package:money/money.dart';
import 'package:uuid/uuid.dart';

/// Reads and writes the ledger, and keeps the rules of ADR 0009.
///
/// Every write is one database transaction: it stamps the rows, leaves
/// tombstones instead of deleting, and records each change in the outbox.
final class LedgerRepository {
  /// Creates a repository on [_db]. Tests can fix [now] and [newId].
  LedgerRepository(
    this._db, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? const Uuid().v7;

  final BirkaDatabase _db;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Adds an account. The currency of [openingBalance] becomes the currency
  /// of the account for good.
  Future<Account> addAccount({
    required String name,
    required AccountType type,
    required Money openingBalance,
    bool includeInTotals = true,
    int sortOrder = 0,
  }) {
    return _db.transaction(() async {
      final id = _newId();
      final at = _timestamp();
      final row = await _db
          .into(_db.accounts)
          .insertReturning(
            AccountsCompanion.insert(
              id: id,
              createdAt: at,
              updatedAt: at,
              name: name,
              type: type.name,
              currency: openingBalance.currency.code,
              decimalDigits: openingBalance.currency.decimalDigits,
              openingBalanceMinor: Value(openingBalance.minorUnits),
              includeInTotals: Value(includeInTotals),
              sortOrder: Value(sortOrder),
            ),
          );
      await _log(_db.accounts, id, 'insert', at);
      return _accountOf(row);
    });
  }

  /// Changes the given fields of an account.
  Future<void> updateAccount(
    String id, {
    String? name,
    bool? includeInTotals,
    bool? archived,
    int? sortOrder,
  }) {
    return _db.transaction(() async {
      final at = _timestamp();
      final updated =
          await (_db.update(
            _db.accounts,
          )..where((row) => row.id.equals(id) & row.deletedAt.isNull())).write(
            AccountsCompanion(
              updatedAt: Value(at),
              name: Value.absentIfNull(name),
              includeInTotals: Value.absentIfNull(includeInTotals),
              archived: Value.absentIfNull(archived),
              sortOrder: Value.absentIfNull(sortOrder),
            ),
          );
      if (updated == 0) throw LedgerException('No account $id');
      await _log(_db.accounts, id, 'update', at);
    });
  }

  /// The accounts in their order, without archived ones unless asked.
  Stream<List<Account>> watchAccounts({bool includeArchived = false}) {
    final query = _db.select(_db.accounts)
      ..where(
        (row) =>
            row.deletedAt.isNull() &
            (includeArchived ? const Constant(true) : row.archived.not()),
      )
      ..orderBy([
        (row) => OrderingTerm(expression: row.sortOrder),
        (row) => OrderingTerm(expression: row.name),
      ]);
    return query.watch().map((rows) => rows.map(_accountOf).toList());
  }

  /// The balance of an account: the opening balance plus every entry that is
  /// not planned. It is computed each time and stored nowhere.
  Stream<Money> watchBalance(String accountId) {
    return _db
        .customSelect(
          '''
          SELECT a.currency, a.decimal_digits,
            a.opening_balance_minor + COALESCE((
              SELECT SUM(e.amount_minor) FROM entries e
              JOIN transactions t ON t.id = e.transaction_id
              WHERE e.account_id = a.id
                AND e.deleted_at IS NULL
                AND t.deleted_at IS NULL
                AND t.status <> ?
            ), 0) AS balance
          FROM accounts a WHERE a.id = ?
          ''',
          variables: [
            Variable.withString(TransactionStatus.planned.name),
            Variable.withString(accountId),
          ],
          readsFrom: {_db.accounts, _db.entries, _db.transactions},
        )
        .watchSingle()
        .map(
          (row) => Money(
            row.read<int>('balance'),
            _currency(row.read<String>('currency'), row.read('decimal_digits')),
          ),
        );
  }

  /// Adds a category.
  Future<Category> addCategory({
    required CategoryKind kind,
    required String name,
    String? parentId,
    String? icon,
    String? color,
    int sortOrder = 0,
  }) {
    return _db.transaction(() async {
      final id = _newId();
      final at = _timestamp();
      final row = await _db
          .into(_db.categories)
          .insertReturning(
            CategoriesCompanion.insert(
              id: id,
              createdAt: at,
              updatedAt: at,
              kind: kind.name,
              name: name,
              parentId: Value(parentId),
              icon: Value(icon),
              color: Value(color),
              sortOrder: Value(sortOrder),
            ),
          );
      await _log(_db.categories, id, 'insert', at);
      return _categoryOf(row);
    });
  }

  /// The categories of [kind] in their order, without archived ones.
  Stream<List<Category>> watchCategories(CategoryKind kind) {
    final query = _db.select(_db.categories)
      ..where(
        (row) =>
            row.kind.equals(kind.name) &
            row.deletedAt.isNull() &
            row.archived.not(),
      )
      ..orderBy([
        (row) => OrderingTerm(expression: row.sortOrder),
        (row) => OrderingTerm(expression: row.name),
      ]);
    return query.watch().map((rows) => rows.map(_categoryOf).toList());
  }

  /// Puts [draft] into the ledger and returns its id.
  Future<String> record(TransactionDraft draft) {
    return _db.transaction(() async {
      await _check(draft);
      final id = _newId();
      final at = _timestamp();
      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: id,
              createdAt: at,
              updatedAt: at,
              kind: draft.kind.name,
              occurredOn: draft.occurredOn.toString(),
              occurredAt: Value(draft.occurredAt?.toUtc()),
              note: Value(draft.note),
              status: draft.status.name,
              source: draft.source.name,
            ),
          );
      await _log(_db.transactions, id, 'insert', at);
      await _writeLegs(id, draft, at);
      return id;
    });
  }

  /// Replaces transaction [id] with [draft]. Its old entries and allocations
  /// become tombstones.
  Future<void> amend(String id, TransactionDraft draft) {
    return _db.transaction(() async {
      await _check(draft);
      final at = _timestamp();
      final updated =
          await (_db.update(
            _db.transactions,
          )..where((row) => row.id.equals(id) & row.deletedAt.isNull())).write(
            TransactionsCompanion(
              updatedAt: Value(at),
              kind: Value(draft.kind.name),
              occurredOn: Value(draft.occurredOn.toString()),
              occurredAt: Value(draft.occurredAt?.toUtc()),
              note: Value(draft.note),
              status: Value(draft.status.name),
              source: Value(draft.source.name),
            ),
          );
      if (updated == 0) throw LedgerException('No transaction $id');
      await _log(_db.transactions, id, 'update', at);
      await _buryLegs(id, at);
      await _writeLegs(id, draft, at);
    });
  }

  /// Deletes transaction [id]: it and its legs become tombstones.
  Future<void> delete(String id) {
    return _db.transaction(() async {
      final at = _timestamp();
      final updated =
          await (_db.update(
            _db.transactions,
          )..where((row) => row.id.equals(id) & row.deletedAt.isNull())).write(
            TransactionsCompanion(updatedAt: Value(at), deletedAt: Value(at)),
          );
      if (updated == 0) throw LedgerException('No transaction $id');
      await _log(_db.transactions, id, 'delete', at);
      await _buryLegs(id, at);
    });
  }

  /// The latest [limit] transactions, of [accountId] if it is given.
  Stream<List<Transaction>> watchTransactions({
    String? accountId,
    int limit = 200,
  }) {
    final query = _db.select(_db.transactions)
      ..where((row) {
        final live = row.deletedAt.isNull();
        if (accountId == null) return live;
        final ofAccount = _db.selectOnly(_db.entries)
          ..addColumns([_db.entries.transactionId])
          ..where(
            _db.entries.accountId.equals(accountId) &
                _db.entries.deletedAt.isNull(),
          );
        return live & row.id.isInQuery(ofAccount);
      })
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.occurredOn, mode: OrderingMode.desc),
        // UUIDv7 ids sort by the moment of creation.
        (row) => OrderingTerm(expression: row.id, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return query.watch().asyncMap(_withLegs);
  }

  DateTime _timestamp() => _now().toUtc();

  Future<void> _log(
    TableInfo<Table, Object?> table,
    String id,
    String operation,
    DateTime at,
  ) {
    return _db
        .into(_db.changes)
        .insert(
          ChangesCompanion.insert(
            entity: table.actualTableName,
            entityId: id,
            operation: operation,
            changedAt: at,
          ),
        );
  }

  /// Checks what only the database can tell: that the accounts and the
  /// categories exist and fit the draft.
  Future<void> _check(TransactionDraft draft) async {
    for (final entry in draft.entries) {
      final account =
          await (_db.select(_db.accounts)..where(
                (row) =>
                    row.id.equals(entry.accountId) & row.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (account == null) {
        throw LedgerException('No account ${entry.accountId}');
      }
      final currency = _currency(account.currency, account.decimalDigits);
      if (entry.amount.currency != currency) {
        throw LedgerException(
          'Account ${account.name} is in $currency, not in '
          '${entry.amount.currency}',
        );
      }
    }
    for (final allocation in draft.allocations) {
      final category =
          await (_db.select(_db.categories)..where(
                (row) =>
                    row.id.equals(allocation.categoryId) &
                    row.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (category == null) {
        throw LedgerException('No category ${allocation.categoryId}');
      }
      if (category.kind != draft.kind.name) {
        throw LedgerException(
          'Category ${category.name} is not for ${draft.kind.name}',
        );
      }
    }
  }

  Future<void> _writeLegs(
    String transactionId,
    TransactionDraft draft,
    DateTime at,
  ) async {
    for (final entry in draft.entries) {
      final id = _newId();
      await _db
          .into(_db.entries)
          .insert(
            EntriesCompanion.insert(
              id: id,
              createdAt: at,
              updatedAt: at,
              transactionId: transactionId,
              accountId: entry.accountId,
              amountMinor: entry.amount.minorUnits,
            ),
          );
      await _log(_db.entries, id, 'insert', at);
    }
    for (final allocation in draft.allocations) {
      final id = _newId();
      await _db
          .into(_db.allocations)
          .insert(
            AllocationsCompanion.insert(
              id: id,
              createdAt: at,
              updatedAt: at,
              transactionId: transactionId,
              categoryId: allocation.categoryId,
              amountMinor: allocation.amount.minorUnits,
            ),
          );
      await _log(_db.allocations, id, 'insert', at);
    }
  }

  Future<void> _buryLegs(String transactionId, DateTime at) async {
    final entries =
        await (_db.update(_db.entries)..where(
              (row) =>
                  row.transactionId.equals(transactionId) &
                  row.deletedAt.isNull(),
            ))
            .writeReturning(
              EntriesCompanion(updatedAt: Value(at), deletedAt: Value(at)),
            );
    for (final entry in entries) {
      await _log(_db.entries, entry.id, 'delete', at);
    }
    final allocations =
        await (_db.update(_db.allocations)..where(
              (row) =>
                  row.transactionId.equals(transactionId) &
                  row.deletedAt.isNull(),
            ))
            .writeReturning(
              AllocationsCompanion(updatedAt: Value(at), deletedAt: Value(at)),
            );
    for (final allocation in allocations) {
      await _log(_db.allocations, allocation.id, 'delete', at);
    }
  }

  Future<List<Transaction>> _withLegs(List<TransactionRow> rows) async {
    final ids = rows.map((row) => row.id).toList();
    final entryRows =
        await (_db.select(_db.entries).join([
                innerJoin(
                  _db.accounts,
                  _db.accounts.id.equalsExp(_db.entries.accountId),
                ),
              ])
              ..where(
                _db.entries.transactionId.isIn(ids) &
                    _db.entries.deletedAt.isNull(),
              )
              ..orderBy([OrderingTerm(expression: _db.entries.id)]))
            .get();
    final entries = <String, List<Entry>>{};
    final currencies = <String, Currency>{};
    for (final joined in entryRows) {
      final entry = joined.readTable(_db.entries);
      final account = joined.readTable(_db.accounts);
      final currency = _currency(account.currency, account.decimalDigits);
      currencies[entry.transactionId] = currency;
      (entries[entry.transactionId] ??= []).add(
        Entry(
          accountId: entry.accountId,
          amount: Money(entry.amountMinor, currency),
        ),
      );
    }
    final allocationRows =
        await (_db.select(_db.allocations)
              ..where(
                (row) => row.transactionId.isIn(ids) & row.deletedAt.isNull(),
              )
              ..orderBy([(row) => OrderingTerm(expression: row.id)]))
            .get();
    final allocations = <String, List<Allocation>>{};
    for (final allocation in allocationRows) {
      (allocations[allocation.transactionId] ??= []).add(
        Allocation(
          categoryId: allocation.categoryId,
          amount: Money(
            allocation.amountMinor,
            currencies[allocation.transactionId]!,
          ),
        ),
      );
    }
    return [
      for (final row in rows)
        Transaction(
          id: row.id,
          kind: TransactionKind.values.byName(row.kind),
          occurredOn: CivilDate.parse(row.occurredOn),
          occurredAt: row.occurredAt,
          note: row.note,
          status: TransactionStatus.values.byName(row.status),
          source: TransactionSource.values.byName(row.source),
          entries: entries[row.id] ?? const [],
          allocations: allocations[row.id] ?? const [],
        ),
    ];
  }

  Currency _currency(String code, int decimalDigits) =>
      Currency.custom(code, decimalDigits: decimalDigits);

  Account _accountOf(AccountRow row) => Account(
    id: row.id,
    name: row.name,
    type: AccountType.values.byName(row.type),
    openingBalance: Money(
      row.openingBalanceMinor,
      _currency(row.currency, row.decimalDigits),
    ),
    includeInTotals: row.includeInTotals,
    archived: row.archived,
    sortOrder: row.sortOrder,
  );

  Category _categoryOf(CategoryRow row) => Category(
    id: row.id,
    parentId: row.parentId,
    kind: CategoryKind.values.byName(row.kind),
    name: row.name,
    icon: row.icon,
    color: row.color,
    archived: row.archived,
    sortOrder: row.sortOrder,
  );
}
