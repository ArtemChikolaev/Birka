import 'package:database/database.dart';
import 'package:drift/drift.dart';
import 'package:ledger/src/account.dart';
import 'package:ledger/src/category.dart';
import 'package:ledger/src/civil_date.dart';
import 'package:ledger/src/ledger_exception.dart';
import 'package:ledger/src/ledger_totals.dart';
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

  /// Adds an account, after the others unless [sortOrder] says otherwise.
  /// The currency of [openingBalance] becomes the currency of the account for
  /// good.
  Future<Account> addAccount({
    required String name,
    required AccountType type,
    required Money openingBalance,
    String? lastDigits,
    AccountArt art = AccountArt.emerald,
    bool includeInTotals = true,
    int? sortOrder,
  }) {
    return _db.transaction(() async {
      final id = _newId();
      final at = _timestamp();
      final last = _db.accounts.sortOrder.max();
      final position =
          sortOrder ??
          await (_db.selectOnly(_db.accounts)
                ..addColumns([last])
                ..where(_db.accounts.deletedAt.isNull()))
              .map((row) => (row.read(last) ?? -1) + 1)
              .getSingle();
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
              lastDigits: Value(lastDigits),
              art: Value(art.name),
              includeInTotals: Value(includeInTotals),
              sortOrder: Value(position),
            ),
          );
      await _log(_db.accounts, id, 'insert', at);
      return _accountOf(row);
    });
  }

  /// Changes the given fields of an account. The currency of
  /// [openingBalance] has to stay the currency of the account.
  Future<void> updateAccount(
    String id, {
    String? name,
    AccountType? type,
    Money? openingBalance,
    Value<String?> lastDigits = const Value.absent(),
    AccountArt? art,
    bool? includeInTotals,
    bool? archived,
    int? sortOrder,
  }) {
    return _db.transaction(() async {
      final at = _timestamp();
      if (openingBalance != null) {
        final account = await this.account(id);
        if (account != null && account.currency != openingBalance.currency) {
          throw LedgerException(
            'Account ${account.name} is in ${account.currency}, not in '
            '${openingBalance.currency}',
          );
        }
      }
      final updated =
          await (_db.update(
            _db.accounts,
          )..where((row) => row.id.equals(id) & row.deletedAt.isNull())).write(
            AccountsCompanion(
              updatedAt: Value(at),
              name: Value.absentIfNull(name),
              type: Value.absentIfNull(type?.name),
              openingBalanceMinor: Value.absentIfNull(
                openingBalance?.minorUnits,
              ),
              lastDigits: lastDigits,
              art: Value.absentIfNull(art?.name),
              includeInTotals: Value.absentIfNull(includeInTotals),
              archived: Value.absentIfNull(archived),
              sortOrder: Value.absentIfNull(sortOrder),
            ),
          );
      if (updated == 0) throw LedgerException('No account $id');
      await _log(_db.accounts, id, 'update', at);
    });
  }

  /// The account [id], if it exists.
  Future<Account?> account(String id) async {
    final row =
        await (_db.select(_db.accounts)
              ..where((row) => row.id.equals(id) & row.deletedAt.isNull()))
            .getSingleOrNull();
    return row == null ? null : _accountOf(row);
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

  /// The accounts in their order with what each one holds, without archived
  /// ones unless asked. One query gives both, so a list never shows an account
  /// with a balance from before its last change.
  Stream<List<AccountBalance>> watchAccountBalances({
    bool includeArchived = false,
  }) {
    return _db
        .customSelect(
          '''
          SELECT a.*, $_balance AS balance
          FROM accounts a
          WHERE a.deleted_at IS NULL AND (? OR NOT a.archived)
          ORDER BY a.sort_order, a.name
          ''',
          variables: [
            Variable.withString(TransactionStatus.planned.name),
            Variable.withBool(includeArchived),
          ],
          readsFrom: {_db.accounts, _db.entries, _db.transactions},
        )
        .watch()
        .asyncMap(
          (rows) => Future.wait(
            rows.map((row) async {
              final account = _accountOf(await _db.accounts.mapFromRow(row));
              return AccountBalance(
                account,
                Money(row.read<int>('balance'), account.currency),
              );
            }),
          ),
        );
  }

  /// The balance of an account: the opening balance plus every entry that is
  /// not planned. It is computed each time and stored nowhere.
  Stream<Money> watchBalance(String accountId) {
    return _db
        .customSelect(
          '''
          SELECT a.currency, a.decimal_digits, $_balance AS balance
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

  /// Runs [writes] as one write. Readers see all of it or none of it, and a
  /// failure undoes it all.
  Future<T> atomically<T>(Future<T> Function() writes) =>
      _db.transaction(writes);

  /// Adds a category, after the others of its [kind]. A subcategory has a
  /// parent of the same kind, which is not a subcategory itself.
  Future<Category> addCategory({
    required CategoryKind kind,
    required String name,
    String? parentId,
    String? icon,
    String? color,
    int? sortOrder,
  }) {
    return _db.transaction(() async {
      if (parentId != null) await _checkParent(parentId, kind);
      final id = _newId();
      final at = _timestamp();
      final last = _db.categories.sortOrder.max();
      final position =
          sortOrder ??
          await (_db.selectOnly(_db.categories)
                ..addColumns([last])
                ..where(
                  _db.categories.deletedAt.isNull() &
                      _db.categories.kind.equals(kind.name),
                ))
              .map((row) => (row.read(last) ?? -1) + 1)
              .getSingle();
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
              sortOrder: Value(position),
            ),
          );
      await _log(_db.categories, id, 'insert', at);
      return _categoryOf(row);
    });
  }

  /// Changes the given fields of a category. Its kind never changes, and a
  /// category with subcategories cannot become one itself.
  Future<void> updateCategory(
    String id, {
    String? name,
    Value<String?> parentId = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<String?> color = const Value.absent(),
    bool? archived,
    int? sortOrder,
  }) {
    return _db.transaction(() async {
      final at = _timestamp();
      final parent = parentId.value;
      if (parentId.present && parent != null) {
        final category = await this.category(id);
        if (category != null) {
          if (parent == id) {
            throw LedgerException(
              'Category ${category.name} is its own parent',
            );
          }
          await _checkParent(parent, category.kind);
          final children =
              await (_db.select(_db.categories)..where(
                    (row) => row.parentId.equals(id) & row.deletedAt.isNull(),
                  ))
                  .get();
          if (children.isNotEmpty) {
            throw LedgerException(
              'Category ${category.name} has subcategories',
            );
          }
        }
      }
      final updated =
          await (_db.update(
            _db.categories,
          )..where((row) => row.id.equals(id) & row.deletedAt.isNull())).write(
            CategoriesCompanion(
              updatedAt: Value(at),
              name: Value.absentIfNull(name),
              parentId: parentId,
              icon: icon,
              color: color,
              archived: Value.absentIfNull(archived),
              sortOrder: Value.absentIfNull(sortOrder),
            ),
          );
      if (updated == 0) throw LedgerException('No category $id');
      await _log(_db.categories, id, 'update', at);
    });
  }

  /// The category [id], if it exists.
  Future<Category?> category(String id) async {
    final row =
        await (_db.select(_db.categories)
              ..where((row) => row.id.equals(id) & row.deletedAt.isNull()))
            .getSingleOrNull();
    return row == null ? null : _categoryOf(row);
  }

  /// The categories of [kind] in their order, without archived ones unless
  /// asked.
  Stream<List<Category>> watchCategories(
    CategoryKind kind, {
    bool includeArchived = false,
  }) {
    final query = _db.select(_db.categories)
      ..where(
        (row) =>
            row.kind.equals(kind.name) &
            row.deletedAt.isNull() &
            (includeArchived ? const Constant(true) : row.archived.not()),
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

  /// The latest [limit] transactions, or all of them without a limit. They can
  /// be narrowed to [accountId] and to the days from [from] to [to], with both
  /// ends included.
  Stream<List<Transaction>> watchTransactions({
    String? accountId,
    CivilDate? from,
    CivilDate? to,
    int? limit = 200,
  }) {
    final query = _db.select(_db.transactions)
      ..where((row) {
        var matches = row.deletedAt.isNull();
        if (from != null) {
          matches &= row.occurredOn.isBiggerOrEqualValue(from.toString());
        }
        if (to != null) {
          matches &= row.occurredOn.isSmallerOrEqualValue(to.toString());
        }
        if (accountId == null) return matches;
        final ofAccount = _db.selectOnly(_db.entries)
          ..addColumns([_db.entries.transactionId])
          ..where(
            _db.entries.accountId.equals(accountId) &
                _db.entries.deletedAt.isNull(),
          );
        return matches & row.id.isInQuery(ofAccount);
      })
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.occurredOn, mode: OrderingMode.desc),
        // UUIDv7 ids sort by the moment of creation.
        (row) => OrderingTerm(expression: row.id, mode: OrderingMode.desc),
      ]);
    if (limit != null) query.limit(limit);
    return query.watch().asyncMap(_withLegs);
  }

  /// Transaction [id], and `null` while it does not exist.
  Stream<Transaction?> watchTransaction(String id) {
    final query = _db.select(_db.transactions)
      ..where((row) => row.id.equals(id) & row.deletedAt.isNull());
    return query.watchSingleOrNull().asyncMap(
      (row) async => row == null ? null : (await _withLegs([row])).singleOrNull,
    );
  }

  /// The first days of the months that have transactions, the latest first.
  Future<List<CivilDate>> months() async {
    final rows = await _db
        .customSelect(
          '''
          SELECT DISTINCT substr(occurred_on, 1, 7) AS month
          FROM transactions
          WHERE deleted_at IS NULL
          ORDER BY month DESC
          ''',
          readsFrom: {_db.transactions},
        )
        .get();
    return [
      for (final row in rows)
        CivilDate.parse('${row.read<String>('month')}-01'),
    ];
  }

  /// What each day since [from] changed the accounts that count towards
  /// totals, one row for each day and currency, the earliest first.
  Stream<List<DayChange>> watchDayChanges({required CivilDate from}) {
    return _db
        .customSelect(
          '''
          SELECT t.occurred_on AS day, a.currency, a.decimal_digits,
            SUM(e.amount_minor) AS change
          FROM entries e
          JOIN transactions t ON t.id = e.transaction_id
          JOIN accounts a ON a.id = e.account_id
          WHERE e.deleted_at IS NULL
            AND t.deleted_at IS NULL
            AND t.status <> ?
            AND t.occurred_on >= ?
            AND a.deleted_at IS NULL
            AND a.include_in_totals
            AND NOT a.archived
          GROUP BY t.occurred_on, a.currency, a.decimal_digits
          ORDER BY t.occurred_on
          ''',
          variables: [
            Variable.withString(TransactionStatus.planned.name),
            Variable.withString(from.toString()),
          ],
          readsFrom: {_db.entries, _db.transactions, _db.accounts},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              DayChange(
                CivilDate.parse(row.read<String>('day')),
                _sum(
                  row.read('change'),
                  row.read('currency'),
                  row.read('decimal_digits'),
                ),
              ),
          ],
        );
  }

  /// What went through the categories of [kind] from [from] to [to], with both
  /// ends included: one row for each category and currency, the biggest of each
  /// currency first. A subcategory counts towards its parent.
  Stream<List<CategoryTotal>> watchCategoryTotals(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  }) {
    return _db
        .customSelect(
          '''
          SELECT top.*, a.currency, a.decimal_digits,
            SUM(al.amount_minor) AS total
          FROM allocations al
          JOIN transactions t ON t.id = al.transaction_id
          JOIN entries e ON e.transaction_id = t.id AND e.deleted_at IS NULL
          JOIN accounts a ON a.id = e.account_id
          JOIN categories c ON c.id = al.category_id
          JOIN categories top ON top.id = COALESCE(c.parent_id, c.id)
          WHERE al.deleted_at IS NULL
            AND t.deleted_at IS NULL
            AND t.status <> ?
            AND t.occurred_on BETWEEN ? AND ?
            AND top.kind = ?
          GROUP BY top.id, a.currency, a.decimal_digits
          ORDER BY a.currency, total DESC, top.sort_order
          ''',
          variables: [
            Variable.withString(TransactionStatus.planned.name),
            Variable.withString(from.toString()),
            Variable.withString(to.toString()),
            Variable.withString(kind.name),
          ],
          readsFrom: {
            _db.allocations,
            _db.transactions,
            _db.entries,
            _db.accounts,
            _db.categories,
          },
        )
        .watch()
        .asyncMap(
          (rows) => Future.wait(
            rows.map(
              (row) async => CategoryTotal(
                _categoryOf(await _db.categories.mapFromRow(row)),
                _sum(
                  row.read('total'),
                  row.read('currency'),
                  row.read('decimal_digits'),
                ),
              ),
            ),
          ),
        );
  }

  /// A sum from SQL as money. It can pass the limit of an amount, where it
  /// stops, so that a list survives two absurd amounts.
  Money _sum(int minorUnits, String code, int decimalDigits) => Money(
    minorUnits.clamp(-Money.maxMinorUnits, Money.maxMinorUnits),
    _currency(code, decimalDigits),
  );

  /// The balance of the account `a` in SQL. Its one variable is the status
  /// that does not count.
  static const _balance = '''
    a.opening_balance_minor + COALESCE((
      SELECT SUM(e.amount_minor) FROM entries e
      JOIN transactions t ON t.id = e.transaction_id
      WHERE e.account_id = a.id
        AND e.deleted_at IS NULL
        AND t.deleted_at IS NULL
        AND t.status <> ?
    ), 0)
  ''';

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

  /// Checks that [parentId] can hold a subcategory of [kind]: categories have
  /// two levels.
  Future<void> _checkParent(String parentId, CategoryKind kind) async {
    final parent = await category(parentId);
    if (parent == null) throw LedgerException('No category $parentId');
    if (parent.kind != kind) {
      throw LedgerException('Category ${parent.name} is not for ${kind.name}');
    }
    if (parent.parentId != null) {
      throw LedgerException('Category ${parent.name} is a subcategory');
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
              // Two ids of one millisecond can come in any order, so the sign
              // puts what leaves a transfer first.
              ..orderBy([OrderingTerm(expression: _db.entries.amountMinor)]))
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
    lastDigits: row.lastDigits,
    art: AccountArt.values.byName(row.art),
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
