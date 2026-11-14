import 'package:database/database.dart';
import 'package:drift/drift.dart';
import 'package:ledger/src/account.dart';
import 'package:ledger/src/category.dart';
import 'package:ledger/src/civil_date.dart';
import 'package:ledger/src/ledger_copy.dart';
import 'package:ledger/src/ledger_exception.dart';
import 'package:ledger/src/ledger_ids.dart';
import 'package:ledger/src/ledger_import.dart';
import 'package:ledger/src/ledger_totals.dart';
import 'package:ledger/src/notice.dart';
import 'package:ledger/src/schedule.dart';
import 'package:ledger/src/tag.dart';
import 'package:ledger/src/transaction.dart';
import 'package:ledger/src/transaction_draft.dart';
import 'package:money/money.dart';

/// Reads and writes the ledger, and keeps the rules of ADR 0009.
///
/// Every write is one database transaction: it stamps the rows, leaves
/// tombstones instead of deleting, and records each change in the outbox.
final class LedgerRepository {
  /// Creates a repository on [_db]. Tests can fix [now], which also gives
  /// the ids their time, and [newId].
  LedgerRepository(
    this._db, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? LedgerIds(now: now).call;

  final BirkaDatabase _db;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Adds an account, after the others unless [sortOrder] says otherwise.
  /// The currency of [openingBalance] becomes the currency of the account for
  /// good.
  ///
  /// A debt needs its [debt] terms, and no other account has them. A debt
  /// never counts towards the capital: the money is not the person's now
  /// (ADR 0029).
  Future<Account> addAccount({
    required String name,
    required AccountType type,
    required Money openingBalance,
    String? lastDigits,
    AccountArt art = AccountArt.emerald,
    bool includeInTotals = true,
    int? sortOrder,
    String? importId,
    DebtTerms? debt,
  }) {
    if ((type == AccountType.debt) != (debt != null)) {
      throw LedgerException(
        type == AccountType.debt
            ? 'Debt $name needs its terms'
            : 'Account $name of type ${type.name} cannot have debt terms',
      );
    }
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
              includeInTotals: Value(includeInTotals && debt == null),
              sortOrder: Value(position),
              importId: Value(importId),
              debtSide: Value(debt?.side.name),
              debtDueOn: Value(debt?.dueOn?.toString()),
              debtReminds: Value(debt?.reminds ?? false),
            ),
          );
      await _log(_db.accounts, id, 'insert', at);
      return _accountOf(row);
    });
  }

  /// Changes the given fields of an account. The currency of
  /// [openingBalance] has to stay the currency of the account.
  ///
  /// [debt] puts new terms on a debt. A debt stays a debt and another
  /// account never becomes one, and a debt never counts towards the capital
  /// (ADR 0029).
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
    DebtTerms? debt,
  }) {
    return _db.transaction(() async {
      final at = _timestamp();
      final checks =
          openingBalance != null ||
          type != null ||
          debt != null ||
          includeInTotals != null;
      final account = checks ? await this.account(id) : null;
      if (account != null) {
        if (openingBalance != null &&
            account.currency != openingBalance.currency) {
          throw LedgerException(
            'Account ${account.name} is in ${account.currency}, not in '
            '${openingBalance.currency}',
          );
        }
        if (type != null &&
            (type == AccountType.debt) != (account.type == AccountType.debt)) {
          throw LedgerException(
            'Account ${account.name} cannot become a ${type.name}',
          );
        }
        if (debt != null && !account.isDebt) {
          throw LedgerException('Account ${account.name} is not a debt');
        }
        if ((includeInTotals ?? false) && account.isDebt) {
          throw LedgerException('Debt ${account.name} cannot count in totals');
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
              debtSide: Value.absentIfNull(debt?.side.name),
              debtDueOn: debt == null
                  ? const Value.absent()
                  : Value(debt.dueOn?.toString()),
              debtReminds: Value.absentIfNull(debt?.reminds),
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

  /// The accounts in their order, without archived ones and without debts
  /// unless asked. A debt is the money of a person between the owner and
  /// someone else, so lists and pickers of accounts leave it out (ADR 0029).
  Stream<List<Account>> watchAccounts({
    bool includeArchived = false,
    bool includeDebts = false,
  }) {
    final query = _db.select(_db.accounts)
      ..where(
        (row) =>
            row.deletedAt.isNull() &
            (includeArchived ? const Constant(true) : row.archived.not()) &
            (includeDebts
                ? const Constant(true)
                : row.type.equals(AccountType.debt.name).not()),
      )
      ..orderBy([
        (row) => OrderingTerm(expression: row.sortOrder),
        (row) => OrderingTerm(expression: row.name),
      ]);
    return query.watch().map((rows) => rows.map(_accountOf).toList());
  }

  /// The accounts in their order with what each one holds, without archived
  /// ones and without debts unless asked, as [watchAccounts]. One query gives
  /// both, so a list never shows an account with a balance from before its
  /// last change.
  Stream<List<AccountBalance>> watchAccountBalances({
    bool includeArchived = false,
    bool includeDebts = false,
  }) {
    return _db
        .customSelect(
          '''
          SELECT a.*, $_balance AS balance
          FROM accounts a
          WHERE a.deleted_at IS NULL AND (? OR NOT a.archived)
            AND (? OR a.type <> ?)
          ORDER BY a.sort_order, a.name
          ''',
          variables: [
            Variable.withString(TransactionStatus.planned.name),
            Variable.withBool(includeArchived),
            Variable.withBool(includeDebts),
            Variable.withString(AccountType.debt.name),
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
  Stream<Money> watchBalance(String accountId) =>
      _balanceQuery(accountId).watchSingle().map(_balanceOf);

  /// What account [accountId] holds now, the same as [watchBalance] says.
  /// Unlike a stream, it can be read inside [atomically].
  Future<Money> balance(String accountId) async =>
      _balanceOf(await _balanceQuery(accountId).getSingle());

  Selectable<QueryRow> _balanceQuery(String accountId) => _db.customSelect(
    '''
    SELECT a.currency, a.decimal_digits, $_balance AS balance
    FROM accounts a WHERE a.id = ?
    ''',
    variables: [
      Variable.withString(TransactionStatus.planned.name),
      Variable.withString(accountId),
    ],
    readsFrom: {_db.accounts, _db.entries, _db.transactions},
  );

  Money _balanceOf(QueryRow row) => Money(
    row.read<int>('balance'),
    _currency(row.read<String>('currency'), row.read('decimal_digits')),
  );

  /// Runs [writes] as one write. Readers see all of it or none of it, and a
  /// failure undoes it all.
  Future<T> atomically<T>(Future<T> Function() writes) =>
      _db.transaction(writes);

  /// How many accounts, categories and transactions the ledger holds, again
  /// after every change.
  Stream<LedgerCounts> watchCounts() {
    return _db
        .customSelect(
          '''
          SELECT
            (SELECT COUNT(*) FROM accounts WHERE deleted_at IS NULL)
              AS accounts,
            (SELECT COUNT(*) FROM categories WHERE deleted_at IS NULL)
              AS categories,
            (SELECT COUNT(*) FROM transactions WHERE deleted_at IS NULL)
              AS transactions
          ''',
          readsFrom: {_db.accounts, _db.categories, _db.transactions},
        )
        .watchSingle()
        .map(
          (row) => LedgerCounts(
            accounts: row.read<int>('accounts'),
            categories: row.read<int>('categories'),
            transactions: row.read<int>('transactions'),
          ),
        );
  }

  /// A copy of everything the ledger holds now, read in one go (ADR 0016).
  Future<LedgerCopy> copy() {
    return _db.transaction(() async {
      final transactions = _db.selectOnly(_db.transactions)
        ..addColumns([_db.transactions.id])
        ..where(_db.transactions.deletedAt.isNull());
      final accounts = _db.selectOnly(_db.accounts)
        ..addColumns([_db.accounts.id])
        ..where(_db.accounts.deletedAt.isNull());
      final categories = _db.selectOnly(_db.categories)
        ..addColumns([_db.categories.id])
        ..where(_db.categories.deletedAt.isNull());
      final tags = _db.selectOnly(_db.tags)
        ..addColumns([_db.tags.id])
        ..where(_db.tags.deletedAt.isNull());
      return LedgerCopy.of(
        madeAt: _timestamp(),
        importRows:
            await (_db.select(_db.imports)
                  ..where((row) => row.deletedAt.isNull())
                  ..orderBy([
                    (row) => OrderingTerm(expression: row.createdAt),
                    (row) => OrderingTerm(expression: row.id),
                  ]))
                .get(),
        accountRows:
            await (_db.select(_db.accounts)
                  ..where((row) => row.deletedAt.isNull())
                  ..orderBy([
                    (row) => OrderingTerm(expression: row.sortOrder),
                    (row) => OrderingTerm(expression: row.id),
                  ]))
                .get(),
        // Parents come first, so that a restore can write them in this order.
        categoryRows:
            await (_db.select(_db.categories)
                  ..where((row) => row.deletedAt.isNull())
                  ..orderBy([
                    (row) => OrderingTerm(expression: row.parentId.isNotNull()),
                    (row) => OrderingTerm(expression: row.kind),
                    (row) => OrderingTerm(expression: row.sortOrder),
                    (row) => OrderingTerm(expression: row.id),
                  ]))
                .get(),
        transactionRows:
            await (_db.select(_db.transactions)
                  ..where((row) => row.deletedAt.isNull())
                  ..orderBy([
                    (row) => OrderingTerm(expression: row.occurredOn),
                    (row) => OrderingTerm(expression: row.id),
                  ]))
                .get(),
        entryRows:
            await (_db.select(_db.entries)
                  ..where(
                    (row) =>
                        row.deletedAt.isNull() &
                        row.transactionId.isInQuery(transactions),
                  )
                  ..orderBy([
                    (row) => OrderingTerm(expression: row.transactionId),
                    (row) => OrderingTerm(expression: row.amountMinor),
                  ]))
                .get(),
        allocationRows:
            await (_db.select(_db.allocations)
                  ..where(
                    (row) =>
                        row.deletedAt.isNull() &
                        row.transactionId.isInQuery(transactions),
                  )
                  ..orderBy([
                    (row) => OrderingTerm(expression: row.transactionId),
                    (row) => OrderingTerm(expression: row.id),
                  ]))
                .get(),
        // Only payments whose accounts and category travel with them, so that
        // the copy restores.
        scheduleRows:
            await (_db.select(_db.schedules)
                  ..where(
                    (row) =>
                        row.deletedAt.isNull() &
                        row.accountId.isInQuery(accounts) &
                        (row.toAccountId.isNull() |
                            row.toAccountId.isInQuery(accounts)) &
                        (row.categoryId.isNull() |
                            row.categoryId.isInQuery(categories)),
                  )
                  ..orderBy([
                    (row) => OrderingTerm(expression: row.nextOn),
                    (row) => OrderingTerm(expression: row.id),
                  ]))
                .get(),
        tagRows:
            await (_db.select(_db.tags)
                  ..where((row) => row.deletedAt.isNull())
                  ..orderBy([
                    (row) => OrderingTerm(expression: row.createdAt),
                    (row) => OrderingTerm(expression: row.id),
                  ]))
                .get(),
        transactionTagRows:
            await (_db.select(_db.transactionTags)
                  ..where(
                    (row) =>
                        row.deletedAt.isNull() &
                        row.transactionId.isInQuery(transactions) &
                        row.tagId.isInQuery(tags),
                  )
                  ..orderBy([
                    (row) => OrderingTerm(expression: row.transactionId),
                    (row) => OrderingTerm(expression: row.id),
                  ]))
                .get(),
      );
    });
  }

  /// Puts [copy] in place of everything the ledger holds, in one write:
  /// readers see the old ledger or the copy, never a mix of the two. The rows
  /// keep their ids and stamps, and the outbox starts again with their
  /// inserts (ADR 0016).
  Future<void> restore(LedgerCopy copy) {
    return _db.transaction(() async {
      await _clear();
      final at = _timestamp();
      final written = <(TableInfo<Table, Object?>, Iterable<String>)>[
        (_db.imports, copy.importRows.map((row) => row.id)),
        (_db.accounts, copy.accountRows.map((row) => row.id)),
        (_db.categories, copy.categoryRows.map((row) => row.id)),
        (_db.transactions, copy.transactionRows.map((row) => row.id)),
        (_db.entries, copy.entryRows.map((row) => row.id)),
        (_db.allocations, copy.allocationRows.map((row) => row.id)),
        (_db.schedules, copy.scheduleRows.map((row) => row.id)),
        (_db.tags, copy.tagRows.map((row) => row.id)),
        (_db.transactionTags, copy.transactionTagRows.map((row) => row.id)),
      ];
      await _db.batch((batch) {
        batch
          ..insertAll(_db.imports, copy.importRows)
          ..insertAll(_db.accounts, copy.accountRows)
          ..insertAll(_db.categories, copy.categoryRows)
          ..insertAll(_db.transactions, copy.transactionRows)
          ..insertAll(_db.entries, copy.entryRows)
          ..insertAll(_db.allocations, copy.allocationRows)
          ..insertAll(_db.schedules, copy.scheduleRows)
          ..insertAll(_db.tags, copy.tagRows)
          ..insertAll(_db.transactionTags, copy.transactionTagRows)
          ..insertAll(_db.changes, [
            for (final (table, ids) in written)
              for (final id in ids)
                ChangesCompanion.insert(
                  entity: table.actualTableName,
                  entityId: id,
                  operation: 'insert',
                  changedAt: at,
                ),
          ]);
      });
    });
  }

  /// Removes everything the ledger holds, the tombstones and the outbox
  /// included, so that none of it stays on this device (ADR 0016). Exchange
  /// rates stay: they are public, and any device fetches them again.
  Future<void> wipe() => _db.transaction(_clear);

  /// Leaves the ledger empty, with the rows that point to others going first.
  /// The notices go too: they tell of the ledger that goes (ADR 0026).
  Future<void> _clear() async {
    for (final table in <TableInfo<Table, Object?>>[
      _db.notices,
      _db.transactionTags,
      _db.tags,
      _db.schedules,
      _db.allocations,
      _db.entries,
      _db.transactions,
      _db.categories,
      _db.accounts,
      _db.imports,
      _db.changes,
    ]) {
      await _db.delete(table).go();
    }
  }

  /// Adds a category, after the others of its [kind]. A subcategory has a
  /// parent of the same kind, which is not a subcategory itself.
  Future<Category> addCategory({
    required CategoryKind kind,
    required String name,
    String? parentId,
    String? icon,
    String? color,
    int? sortOrder,
    String? importId,
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
              importId: Value(importId),
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

  /// Puts [draft] into the ledger and returns its id, as a part of the import
  /// [importId] when it has one.
  Future<String> record(TransactionDraft draft, {String? importId}) {
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
              importId: Value(importId),
            ),
          );
      await _log(_db.transactions, id, 'insert', at);
      await _writeLegs(id, draft, at);
      await _tagNew(id, draft, at);
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
      await _tagChanged(id, draft, at);
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
      await _buryTags(id, at);
    });
  }

  /// Starts an import of the statement [fileName], whose operations go from
  /// [firstDay] to [lastDay], and returns its id (ADR 0021).
  ///
  /// The accounts, categories and transactions that the import brings name
  /// this id, and the whole import goes in through one [atomically], so that a
  /// closed tab or app leaves none of it.
  Future<String> addImport({
    required String fileName,
    required CivilDate firstDay,
    required CivilDate lastDay,
    String? format,
  }) {
    return _db.transaction(() async {
      final id = _newId();
      final at = _timestamp();
      await _db
          .into(_db.imports)
          .insert(
            ImportsCompanion.insert(
              id: id,
              createdAt: at,
              updatedAt: at,
              fileName: fileName,
              format: Value(format),
              firstDay: firstDay.toString(),
              lastDay: lastDay.toString(),
            ),
          );
      await _log(_db.imports, id, 'insert', at);
      await _db
          .into(_db.notices)
          .insert(
            NoticesCompanion.insert(
              id: _newId(),
              source: NoticeSource.import.name,
              createdAt: at,
              importId: Value(id),
            ),
          );
      return id;
    });
  }

  /// Takes import [id] out of the ledger in one write: its transactions become
  /// tombstones, and so do the accounts and categories it added that nothing
  /// else uses now. What the person recorded and other imports stay, an
  /// account or a category that stays no longer names the import, and a
  /// regular payment that its statement brought waits again for those times.
  Future<void> undoImport(String id) {
    return _db.transaction(() async {
      final at = _timestamp();
      final updated =
          await (_db.update(
            _db.imports,
          )..where((row) => row.id.equals(id) & row.deletedAt.isNull())).write(
            ImportsCompanion(updatedAt: Value(at), deletedAt: Value(at)),
          );
      if (updated == 0) throw LedgerException('No import $id');
      await _log(_db.imports, id, 'delete', at);
      final transactions =
          await (_db.update(_db.transactions)..where(
                (row) => row.importId.equals(id) & row.deletedAt.isNull(),
              ))
              .writeReturning(
                TransactionsCompanion(
                  updatedAt: Value(at),
                  deletedAt: Value(at),
                ),
              );
      for (final transaction in transactions) {
        await _log(_db.transactions, transaction.id, 'delete', at);
        await _buryLegs(transaction.id, at);
        await _buryTags(transaction.id, at);
      }
      // A regular payment that the statement brought waits again for the
      // times it brought (ADR 0023).
      final found =
          await (_db.select(_db.schedules)..where(
                (row) => row.lastImportId.equals(id) & row.deletedAt.isNull(),
              ))
              .get();
      for (final schedule in found) {
        await (_db.update(
          _db.schedules,
        )..where((row) => row.id.equals(schedule.id))).write(
          _withLast(
            SchedulesCompanion(
              updatedAt: Value(at),
              nextOn: Value(schedule.lastFrom ?? schedule.nextOn),
            ),
            null,
          ),
        );
        await _log(_db.schedules, schedule.id, 'update', at);
      }
      await (_db.update(
        _db.notices,
      )..where((row) => row.foundBy.equals(id))).write(
        const NoticesCompanion(
          outcome: Value(null),
          outcomeAt: Value(null),
          nextOn: Value(null),
          foundBy: Value(null),
        ),
      );
      final accounts =
          await (_db.select(_db.accounts)..where(
                (row) => row.importId.equals(id) & row.deletedAt.isNull(),
              ))
              .get();
      for (final account in accounts) {
        final used =
            await _exists(
              _db.entries,
              (row) =>
                  row.accountId.equals(account.id) & row.deletedAt.isNull(),
            ) ||
            await _exists(
              _db.schedules,
              (row) =>
                  (row.accountId.equals(account.id) |
                      row.toAccountId.equals(account.id)) &
                  row.deletedAt.isNull(),
            );
        await (_db.update(
          _db.accounts,
        )..where((row) => row.id.equals(account.id))).write(
          used
              ? AccountsCompanion(
                  updatedAt: Value(at),
                  importId: const Value(null),
                )
              : AccountsCompanion(
                  updatedAt: Value(at),
                  deletedAt: Value(at),
                ),
        );
        await _log(_db.accounts, account.id, used ? 'update' : 'delete', at);
      }
      // Subcategories go first, so that their parents can follow them.
      final categories =
          await (_db.select(_db.categories)
                ..where(
                  (row) => row.importId.equals(id) & row.deletedAt.isNull(),
                )
                ..orderBy([
                  (row) => OrderingTerm(expression: row.parentId.isNull()),
                ]))
              .get();
      for (final category in categories) {
        final used =
            await _exists(
              _db.allocations,
              (row) =>
                  row.categoryId.equals(category.id) & row.deletedAt.isNull(),
            ) ||
            await _exists(
              _db.categories,
              (row) =>
                  row.parentId.equals(category.id) & row.deletedAt.isNull(),
            ) ||
            await _exists(
              _db.schedules,
              (row) =>
                  row.categoryId.equals(category.id) & row.deletedAt.isNull(),
            );
        await (_db.update(
          _db.categories,
        )..where((row) => row.id.equals(category.id))).write(
          used
              ? CategoriesCompanion(
                  updatedAt: Value(at),
                  importId: const Value(null),
                )
              : CategoriesCompanion(
                  updatedAt: Value(at),
                  deletedAt: Value(at),
                ),
        );
        await _log(
          _db.categories,
          category.id,
          used ? 'update' : 'delete',
          at,
        );
      }
    });
  }

  /// The imports whose transactions the ledger still holds, the latest first.
  Stream<List<LedgerImport>> watchImports() {
    return _db
        .customSelect(
          '''
          SELECT i.id, i.file_name, i.format, i.first_day, i.last_day,
            i.created_at, COUNT(DISTINCT t.id) AS transactions,
            GROUP_CONCAT(DISTINCT e.account_id) AS accounts
          FROM imports i
          JOIN transactions t ON t.import_id = i.id AND t.deleted_at IS NULL
          LEFT JOIN entries e
            ON e.transaction_id = t.id AND e.deleted_at IS NULL
          WHERE i.deleted_at IS NULL
          GROUP BY i.id
          ORDER BY i.created_at DESC, i.id DESC
          ''',
          readsFrom: {_db.imports, _db.transactions, _db.entries},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              LedgerImport(
                id: row.read<String>('id'),
                fileName: row.read<String>('file_name'),
                format: row.read<String?>('format'),
                firstDay: CivilDate.parse(row.read<String>('first_day')),
                lastDay: CivilDate.parse(row.read<String>('last_day')),
                importedAt: row.read<DateTime>('created_at'),
                transactions: row.read<int>('transactions'),
                accountIds: {
                  ...?row.read<String?>('accounts')?.split(','),
                },
              ),
          ],
        );
  }

  /// Adds a regular payment that first comes on [next] and then again every
  /// [every], on [day] of the month, which is the day of [next] unless said
  /// otherwise (ADR 0023). A monthly one with [advanceDay] comes twice a
  /// month: its advance on that day and the rest on [day], each with
  /// [amount] unless the advance has [advanceAmount]. An expense or an
  /// income without [categoryId] gives transactions that wait in the inbox
  /// for one; a transfer goes to [toAccountId] in the same currency.
  ///
  /// A payment [madeFrom] a transaction takes it as its time on its day, done
  /// before [next], so that no time asks for it again, and keeps its id, so
  /// that the transaction leads to the payment after later times too (ADR
  /// 0023, point 22).
  Future<Schedule> addSchedule({
    required TransactionKind kind,
    required String name,
    required String accountId,
    required Money amount,
    required ScheduleEvery every,
    required CivilDate next,
    int? day,
    int? advanceDay,
    Money? advanceAmount,
    String? toAccountId,
    String? categoryId,
    ScheduleOnDay onDay = ScheduleOnDay.ask,
    ScheduleReminder reminder = ScheduleReminder.onDay,
    String? madeFrom,
  }) {
    return _db.transaction(() async {
      final schedule = Schedule(
        id: _newId(),
        kind: kind,
        name: name,
        accountId: accountId,
        toAccountId: toAccountId,
        categoryId: categoryId,
        amount: amount,
        every: every,
        day: day ?? next.day,
        advanceDay: advanceDay,
        advanceAmount: advanceAmount,
        next: next,
        onDay: onDay,
        reminder: reminder,
        madeFrom: madeFrom,
      );
      await _checkSchedule(schedule);
      final at = _timestamp();
      final last = madeFrom == null
          ? null
          : await _madeFrom(madeFrom, next: next, at: at);
      final values = SchedulesCompanion.insert(
        id: schedule.id,
        createdAt: at,
        updatedAt: at,
        kind: kind.name,
        name: name,
        accountId: accountId,
        toAccountId: Value(toAccountId),
        categoryId: Value(categoryId),
        amountMinor: amount.minorUnits,
        every: every.name,
        day: schedule.day,
        advanceDay: Value(advanceDay),
        advanceAmountMinor: Value(advanceAmount?.minorUnits),
        madeFrom: Value(madeFrom),
        nextOn: next.toString(),
        onDay: onDay.name,
        reminder: reminder.name,
      );
      await _db
          .into(_db.schedules)
          .insert(last == null ? values : _withLast(values, last));
      await _log(_db.schedules, schedule.id, 'insert', at);
      return last == null ? schedule : schedule.movedTo(next, last: last);
    });
  }

  /// The time that transaction [id] was of a payment made from it, posted at
  /// [at]: its day, which has to come before the [next] time of the payment.
  Future<ScheduleLast> _madeFrom(
    String id, {
    required CivilDate next,
    required DateTime at,
  }) async {
    final row =
        await (_db.select(_db.transactions)
              ..where((row) => row.id.equals(id) & row.deletedAt.isNull()))
            .getSingleOrNull();
    if (row == null) {
      throw LedgerException('No transaction $id to make a payment of');
    }
    final day = CivilDate.parse(row.occurredOn);
    if (day.compareTo(next) >= 0) {
      throw const LedgerException(
        'A payment made from a transaction comes after it',
      );
    }
    return ScheduleLast(
      done: ScheduleDone.posted,
      from: day,
      on: day,
      at: at,
      transactionId: id,
    );
  }

  /// Puts [schedule] in place of the regular payment with its id. The
  /// transactions that the payment gave before stay as they are, and so does
  /// what was done to its last times, unless its next time moves: what was
  /// done then no longer leads to it.
  Future<void> updateSchedule(Schedule schedule) {
    return _db.transaction(() async {
      await _checkSchedule(schedule);
      final before = await this.schedule(schedule.id);
      final at = _timestamp();
      final values = SchedulesCompanion(
        updatedAt: Value(at),
        kind: Value(schedule.kind.name),
        name: Value(schedule.name),
        accountId: Value(schedule.accountId),
        toAccountId: Value(schedule.toAccountId),
        categoryId: Value(schedule.categoryId),
        amountMinor: Value(schedule.amount.minorUnits),
        every: Value(schedule.every.name),
        day: Value(schedule.day),
        advanceDay: Value(schedule.advanceDay),
        advanceAmountMinor: Value(schedule.advanceAmount?.minorUnits),
        nextOn: Value(schedule.next.toString()),
        onDay: Value(schedule.onDay.name),
        reminder: Value(schedule.reminder.name),
      );
      final updated =
          await (_db.update(_db.schedules)..where(
                (row) => row.id.equals(schedule.id) & row.deletedAt.isNull(),
              ))
              .write(
                before != null && before.next != schedule.next
                    ? _withLast(values, null)
                    : values,
              );
      if (updated == 0) throw LedgerException('No schedule ${schedule.id}');
      await _log(_db.schedules, schedule.id, 'update', at);
      if (before != null && before.next != schedule.next) {
        await _dropOpenNotices(schedule.id);
      }
    });
  }

  /// Deletes regular payment [id]. The transactions it gave stay.
  Future<void> deleteSchedule(String id) {
    return _db.transaction(() async {
      final at = _timestamp();
      final updated =
          await (_db.update(
            _db.schedules,
          )..where((row) => row.id.equals(id) & row.deletedAt.isNull())).write(
            SchedulesCompanion(updatedAt: Value(at), deletedAt: Value(at)),
          );
      if (updated == 0) throw LedgerException('No schedule $id');
      await _log(_db.schedules, id, 'delete', at);
      await _dropOpenNotices(id);
    });
  }

  /// Regular payment [id], if it exists.
  Future<Schedule?> schedule(String id) async {
    final rows = await (_schedulesQuery()..where(_db.schedules.id.equals(id)))
        .get();
    return rows.map(_scheduleOf).singleOrNull;
  }

  /// The regular payments, the nearest first, again after every change.
  Stream<List<Schedule>> watchSchedules() => _schedulesQuery().watch().map(
    (rows) => rows.map(_scheduleOf).toList(),
  );

  /// Records the next time of regular payment [id] as a transaction of its
  /// own and moves the payment on to its time after that, in one write, and
  /// returns the id of the transaction. The transaction falls on that time
  /// unless [on] says otherwise, and takes the amount of the payment unless
  /// [amount] says otherwise, as for a bill that changes from month to month.
  Future<String> postSchedule(String id, {Money? amount, CivilDate? on}) {
    return _db.transaction(() async {
      final schedule = await _scheduleOrThrow(id);
      final transactionId = await record(
        _draftOf(
          schedule,
          amount ?? schedule.amountOn(schedule.next),
          on ?? schedule.next,
        ),
      );
      await _done(
        schedule,
        ScheduleDone.posted,
        transactionId: transactionId,
      );
      return transactionId;
    });
  }

  /// Moves regular payment [id] on to its time after the next one with no
  /// transaction, as for a month that went without it.
  Future<void> skipSchedule(String id) {
    return _db.transaction(() async {
      final schedule = await _scheduleOrThrow(id);
      await _done(schedule, ScheduleDone.skipped);
    });
  }

  /// Marks the times of regular payment [id] from its next one through
  /// [through] as done by the statement of import [importId], whose
  /// transaction [transactionId] brought the last of them, and moves the
  /// payment on to its time after that (ADR 0023). Those times give no
  /// transactions of their own, and the payment waits for them again when
  /// the import goes out.
  Future<void> findSchedule(
    String id, {
    required CivilDate through,
    required String transactionId,
    required String importId,
  }) {
    return _db.transaction(() async {
      final schedule = await _scheduleOrThrow(id);
      if (through.compareTo(schedule.next) < 0) {
        throw LedgerException(
          'Regular payment ${schedule.name} comes next on ${schedule.next}, '
          'after $through',
        );
      }
      await _done(
        schedule,
        ScheduleDone.found,
        through: through,
        transactionId: transactionId,
        importId: importId,
      );
    });
  }

  /// Posts every time that has come by [today] of the regular payments that
  /// post themselves, the ones missed while the app was closed included, in
  /// one write, and returns the ids of the transactions. The payments that
  /// ask wait for the person.
  Future<List<String>> postDueSchedules(CivilDate today) {
    return _db.transaction(() async {
      final posted = <String>[];
      for (final row in await _schedulesQuery().get()) {
        final schedule = _scheduleOf(row);
        if (schedule.onDay != ScheduleOnDay.post) continue;
        CivilDate? through;
        String? transactionId;
        for (final time in schedule.timesUntil(today)) {
          transactionId = await record(
            _draftOf(schedule, schedule.amountOn(time), time),
          );
          posted.add(transactionId);
          through = time;
        }
        if (through != null) {
          await _done(
            schedule,
            ScheduleDone.posted,
            through: through,
            transactionId: transactionId,
            itself: true,
          );
        }
      }
      return posted;
    });
  }

  /// The notices of this device, the latest first (ADR 0026), again after
  /// every change: the times of the regular payments that Birka reminded of
  /// or posted itself, with what became of them, and the imports, with how
  /// many of their transactions the ledger holds and how many of those wait
  /// in the inbox for a category.
  Stream<List<Notice>> watchNotices() {
    return _db
        .customSelect(
          '''
          SELECT n.*, i.file_name AS import_file_name,
            i.format AS import_format, i.first_day AS import_first_day,
            i.last_day AS import_last_day,
            i.deleted_at AS import_deleted_at,
            d.debt_side AS debt_side, d.deleted_at AS debt_deleted_at,
            d.opening_balance_minor AS debt_opening,
            (SELECT COUNT(*) FROM transactions t
              WHERE t.import_id = n.import_id AND t.deleted_at IS NULL)
              AS import_transactions,
            (SELECT COUNT(DISTINCT t.id) FROM transactions t
              JOIN allocations a
                ON a.transaction_id = t.id AND a.deleted_at IS NULL
              WHERE t.import_id = n.import_id AND t.deleted_at IS NULL
                AND a.category_id IS NULL) AS import_waiting
          FROM notices n
          LEFT JOIN imports i ON i.id = n.import_id
          LEFT JOIN accounts d ON d.id = n.debt_id
          ORDER BY n.created_at DESC, n.id DESC
          ''',
          readsFrom: {
            _db.notices,
            _db.imports,
            _db.transactions,
            _db.allocations,
            _db.accounts,
            _db.entries,
          },
        )
        .watch()
        .asyncMap((rows) async {
          final legs = await _debtLegs({
            for (final row in rows) ?row.read<String?>('debt_id'),
          });
          return [for (final row in rows) ?_noticeOf(row, legs)];
        });
  }

  /// The entries of debts [ids] that are not planned, by debt, the earliest
  /// first, with the day and the note of their transfers.
  Future<Map<String, List<({CivilDate day, int minor, String note})>>>
  _debtLegs(Set<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await _db
        .customSelect(
          '''
          SELECT e.account_id, e.amount_minor, t.occurred_on, t.note
          FROM entries e
          JOIN transactions t ON t.id = e.transaction_id
          WHERE e.account_id IN (${List.filled(ids.length, '?').join(', ')})
            AND e.deleted_at IS NULL AND t.deleted_at IS NULL
            AND t.status <> ?
          ORDER BY t.occurred_on, t.id
          ''',
          variables: [
            for (final id in ids) Variable.withString(id),
            Variable.withString(TransactionStatus.planned.name),
          ],
          readsFrom: {_db.entries, _db.transactions},
        )
        .get();
    final legs = <String, List<({CivilDate day, int minor, String note})>>{};
    for (final row in rows) {
      (legs[row.read<String>('account_id')] ??= []).add((
        day: CivilDate.parse(row.read<String>('occurred_on')),
        minor: row.read<int>('amount_minor'),
        note: row.read<String>('note'),
      ));
    }
    return legs;
  }

  /// How many notices the person has not read yet, again after every change.
  Stream<int> watchNewNotices() {
    final count = _db.notices.id.count();
    return (_db.selectOnly(_db.notices)
          ..addColumns([count])
          ..where(_db.notices.readAt.isNull()))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  /// Marks notices [ids] read, or every new one when [ids] is `null`.
  Future<void> readNotices([Iterable<String>? ids]) async {
    if (ids != null && ids.isEmpty) return;
    final at = _timestamp();
    await (_db.update(_db.notices)..where(
          (row) => ids == null
              ? row.readAt.isNull()
              : row.readAt.isNull() & row.id.isIn(ids),
        ))
        .write(NoticesCompanion(readAt: Value(at)));
  }

  /// Puts into the notices each [reminders] of a time of a regular payment
  /// that came at its moment (ADR 0026): one notice for each time, which
  /// keeps the moment it came at. A time that has a notice already keeps it,
  /// and a time before the next one of its payment was done meanwhile, so it
  /// gets none, as a payment that is gone does.
  Future<void> noteReminders(
    Iterable<({String scheduleId, CivilDate time, DateTime at})> reminders,
  ) {
    return _db.transaction(() async {
      final schedules = <String, Schedule?>{};
      for (final reminder in reminders) {
        final id = reminder.scheduleId;
        if (!schedules.containsKey(id)) schedules[id] = await schedule(id);
        final payment = schedules[id];
        if (payment == null || reminder.time.compareTo(payment.next) < 0) {
          continue;
        }
        await _db
            .into(_db.notices)
            .insert(
              _noticeOfTime(payment, reminder.time, reminder.at.toUtc()),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  /// Puts into the notices each of [days] of a debt that came at its moment
  /// (ADR 0029): one notice for each day of a debt, which keeps the moment it
  /// came at, the name of the person and what was owed then. A day that has
  /// a notice already keeps it, and a debt that is gone, owes nothing now, or
  /// keeps another day or no reminder of it gets none.
  Future<void> noteDebtDays(
    Iterable<({String debtId, CivilDate due, DateTime at})> days,
  ) {
    return _db.transaction(() async {
      for (final day in days) {
        final debt = await account(day.debtId);
        final terms = debt?.debt;
        if (debt == null ||
            terms == null ||
            !terms.reminds ||
            terms.dueOn != day.due) {
          continue;
        }
        final sign = terms.side == DebtSide.lent ? 1 : -1;
        final owed = (await balance(debt.id)).minorUnits * sign;
        if (owed <= 0) continue;
        await _db
            .into(_db.notices)
            .insert(
              NoticesCompanion.insert(
                id: _newId(),
                source: NoticeSource.debt.name,
                createdAt: day.at.toUtc(),
                debtId: Value(debt.id),
                timeOn: Value(day.due.toString()),
                name: Value(debt.name),
                amountMinor: Value(owed),
                currency: Value(debt.currency.code),
                decimalDigits: Value(debt.currency.decimalDigits),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  /// Marks read the notices of debt [debtId] that are new, as when the
  /// person settled it: what they did is no news to them.
  Future<void> readDebtNotices(String debtId) async {
    await (_db.update(_db.notices)..where(
          (row) => row.debtId.equals(debtId) & row.readAt.isNull(),
        ))
        .write(NoticesCompanion(readAt: Value(_timestamp())));
  }

  /// Forgets the notices that came before [before], read or not, and says
  /// how many it forgot.
  Future<int> forgetNotices({required DateTime before}) => (_db.delete(
    _db.notices,
  )..where((row) => row.createdAt.isSmallerThanValue(before.toUtc()))).go();

  /// The regular payments that exist, with their accounts for the currency,
  /// the nearest first.
  JoinedSelectStatement<HasResultSet, dynamic> _schedulesQuery() =>
      _db.select(_db.schedules).join([
          innerJoin(
            _db.accounts,
            _db.accounts.id.equalsExp(_db.schedules.accountId),
          ),
        ])
        ..where(
          _db.schedules.deletedAt.isNull() & _db.accounts.deletedAt.isNull(),
        )
        ..orderBy([
          OrderingTerm(expression: _db.schedules.nextOn),
          OrderingTerm(expression: _db.schedules.name),
          OrderingTerm(expression: _db.schedules.id),
        ]);

  Future<Schedule> _scheduleOrThrow(String id) async =>
      await schedule(id) ?? (throw LedgerException('No schedule $id'));

  /// Records that the times of [schedule] from its next one through
  /// [through], the next one unless said otherwise, were done as [done], by
  /// Birka [itself] or by the person, and moves it on to its time after them.
  Future<void> _done(
    Schedule schedule,
    ScheduleDone done, {
    CivilDate? through,
    String? transactionId,
    String? importId,
    bool itself = false,
  }) async {
    final at = _timestamp();
    final on = through ?? schedule.next;
    await (_db.update(
      _db.schedules,
    )..where((row) => row.id.equals(schedule.id))).write(
      _withLast(
        SchedulesCompanion(
          updatedAt: Value(at),
          nextOn: Value(schedule.after(on).toString()),
        ),
        ScheduleLast(
          done: done,
          from: schedule.next,
          on: on,
          at: at,
          transactionId: transactionId,
          importId: importId,
        ),
      ),
    );
    await _log(_db.schedules, schedule.id, 'update', at);
    await _noteDone(
      schedule,
      done,
      on: on,
      at: at,
      importId: importId,
      itself: itself,
    );
  }

  /// [values] that also say what was done to the last times of a schedule,
  /// or that nothing was.
  SchedulesCompanion _withLast(SchedulesCompanion values, ScheduleLast? last) =>
      values.copyWith(
        lastDone: Value(last?.done.name),
        lastFrom: Value(last?.from.toString()),
        lastOn: Value(last?.on.toString()),
        lastTransactionId: Value(last?.transactionId),
        lastImportId: Value(last?.importId),
        lastAt: Value(last?.at),
      );

  /// Tells the notices of the times of [schedule] from its next one through
  /// [on] that they were [done] at [at] (ADR 0026). A time that Birka posted
  /// [itself] gets a notice when it has none, since nothing else told the
  /// person of it; what the person did, and what the statement of import
  /// [importId] brought, changes only the notices that are there. What the
  /// person did is no news to them, so its notices are read.
  Future<void> _noteDone(
    Schedule schedule,
    ScheduleDone done, {
    required CivilDate on,
    required DateTime at,
    String? importId,
    bool itself = false,
  }) async {
    final outcome = switch (done) {
      ScheduleDone.posted when itself => NoticeOutcome.postedItself,
      ScheduleDone.posted => NoticeOutcome.posted,
      ScheduleDone.skipped => NoticeOutcome.skipped,
      ScheduleDone.found => NoticeOutcome.found,
    };
    final values = NoticesCompanion(
      outcome: Value(outcome.name),
      outcomeAt: Value(at),
      nextOn: Value(schedule.after(on).toString()),
      foundBy: Value(importId),
    );
    final byPerson = done != ScheduleDone.found && !itself;
    for (final time in schedule.timesUntil(on)) {
      Expression<bool> ofTime($NoticesTable row) =>
          row.scheduleId.equals(schedule.id) &
          row.timeOn.equals(time.toString());
      final updated = await (_db.update(
        _db.notices,
      )..where(ofTime)).write(values);
      if (byPerson) {
        await (_db.update(_db.notices)
              ..where((row) => ofTime(row) & row.readAt.isNull()))
            .write(NoticesCompanion(readAt: Value(at)));
      }
      if (updated == 0 && itself) {
        await _db
            .into(_db.notices)
            .insert(
              _noticeOfTime(
                schedule,
                time,
                at,
              ).copyWith(
                outcome: values.outcome,
                outcomeAt: values.outcomeAt,
                nextOn: values.nextOn,
              ),
            );
      }
    }
  }

  /// A new notice of [time] of [schedule] that came at [at], with the name and
  /// the amount the payment has now.
  NoticesCompanion _noticeOfTime(
    Schedule schedule,
    CivilDate time,
    DateTime at,
  ) => NoticesCompanion.insert(
    id: _newId(),
    source: NoticeSource.payment.name,
    createdAt: at,
    scheduleId: Value(schedule.id),
    timeOn: Value(time.toString()),
    name: Value(schedule.name),
    kind: Value(schedule.kind.name),
    amountMinor: Value(schedule.amountOn(time).minorUnits),
    currency: Value(schedule.amount.currency.code),
    decimalDigits: Value(schedule.amount.currency.decimalDigits),
    advance: Value(schedule.isAdvance(time)),
    postsItself: Value(schedule.onDay == ScheduleOnDay.post),
  );

  /// Forgets the notices of regular payment [scheduleId] that still wait for
  /// what becomes of their times, as their times no longer stand.
  Future<void> _dropOpenNotices(String scheduleId) =>
      (_db.delete(_db.notices)..where(
            (row) => row.scheduleId.equals(scheduleId) & row.outcome.isNull(),
          ))
          .go();

  /// The notice of [row] of [watchNotices], with the [legs] of its debt, or
  /// `null` for one that this version cannot read, such as of a source that
  /// a newer one added.
  Notice? _noticeOf(
    QueryRow row,
    Map<String, List<({CivilDate day, int minor, String note})>> legs,
  ) {
    final notice = _db.notices.map(row.data);
    switch (NoticeSource.values.asNameMap()[notice.source]) {
      case NoticeSource.payment:
        final NoticeRow(
          :scheduleId,
          :timeOn,
          :name,
          :kind,
          :amountMinor,
          :currency,
          :decimalDigits,
        ) = notice;
        if (scheduleId == null ||
            timeOn == null ||
            name == null ||
            kind == null ||
            amountMinor == null ||
            currency == null ||
            decimalDigits == null) {
          return null;
        }
        return PaymentNotice(
          id: notice.id,
          at: notice.createdAt,
          readAt: notice.readAt,
          scheduleId: scheduleId,
          time: CivilDate.parse(timeOn),
          name: name,
          kind: TransactionKind.values.byName(kind),
          amount: Money(amountMinor, _currency(currency, decimalDigits)),
          advance: notice.advance,
          postsItself: notice.postsItself,
          outcome: switch (notice.outcome) {
            final outcome? => NoticeOutcome.values.asNameMap()[outcome],
            null => null,
          },
          outcomeAt: notice.outcomeAt,
          next: switch (notice.nextOn) {
            final next? => CivilDate.parse(next),
            null => null,
          },
        );
      case NoticeSource.debt:
        final NoticeRow(
          :debtId,
          :timeOn,
          :name,
          :amountMinor,
          :currency,
          :decimalDigits,
        ) = notice;
        if (debtId == null ||
            timeOn == null ||
            name == null ||
            amountMinor == null ||
            currency == null ||
            decimalDigits == null) {
          return null;
        }
        final money = _currency(currency, decimalDigits);
        final due = CivilDate.parse(timeOn);
        final sideName = row.read<String?>('debt_side');
        final side = DebtSide.values.asNameMap()[sideName];
        final gone = row.read<DateTime?>('debt_deleted_at') != null;
        // A debt that the ledger no longer has, or deleted, has no rounds.
        final round = side == null || gone
            ? null
            : _roundOf(
                due,
                opening: row.read<int>('debt_opening'),
                sign: side == DebtSide.lent ? 1 : -1,
                legs: legs[debtId] ?? const [],
              );
        return DebtNotice(
          id: notice.id,
          at: notice.createdAt,
          readAt: notice.readAt,
          debtId: debtId,
          name: name,
          side: side ?? DebtSide.lent,
          due: due,
          owed: Money(amountMinor, money),
          left: switch (round?.left) {
            final left? when left > 0 => Money(left, money),
            _ => null,
          },
          since: round?.since,
          note: round?.note ?? '',
          settledOn: round?.settledOn,
          gone: round == null,
        );
      case NoticeSource.import:
        final fileName = row.read<String?>('import_file_name');
        final importId = notice.importId;
        if (fileName == null || importId == null) return null;
        return ImportNotice(
          id: notice.id,
          at: notice.createdAt,
          readAt: notice.readAt,
          importId: importId,
          fileName: fileName,
          format: row.read<String?>('import_format'),
          firstDay: CivilDate.parse(row.read<String>('import_first_day')),
          lastDay: CivilDate.parse(row.read<String>('import_last_day')),
          transactions: row.read<int>('import_transactions'),
          waiting: row.read<int>('import_waiting'),
          undone: row.read<DateTime?>('import_deleted_at') != null,
        );
      case null:
        return null;
    }
  }

  /// The round of a debt that [due] falls in (ADR 0029): the latest one that
  /// started by that day, from the [opening] balance of the debt and its
  /// [legs] in order, where [sign] turns what the debt holds into what is
  /// owed. It gives the day the round started, unknown for an opening
  /// balance, the note that started it, the day it came back to nought and
  /// what is owed while it is open, or `null` when no round started by then.
  static ({CivilDate? since, String note, CivilDate? settledOn, int left})?
  _roundOf(
    CivilDate due, {
    required int opening,
    required int sign,
    required List<({CivilDate day, int minor, String note})> legs,
  }) {
    var owed = opening * sign;
    var found = owed > 0;
    CivilDate? since;
    var note = '';
    CivilDate? settledOn;
    for (final leg in legs) {
      final before = owed;
      owed += leg.minor * sign;
      if (before <= 0 && owed > 0) {
        // A round that starts after the day leaves the one it falls in.
        if (leg.day.compareTo(due) > 0) break;
        (found, since, note, settledOn) = (true, leg.day, leg.note, null);
      } else if (before > 0 && owed <= 0 && found) {
        settledOn = leg.day;
      }
    }
    if (!found) return null;
    return (
      since: since,
      note: note,
      settledOn: settledOn,
      left: settledOn == null ? owed : 0,
    );
  }

  /// The transaction that regular payment [schedule] gives on [on].
  TransactionDraft _draftOf(Schedule schedule, Money amount, CivilDate on) {
    final allocations = [
      Allocation(categoryId: schedule.categoryId, amount: amount),
    ];
    return switch (schedule.kind) {
      TransactionKind.expense => TransactionDraft.expense(
        accountId: schedule.accountId,
        allocations: allocations,
        occurredOn: on,
        note: schedule.name,
        source: TransactionSource.recurring,
      ),
      TransactionKind.income => TransactionDraft.income(
        accountId: schedule.accountId,
        allocations: allocations,
        occurredOn: on,
        note: schedule.name,
        source: TransactionSource.recurring,
      ),
      TransactionKind.transfer => TransactionDraft.transfer(
        fromAccountId: schedule.accountId,
        sent: amount,
        toAccountId: schedule.toAccountId!,
        received: amount,
        occurredOn: on,
        note: schedule.name,
        source: TransactionSource.recurring,
      ),
      TransactionKind.adjustment => throw const LedgerException(
        'A regular payment cannot adjust a balance',
      ),
    };
  }

  /// Checks that [schedule] can give its transactions: its accounts and its
  /// category exist and fit it.
  Future<void> _checkSchedule(Schedule schedule) async {
    if (schedule.name.trim().isEmpty) {
      throw const LedgerException('A regular payment needs a name');
    }
    if (!schedule.amount.isPositive) {
      throw const LedgerException('A regular payment moves a positive amount');
    }
    if (schedule.day < 1 || schedule.day > 31) {
      throw LedgerException('No day ${schedule.day} in a month');
    }
    if (schedule.advanceDay case final advance?) {
      if (advance < 1 || advance > 31 || advance == schedule.day) {
        throw LedgerException(
          'No advance on day $advance besides day ${schedule.day}',
        );
      }
      if (schedule.every != ScheduleEvery.month) {
        throw const LedgerException('Only a monthly payment has an advance');
      }
    }
    if (schedule.advanceAmount case final advance?) {
      if (schedule.advanceDay == null) {
        throw const LedgerException(
          'An amount of an advance needs the day of the advance',
        );
      }
      if (!advance.isPositive) {
        throw const LedgerException('An advance moves a positive amount');
      }
      if (advance.currency != schedule.amount.currency) {
        throw LedgerException(
          'An advance in ${advance.currency} of a payment in '
          '${schedule.amount.currency}',
        );
      }
    }
    final account = await this.account(schedule.accountId);
    if (account == null) {
      throw LedgerException('No account ${schedule.accountId}');
    }
    if (account.currency != schedule.amount.currency) {
      throw LedgerException(
        'Account ${account.name} is in ${account.currency}, not in '
        '${schedule.amount.currency}',
      );
    }
    switch (schedule.kind) {
      case TransactionKind.transfer:
        final toAccountId = schedule.toAccountId;
        if (toAccountId == null || toAccountId == schedule.accountId) {
          throw const LedgerException(
            'A transfer needs two different accounts',
          );
        }
        if (schedule.categoryId != null) {
          throw const LedgerException('A transfer has no category');
        }
        final to = await this.account(toAccountId);
        if (to == null) throw LedgerException('No account $toAccountId');
        if (to.currency != account.currency) {
          throw LedgerException(
            'A regular transfer stays in ${account.currency}, not in '
            '${to.currency}',
          );
        }
      case TransactionKind.expense || TransactionKind.income:
        if (schedule.toAccountId != null) {
          throw const LedgerException(
            'Only a transfer goes to another account',
          );
        }
        final categoryId = schedule.categoryId;
        if (categoryId == null) return;
        final category = await this.category(categoryId);
        if (category == null) throw LedgerException('No category $categoryId');
        if (category.kind.name != schedule.kind.name) {
          throw LedgerException(
            'Category ${category.name} is not for ${schedule.kind.name}',
          );
        }
      case TransactionKind.adjustment:
        throw const LedgerException(
          'A regular payment cannot adjust a balance',
        );
    }
  }

  Schedule _scheduleOf(TypedResult row) {
    final schedule = row.readTable(_db.schedules);
    final account = row.readTable(_db.accounts);
    return Schedule(
      id: schedule.id,
      kind: TransactionKind.values.byName(schedule.kind),
      name: schedule.name,
      accountId: schedule.accountId,
      toAccountId: schedule.toAccountId,
      categoryId: schedule.categoryId,
      amount: Money(
        schedule.amountMinor,
        _currency(account.currency, account.decimalDigits),
      ),
      every: ScheduleEvery.values.byName(schedule.every),
      day: schedule.day,
      advanceDay: schedule.advanceDay,
      advanceAmount: switch (schedule.advanceAmountMinor) {
        final minor? => Money(
          minor,
          _currency(account.currency, account.decimalDigits),
        ),
        null => null,
      },
      madeFrom: schedule.madeFrom,
      next: CivilDate.parse(schedule.nextOn),
      onDay: ScheduleOnDay.values.byName(schedule.onDay),
      reminder: ScheduleReminder.values.byName(schedule.reminder),
      last: switch ((
        schedule.lastDone,
        schedule.lastFrom,
        schedule.lastOn,
        schedule.lastAt,
      )) {
        (final done?, final from?, final on?, final at?) => ScheduleLast(
          done: ScheduleDone.values.byName(done),
          from: CivilDate.parse(from),
          on: CivilDate.parse(on),
          at: at,
          transactionId: schedule.lastTransactionId,
          importId: schedule.lastImportId,
        ),
        _ => null,
      },
    );
  }

  /// Adds a метка (ADR 0027). A trip that [marksDays] goes at once onto the
  /// expenses that its [days] already have, and the result says how many.
  Future<TagMarking> addTag({
    required String name,
    TagDays? days,
    bool marksDays = false,
  }) {
    return _db.transaction(() async {
      final tag = Tag(
        id: _newId(),
        name: _tagName(name),
        days: days,
        marksDays: marksDays && days != null,
      );
      final at = _timestamp();
      await _db
          .into(_db.tags)
          .insert(
            TagsCompanion.insert(
              id: tag.id,
              createdAt: at,
              updatedAt: at,
              name: tag.name,
              firstDay: Value(days?.first.toString()),
              lastDay: Value(days?.last.toString()),
              marksDays: Value(tag.marksDays),
            ),
          );
      await _log(_db.tags, tag.id, 'insert', at);
      return TagMarking(tag, marked: await _markDays(tag, at));
    });
  }

  /// Puts [tag] in place of the метка with its id. The expenses of its days
  /// follow: those of new days get it, and those of days it no longer has,
  /// or of a trip that stopped marking them, lose it, unless the person put
  /// it on by hand.
  Future<TagMarking> updateTag(Tag tag) {
    return _db.transaction(() async {
      final days = tag.days;
      final kept = tag.copyWith(
        name: _tagName(tag.name),
        marksDays: tag.marksDays && days != null,
      );
      final at = _timestamp();
      final updated =
          await (_db.update(_db.tags)..where(
                (row) => row.id.equals(tag.id) & row.deletedAt.isNull(),
              ))
              .write(
                TagsCompanion(
                  updatedAt: Value(at),
                  name: Value(kept.name),
                  firstDay: Value(days?.first.toString()),
                  lastDay: Value(days?.last.toString()),
                  marksDays: Value(kept.marksDays),
                  archived: Value(kept.archived),
                ),
              );
      if (updated == 0) throw LedgerException('No метка ${tag.id}');
      await _log(_db.tags, tag.id, 'update', at);
      return TagMarking(kept, marked: await _markDays(kept, at));
    });
  }

  /// Takes the days of trip [id] back off its expenses: the trip stops
  /// marking them, and only what the person put on by hand stays. This is
  /// the way back from what [addTag] or [updateTag] marked.
  Future<void> unmarkDays(String id) async {
    final tag = await this.tag(id);
    if (tag == null) throw LedgerException('No метка $id');
    await updateTag(tag.copyWith(marksDays: false));
  }

  /// Метка [id], if it exists.
  Future<Tag?> tag(String id) async {
    final row =
        await (_db.select(_db.tags)
              ..where((row) => row.id.equals(id) & row.deletedAt.isNull()))
            .getSingleOrNull();
    return row == null ? null : _tagOf(row);
  }

  /// The метки, again after every change: the trips by their first days, the
  /// latest first, then the others by name. Archived ones stay out unless
  /// [includeArchived].
  Stream<List<Tag>> watchTags({bool includeArchived = false}) {
    final query = _db.select(_db.tags)
      ..where(
        (row) =>
            row.deletedAt.isNull() &
            (includeArchived ? const Constant(true) : row.archived.not()),
      )
      ..orderBy([
        (row) => OrderingTerm(expression: row.firstDay.isNull()),
        (row) =>
            OrderingTerm(expression: row.firstDay, mode: OrderingMode.desc),
        (row) => OrderingTerm(expression: row.name),
        (row) => OrderingTerm(expression: row.id),
      ]);
    return query.watch().map((rows) => rows.map(_tagOf).toList());
  }

  /// Puts on transaction [id] exactly the метки [tagIds], as the person
  /// picked them. A trip whose days had put it on and that is not among them
  /// stays off the transaction for good.
  Future<void> setTags(String id, Iterable<String> tagIds) {
    return _db.transaction(() async {
      final row =
          await (_db.select(_db.transactions)
                ..where((row) => row.id.equals(id) & row.deletedAt.isNull()))
              .getSingleOrNull();
      if (row == null) throw LedgerException('No transaction $id');
      final at = _timestamp();
      await _pickTags(
        id,
        kind: TransactionKind.values.byName(row.kind),
        source: TransactionSource.values.byName(row.source),
        day: CivilDate.parse(row.occurredOn),
        picked: {...tagIds},
        at: at,
      );
      await _touch(id, at);
    });
  }

  /// The метки of a new transaction: those the person picked, or the trips
  /// whose days put them on.
  Future<void> _tagNew(String id, TransactionDraft draft, DateTime at) async {
    final picked = draft.tags;
    if (picked != null) {
      await _pickTags(
        id,
        kind: draft.kind,
        source: draft.source,
        day: draft.occurredOn,
        picked: picked,
        at: at,
      );
      return;
    }
    for (final tag in await _markingTrips()) {
      if (tag.marks(
        kind: draft.kind,
        source: draft.source,
        day: draft.occurredOn,
      )) {
        await _putTag(id, tag.id, TagMark.days, at);
      }
    }
  }

  /// The метки of a changed transaction: those the person picked, or what it
  /// wore, with the trips whose days put them on or take them off now.
  Future<void> _tagChanged(
    String id,
    TransactionDraft draft,
    DateTime at,
  ) async {
    final picked = draft.tags;
    if (picked != null) {
      await _pickTags(
        id,
        kind: draft.kind,
        source: draft.source,
        day: draft.occurredOn,
        picked: picked,
        at: at,
      );
      return;
    }
    final worn = await _tagRowsOf(id);
    final frozen = await _archivedOf(worn.keys);
    final trips = {for (final tag in await _markingTrips()) tag.id: tag};
    bool marks(Tag? tag) =>
        tag != null &&
        tag.marks(
          kind: draft.kind,
          source: draft.source,
          day: draft.occurredOn,
        );
    // What the days put on and no longer cover goes, unless its trip is
    // archived.
    for (final row in worn.values) {
      if (row.mark == TagMark.days.name &&
          !frozen.contains(row.tagId) &&
          !marks(trips[row.tagId])) {
        await _buryTagRow(row.id, at);
      }
    }
    // A trip whose days cover it now puts itself on, unless it was taken off.
    for (final tag in trips.values) {
      if (marks(tag) && !worn.containsKey(tag.id)) {
        await _putTag(id, tag.id, TagMark.days, at);
      }
    }
  }

  /// Makes transaction [id] wear exactly [picked]: a picked trip whose days
  /// cover it counts as put on by them, another picked метка as put on by
  /// hand, and a trip whose days cover it but that is not picked stays off.
  /// What it wears of an archived метка stays as it is, since the pickers do
  /// not show one.
  Future<void> _pickTags(
    String id, {
    required TransactionKind kind,
    required TransactionSource source,
    required CivilDate day,
    required Set<String> picked,
    required DateTime at,
  }) async {
    final worn = await _tagRowsOf(id);
    final frozen = await _archivedOf(worn.keys);
    final wanted = <String, TagMark>{};
    for (final tagId in picked) {
      if (frozen.contains(tagId)) continue;
      final tag = await this.tag(tagId);
      if (tag == null) throw LedgerException('No метка $tagId');
      wanted[tagId] = tag.marks(kind: kind, source: source, day: day)
          ? TagMark.days
          : TagMark.hand;
    }
    for (final tag in await _markingTrips()) {
      if (!wanted.containsKey(tag.id) &&
          tag.marks(kind: kind, source: source, day: day)) {
        wanted[tag.id] = TagMark.off;
      }
    }
    for (final MapEntry(key: tagId, value: mark) in wanted.entries) {
      final row = worn[tagId];
      if (row == null) {
        await _putTag(id, tagId, mark, at);
      } else if (row.mark != mark.name) {
        await (_db.update(
          _db.transactionTags,
        )..where((it) => it.id.equals(row.id))).write(
          TransactionTagsCompanion(
            updatedAt: Value(at),
            mark: Value(mark.name),
          ),
        );
        await _log(_db.transactionTags, row.id, 'update', at);
      }
    }
    for (final row in worn.values) {
      if (!wanted.containsKey(row.tagId) && !frozen.contains(row.tagId)) {
        await _buryTagRow(row.id, at);
      }
    }
  }

  /// Puts [tag] onto the expenses of its days that do not wear it yet, and
  /// takes it off those that its days put it on and no longer cover. Returns
  /// how many it was put on. An archived метка stays on what it wears and
  /// marks nothing more.
  Future<int> _markDays(Tag tag, DateTime at) async {
    if (tag.archived) return 0;
    final rows =
        await (_db.select(_db.transactionTags)..where(
              (row) => row.tagId.equals(tag.id) & row.deletedAt.isNull(),
            ))
            .get();
    final worn = {for (final row in rows) row.transactionId: row};
    final covered = <String>{};
    final days = tag.days;
    if (tag.marksDays && days != null) {
      final expenses =
          await (_db.select(_db.transactions)..where(
                (row) =>
                    row.deletedAt.isNull() &
                    row.kind.equals(TransactionKind.expense.name) &
                    row.source.equals(TransactionSource.recurring.name).not() &
                    row.occurredOn.isBiggerOrEqualValue(days.first.toString()) &
                    row.occurredOn.isSmallerOrEqualValue(days.last.toString()),
              ))
              .get();
      covered.addAll(expenses.map((row) => row.id));
    }
    var marked = 0;
    for (final id in covered) {
      if (worn.containsKey(id)) continue;
      await _putTag(id, tag.id, TagMark.days, at);
      await _touch(id, at);
      marked++;
    }
    for (final row in rows) {
      if (row.mark == TagMark.days.name &&
          !covered.contains(row.transactionId)) {
        await _buryTagRow(row.id, at);
        await _touch(row.transactionId, at);
      }
    }
    return marked;
  }

  /// The trips whose days put them on expenses by themselves.
  Future<List<Tag>> _markingTrips() async {
    final rows =
        await (_db.select(_db.tags)..where(
              (row) =>
                  row.deletedAt.isNull() &
                  row.archived.not() &
                  row.marksDays &
                  row.firstDay.isNotNull(),
            ))
            .get();
    return rows.map(_tagOf).toList();
  }

  /// Which of метки [ids] are archived: what a transaction wears of them
  /// stays as it is.
  Future<Set<String>> _archivedOf(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return const {};
    final rows = await (_db.select(
      _db.tags,
    )..where((row) => row.id.isIn(list) & row.archived)).get();
    return {for (final row in rows) row.id};
  }

  /// The links of transaction [id] to its метки, by the id of the метка.
  Future<Map<String, TransactionTagRow>> _tagRowsOf(String id) async {
    final rows =
        await (_db.select(_db.transactionTags)..where(
              (row) => row.transactionId.equals(id) & row.deletedAt.isNull(),
            ))
            .get();
    return {for (final row in rows) row.tagId: row};
  }

  Future<void> _putTag(
    String transactionId,
    String tagId,
    TagMark mark,
    DateTime at,
  ) async {
    final id = _newId();
    await _db
        .into(_db.transactionTags)
        .insert(
          TransactionTagsCompanion.insert(
            id: id,
            createdAt: at,
            updatedAt: at,
            transactionId: transactionId,
            tagId: tagId,
            mark: mark.name,
          ),
        );
    await _log(_db.transactionTags, id, 'insert', at);
  }

  Future<void> _buryTagRow(String id, DateTime at) async {
    await (_db.update(
      _db.transactionTags,
    )..where((row) => row.id.equals(id))).write(
      TransactionTagsCompanion(updatedAt: Value(at), deletedAt: Value(at)),
    );
    await _log(_db.transactionTags, id, 'delete', at);
  }

  /// Takes every метка off transaction [id], as it goes.
  Future<void> _buryTags(String id, DateTime at) async {
    final rows =
        await (_db.update(_db.transactionTags)..where(
              (row) => row.transactionId.equals(id) & row.deletedAt.isNull(),
            ))
            .writeReturning(
              TransactionTagsCompanion(
                updatedAt: Value(at),
                deletedAt: Value(at),
              ),
            );
    for (final row in rows) {
      await _log(_db.transactionTags, row.id, 'delete', at);
    }
  }

  /// Stamps transaction [id] as changed, as its метки did, so that whoever
  /// watches it reads them again.
  Future<void> _touch(String id, DateTime at) async {
    await (_db.update(_db.transactions)..where((row) => row.id.equals(id)))
        .write(TransactionsCompanion(updatedAt: Value(at)));
    await _log(_db.transactions, id, 'update', at);
  }

  String _tagName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const LedgerException('A метка needs a name');
    return trimmed;
  }

  Tag _tagOf(TagRow row) {
    final first = row.firstDay;
    final last = row.lastDay;
    return Tag(
      id: row.id,
      name: row.name,
      days: first == null || last == null
          ? null
          : TagDays(CivilDate.parse(first), CivilDate.parse(last)),
      marksDays: row.marksDays,
      archived: row.archived,
    );
  }

  /// Whether [table] has a row that [where] picks.
  Future<bool> _exists<T extends HasResultSet, R>(
    ResultSetImplementation<T, R> table,
    Expression<bool> Function(T row) where,
  ) async {
    final row =
        await (_db.select(table)
              ..where(where)
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// The latest [limit] transactions, or all of them without a limit. They can
  /// be narrowed to [accountId], to the days from [from] to [to], with both
  /// ends included, to those that wear метка [tagId], to those that wear any
  /// метка when [tagged], and to those that move a debt when [debts].
  Stream<List<Transaction>> watchTransactions({
    String? accountId,
    CivilDate? from,
    CivilDate? to,
    String? tagId,
    bool tagged = false,
    bool debts = false,
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
        if (tagId != null || tagged) {
          final links = _db.transactionTags;
          var worn =
              links.mark.equals(TagMark.off.name).not() &
              links.deletedAt.isNull();
          if (tagId != null) worn &= links.tagId.equals(tagId);
          final wearing = _db.selectOnly(links)
            ..addColumns([links.transactionId])
            ..where(worn);
          matches &= row.id.isInQuery(wearing);
        }
        if (debts) {
          final debtAccounts = _db.selectOnly(_db.accounts)
            ..addColumns([_db.accounts.id])
            ..where(_db.accounts.type.equals(AccountType.debt.name));
          final ofDebts = _db.selectOnly(_db.entries)
            ..addColumns([_db.entries.transactionId])
            ..where(
              _db.entries.accountId.isInQuery(debtAccounts) &
                  _db.entries.deletedAt.isNull(),
            );
          matches &= row.id.isInQuery(ofDebts);
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

  /// The first days of the months that have transactions, the latest first,
  /// when months start on day [start] of the calendar (ADR 0024).
  Future<List<CivilDate>> months({int start = 1}) async {
    final rows = await _db
        .customSelect(
          '''
          SELECT DISTINCT CASE
              WHEN CAST(substr(occurred_on, 9, 2) AS INTEGER) >= ?1
              THEN substr(occurred_on, 1, 7)
              ELSE substr(date(occurred_on, 'start of month', '-1 month'), 1, 7)
            END AS month
          FROM transactions
          WHERE deleted_at IS NULL
          ORDER BY month DESC
          ''',
          variables: [Variable.withInt(start)],
          readsFrom: {_db.transactions},
        )
        .get();
    final day = '$start'.padLeft(2, '0');
    return [
      for (final row in rows)
        CivilDate.parse('${row.read<String>('month')}-$day'),
    ];
  }

  /// What each day since [from] changed the accounts that count towards
  /// totals, or account [accountId] alone, one row for each day and currency,
  /// the earliest first.
  Stream<List<DayChange>> watchDayChanges({
    required CivilDate from,
    String? accountId,
  }) {
    final which = accountId == null
        ? 'a.include_in_totals AND NOT a.archived'
        : 'a.id = ?';
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
            AND $which
          GROUP BY t.occurred_on, a.currency, a.decimal_digits
          ORDER BY t.occurred_on
          ''',
          variables: [
            Variable.withString(TransactionStatus.planned.name),
            Variable.withString(from.toString()),
            if (accountId != null) Variable.withString(accountId),
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
  /// ends included: one row for each category, day and currency, the earliest
  /// first. A subcategory counts towards its parent, and what waits for a
  /// category has a row without one.
  Stream<List<CategoryDayTotal>> watchCategoryDays(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  }) {
    return _db
        .customSelect(
          '''
          SELECT top.*, t.occurred_on AS day, a.currency, a.decimal_digits,
            SUM(al.amount_minor) AS total
          FROM allocations al
          JOIN transactions t ON t.id = al.transaction_id
          JOIN entries e ON e.transaction_id = t.id AND e.deleted_at IS NULL
          JOIN accounts a ON a.id = e.account_id
          LEFT JOIN categories c ON c.id = al.category_id
          LEFT JOIN categories top ON top.id = COALESCE(c.parent_id, c.id)
          WHERE al.deleted_at IS NULL
            AND t.deleted_at IS NULL
            AND t.status <> ?
            AND t.occurred_on BETWEEN ? AND ?
            AND COALESCE(top.kind, t.kind) = ?
          GROUP BY top.id, t.occurred_on, a.currency, a.decimal_digits
          ORDER BY t.occurred_on, a.currency, top.sort_order
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
              (row) async => CategoryDayTotal(
                row.read<String?>('id') == null
                    ? null
                    : _categoryOf(await _db.categories.mapFromRow(row)),
                CivilDate.parse(row.read<String>('day')),
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

  /// The days of expenses and income on accounts in a currency other than
  /// [currency], the latest first: what a report in [currency] needs rates for.
  Future<List<CivilDate>> daysOutside(Currency currency) async {
    final rows = await _db
        .customSelect(
          '''
          SELECT DISTINCT t.occurred_on AS day
          FROM allocations al
          JOIN transactions t ON t.id = al.transaction_id
          JOIN entries e ON e.transaction_id = t.id AND e.deleted_at IS NULL
          JOIN accounts a ON a.id = e.account_id
          WHERE al.deleted_at IS NULL
            AND t.deleted_at IS NULL
            AND t.status <> ?
            AND a.currency <> ?
          ORDER BY day DESC
          ''',
          variables: [
            Variable.withString(TransactionStatus.planned.name),
            Variable.withString(currency.code),
          ],
          readsFrom: {
            _db.allocations,
            _db.transactions,
            _db.entries,
            _db.accounts,
          },
        )
        .get();
    return [for (final row in rows) CivilDate.parse(row.read<String>('day'))];
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
      final categoryId = allocation.categoryId;
      if (categoryId == null) continue;
      final category =
          await (_db.select(_db.categories)..where(
                (row) => row.id.equals(categoryId) & row.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (category == null) {
        throw LedgerException('No category $categoryId');
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
              categoryId: Value(allocation.categoryId),
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
    final tagRows =
        await (_db.select(_db.transactionTags)..where(
              (row) => row.transactionId.isIn(ids) & row.deletedAt.isNull(),
            ))
            .get();
    final tags = <String, Map<String, TagMark>>{};
    for (final row in tagRows) {
      (tags[row.transactionId] ??= {})[row.tagId] = TagMark.values.byName(
        row.mark,
      );
    }
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
          importId: row.importId,
          tags: tags[row.id] ?? const {},
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
    debt: switch (row.debtSide) {
      final side? => DebtTerms(
        side: DebtSide.values.byName(side),
        dueOn: switch (row.debtDueOn) {
          final day? => CivilDate.parse(day),
          null => null,
        },
        reminds: row.debtReminds,
      ),
      null => null,
    },
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
