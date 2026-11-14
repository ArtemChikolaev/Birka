import 'dart:convert';

import 'package:database/database.dart';
import 'package:ledger/src/account.dart';
import 'package:ledger/src/category.dart';
import 'package:ledger/src/civil_date.dart';
import 'package:ledger/src/schedule.dart';
import 'package:ledger/src/tag.dart';
import 'package:ledger/src/transaction.dart';
import 'package:ledger/src/transaction_draft.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// How many accounts, categories and transactions the ledger holds, archived
/// ones included and tombstones left out.
@immutable
final class LedgerCounts {
  /// Creates the counts.
  const LedgerCounts({
    required this.accounts,
    required this.categories,
    required this.transactions,
  });

  /// The accounts.
  final int accounts;

  /// The categories, subcategories included.
  final int categories;

  /// The transactions.
  final int transactions;

  /// Whether the ledger holds nothing at all.
  bool get isEmpty => accounts == 0 && categories == 0 && transactions == 0;

  @override
  bool operator ==(Object other) =>
      other is LedgerCounts &&
      other.accounts == accounts &&
      other.categories == categories &&
      other.transactions == transactions;

  @override
  int get hashCode => Object.hash(accounts, categories, transactions);
}

/// Why a file cannot become the ledger.
enum LedgerCopyProblem {
  /// It is not a copy of Birka.
  notACopy,

  /// A newer version of Birka made it, in a format this one does not know.
  newer,

  /// It is a copy, but something in it is damaged or breaks the rules of the
  /// ledger.
  damaged,
}

/// Thrown when a file is not a copy that this version can restore.
final class LedgerCopyException implements Exception {
  /// Creates an exception for [problem].
  const LedgerCopyException(this.problem, this.message);

  /// What is wrong, as people are told.
  final LedgerCopyProblem problem;

  /// What exactly is wrong.
  final String message;

  @override
  String toString() => 'LedgerCopyException(${problem.name}): $message';
}

/// Everything the ledger holds, in the form of a file (ADR 0016).
///
/// It keeps every import, account, category and transaction with its entries,
/// allocations and метки, every regular payment and every метка, with their
/// ids and stamps, so that a restored ledger is the one that was copied.
/// Tombstones stay out: what was deleted does not travel.
final class LedgerCopy {
  /// Creates a copy of rows that the ledger has read.
  @internal
  LedgerCopy.of({
    required DateTime madeAt,
    required this.importRows,
    required this.accountRows,
    required this.categoryRows,
    required this.transactionRows,
    required this.entryRows,
    required this.allocationRows,
    required this.scheduleRows,
    required this.tagRows,
    required this.transactionTagRows,
  }) : madeAt = madeAt.toUtc();

  /// Reads a copy from the text of its file.
  ///
  /// It checks everything that the ledger relies on, so that a restored copy
  /// reads like one that the app wrote itself. Throws a [LedgerCopyException]
  /// otherwise.
  factory LedgerCopy.parse(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw const LedgerCopyException(LedgerCopyProblem.notACopy, 'Not JSON');
    }
    if (json is! Map<String, Object?> || json['format'] != _format) {
      throw const LedgerCopyException(
        LedgerCopyProblem.notACopy,
        'No mark of the format',
      );
    }
    final format = json['version'];
    if (format is! int || format < 1) _damaged('No version');
    if (format > version) {
      throw LedgerCopyException(
        LedgerCopyProblem.newer,
        'Version $format is newer than $version',
      );
    }
    return _read(json);
  }

  /// The version of the format that this code writes. It reads every version
  /// up to this one: version 2 added imports and operations that wait for a
  /// category (ADR 0021), version 3 regular payments, version 4 what was done
  /// to their last times, version 5 their advances, version 6 the
  /// transactions they were made from, version 7 the amounts of advances of
  /// their own (ADR 0023), version 8 метки and trips (ADR 0027), and version
  /// 9 the terms of debts (ADR 0029).
  static const version = 9;

  static const _format = 'birka-copy';

  /// When the copy was made.
  final DateTime madeAt;

  /// The imports, for the ledger to write back.
  @internal
  final List<ImportRow> importRows;

  /// The accounts, for the ledger to write back.
  @internal
  final List<AccountRow> accountRows;

  /// The categories with the parents first, for the ledger to write back.
  @internal
  final List<CategoryRow> categoryRows;

  /// The transactions, for the ledger to write back.
  @internal
  final List<TransactionRow> transactionRows;

  /// The entries, for the ledger to write back.
  @internal
  final List<EntryRow> entryRows;

  /// The allocations, for the ledger to write back.
  @internal
  final List<AllocationRow> allocationRows;

  /// The regular payments, for the ledger to write back.
  @internal
  final List<ScheduleRow> scheduleRows;

  /// The метки, for the ledger to write back.
  @internal
  final List<TagRow> tagRows;

  /// The метки on the transactions, for the ledger to write back.
  @internal
  final List<TransactionTagRow> transactionTagRows;

  /// How much the copy holds.
  LedgerCounts get counts => LedgerCounts(
    accounts: accountRows.length,
    categories: categoryRows.length,
    transactions: transactionRows.length,
  );

  /// The text of the file: JSON, with the entries and the allocations inside
  /// their transactions.
  String encode() {
    final entries = <String, List<EntryRow>>{};
    for (final entry in entryRows) {
      (entries[entry.transactionId] ??= []).add(entry);
    }
    final allocations = <String, List<AllocationRow>>{};
    for (final allocation in allocationRows) {
      (allocations[allocation.transactionId] ??= []).add(allocation);
    }
    final marks = <String, List<TransactionTagRow>>{};
    for (final mark in transactionTagRows) {
      (marks[mark.transactionId] ??= []).add(mark);
    }
    return jsonEncode({
      'format': _format,
      'version': version,
      'madeAt': _text(madeAt),
      'imports': [
        for (final row in importRows)
          {
            ..._stamps(row.id, row.createdAt, row.updatedAt),
            'fileName': row.fileName,
            'format': row.format,
            'firstDay': row.firstDay,
            'lastDay': row.lastDay,
          },
      ],
      'accounts': [
        for (final row in accountRows)
          {
            ..._stamps(row.id, row.createdAt, row.updatedAt),
            'name': row.name,
            'type': row.type,
            'currency': row.currency,
            'decimalDigits': row.decimalDigits,
            'openingBalanceMinor': row.openingBalanceMinor,
            'lastDigits': row.lastDigits,
            'art': row.art,
            'includeInTotals': row.includeInTotals,
            'archived': row.archived,
            'sortOrder': row.sortOrder,
            'importId': row.importId,
            'debtSide': row.debtSide,
            'debtDueOn': row.debtDueOn,
            'debtReminds': row.debtReminds,
          },
      ],
      'categories': [
        for (final row in categoryRows)
          {
            ..._stamps(row.id, row.createdAt, row.updatedAt),
            'parentId': row.parentId,
            'kind': row.kind,
            'name': row.name,
            'icon': row.icon,
            'color': row.color,
            'archived': row.archived,
            'sortOrder': row.sortOrder,
            'importId': row.importId,
          },
      ],
      'transactions': [
        for (final row in transactionRows)
          {
            ..._stamps(row.id, row.createdAt, row.updatedAt),
            'kind': row.kind,
            'occurredOn': row.occurredOn,
            'occurredAt': switch (row.occurredAt) {
              final at? => _text(at),
              null => null,
            },
            'note': row.note,
            'status': row.status,
            'source': row.source,
            'importId': row.importId,
            'entries': [
              for (final entry in entries[row.id] ?? const <EntryRow>[])
                {
                  ..._stamps(entry.id, entry.createdAt, entry.updatedAt),
                  'accountId': entry.accountId,
                  'amountMinor': entry.amountMinor,
                },
            ],
            'allocations': [
              for (final allocation
                  in allocations[row.id] ?? const <AllocationRow>[])
                {
                  ..._stamps(
                    allocation.id,
                    allocation.createdAt,
                    allocation.updatedAt,
                  ),
                  'categoryId': allocation.categoryId,
                  'amountMinor': allocation.amountMinor,
                },
            ],
            'marks': [
              for (final mark in marks[row.id] ?? const <TransactionTagRow>[])
                {
                  ..._stamps(mark.id, mark.createdAt, mark.updatedAt),
                  'tagId': mark.tagId,
                  'mark': mark.mark,
                },
            ],
          },
      ],
      'tags': [
        for (final row in tagRows)
          {
            ..._stamps(row.id, row.createdAt, row.updatedAt),
            'name': row.name,
            'firstDay': row.firstDay,
            'lastDay': row.lastDay,
            'marksDays': row.marksDays,
            'archived': row.archived,
          },
      ],
      'schedules': [
        for (final row in scheduleRows)
          {
            ..._stamps(row.id, row.createdAt, row.updatedAt),
            'kind': row.kind,
            'name': row.name,
            'accountId': row.accountId,
            'toAccountId': row.toAccountId,
            'categoryId': row.categoryId,
            'amountMinor': row.amountMinor,
            'every': row.every,
            'day': row.day,
            'advanceDay': row.advanceDay,
            'advanceAmountMinor': row.advanceAmountMinor,
            'madeFrom': row.madeFrom,
            'nextOn': row.nextOn,
            'onDay': row.onDay,
            'reminder': row.reminder,
            'lastDone': row.lastDone,
            'lastFrom': row.lastFrom,
            'lastOn': row.lastOn,
            'lastTransactionId': row.lastTransactionId,
            'lastImportId': row.lastImportId,
            'lastAt': switch (row.lastAt) {
              final at? => _text(at),
              null => null,
            },
          },
      ],
    });
  }

  static Map<String, Object?> _stamps(
    String id,
    DateTime createdAt,
    DateTime updatedAt,
  ) => {'id': id, 'createdAt': _text(createdAt), 'updatedAt': _text(updatedAt)};

  static String _text(DateTime moment) => moment.toUtc().toIso8601String();
}

/// Reads the rows of versions 1 to 9, and checks them as the ledger checks a
/// write. Version 1 has no imports, versions 1 and 2 no regular payments,
/// version 3 nothing done to their times, version 4 no advances, version 5
/// no transactions they were made from, version 6 no advances of their own,
/// versions before 8 no метки, and versions before 9 no terms of debts.
LedgerCopy _read(Map<String, Object?> json) {
  final imports = <String, ImportRow>{};
  for (final item
      in json['imports'] == null ? const [] : _list(json, 'imports')) {
    final row = _import(_object(item));
    if (imports.containsKey(row.id)) _damaged('Import ${row.id} twice');
    imports[row.id] = row;
  }
  void checkImport(String? importId, String whose) {
    if (importId != null && !imports.containsKey(importId)) {
      _damaged('$whose comes from no import $importId');
    }
  }

  final accounts = <String, AccountRow>{};
  for (final item in _list(json, 'accounts')) {
    final row = _account(_object(item));
    if (accounts.containsKey(row.id)) _damaged('Account ${row.id} twice');
    checkImport(row.importId, 'Account ${row.id}');
    accounts[row.id] = row;
  }
  final categories = <String, CategoryRow>{};
  for (final item in _list(json, 'categories')) {
    final row = _category(_object(item));
    if (categories.containsKey(row.id)) _damaged('Category ${row.id} twice');
    checkImport(row.importId, 'Category ${row.id}');
    categories[row.id] = row;
  }
  for (final category in categories.values) {
    _checkParent(category, categories);
  }
  final tags = <String, TagRow>{};
  for (final item in json['tags'] == null ? const [] : _list(json, 'tags')) {
    final row = _tag(_object(item));
    if (tags.containsKey(row.id)) _damaged('Метка ${row.id} twice');
    tags[row.id] = row;
  }
  final marks = <String, TransactionTagRow>{};
  final transactions = <String, TransactionRow>{};
  final entries = <String, EntryRow>{};
  final allocations = <String, AllocationRow>{};
  for (final item in _list(json, 'transactions')) {
    final object = _object(item);
    final row = _transaction(object);
    if (transactions.containsKey(row.id)) {
      _damaged('Transaction ${row.id} twice');
    }
    checkImport(row.importId, 'Transaction ${row.id}');
    transactions[row.id] = row;
    final ownEntries = [
      for (final leg in _list(object, 'entries')) _entry(_object(leg), row.id),
    ];
    final ownAllocations = [
      for (final leg in _list(object, 'allocations'))
        _allocation(_object(leg), row.id),
    ];
    _checkLegs(row, ownEntries, ownAllocations, accounts, categories);
    for (final entry in ownEntries) {
      if (entries.containsKey(entry.id)) _damaged('Entry ${entry.id} twice');
      entries[entry.id] = entry;
    }
    for (final allocation in ownAllocations) {
      if (allocations.containsKey(allocation.id)) {
        _damaged('Allocation ${allocation.id} twice');
      }
      allocations[allocation.id] = allocation;
    }
    final worn = <String>{};
    for (final item
        in object['marks'] == null ? const [] : _list(object, 'marks')) {
      final mark = _mark(_object(item), row.id);
      if (!tags.containsKey(mark.tagId)) {
        _damaged('Transaction ${row.id} wears no метка ${mark.tagId}');
      }
      if (!worn.add(mark.tagId)) {
        _damaged('Transaction ${row.id} wears ${mark.tagId} twice');
      }
      if (marks.containsKey(mark.id)) _damaged('Mark ${mark.id} twice');
      marks[mark.id] = mark;
    }
  }
  final schedules = <String, ScheduleRow>{};
  for (final item
      in json['schedules'] == null ? const [] : _list(json, 'schedules')) {
    final row = _schedule(_object(item), accounts, categories);
    if (schedules.containsKey(row.id)) _damaged('Schedule ${row.id} twice');
    schedules[row.id] = row;
  }
  return LedgerCopy.of(
    madeAt: _moment(json, 'madeAt'),
    importRows: [...imports.values],
    accountRows: [...accounts.values],
    categoryRows: [
      ...categories.values.where((row) => row.parentId == null),
      ...categories.values.where((row) => row.parentId != null),
    ],
    transactionRows: [...transactions.values],
    entryRows: [...entries.values],
    allocationRows: [...allocations.values],
    scheduleRows: [...schedules.values],
    tagRows: [...tags.values],
    transactionTagRows: [...marks.values],
  );
}

TagRow _tag(Map<String, Object?> json) {
  final id = _id(json);
  final firstDay = _field<String?>(json, 'firstDay');
  final lastDay = _field<String?>(json, 'lastDay');
  if ((firstDay == null) != (lastDay == null)) {
    _damaged('Метка $id has one end of its days');
  }
  if (firstDay != null && lastDay != null) {
    _obeying(
      'Метка $id has no days $firstDay..$lastDay',
      () => TagDays(CivilDate.parse(firstDay), CivilDate.parse(lastDay)),
    );
  }
  final name = _string(json, 'name');
  if (name.trim().isEmpty) _damaged('Метка $id has no name');
  final marksDays = _field<bool>(json, 'marksDays');
  if (marksDays && firstDay == null) _damaged('Метка $id marks no days');
  return TagRow(
    id: id,
    createdAt: _moment(json, 'createdAt'),
    updatedAt: _moment(json, 'updatedAt'),
    name: name,
    firstDay: firstDay,
    lastDay: lastDay,
    marksDays: marksDays,
    archived: _field<bool>(json, 'archived'),
  );
}

TransactionTagRow _mark(Map<String, Object?> json, String transactionId) =>
    TransactionTagRow(
      id: _id(json),
      createdAt: _moment(json, 'createdAt'),
      updatedAt: _moment(json, 'updatedAt'),
      transactionId: transactionId,
      tagId: _string(json, 'tagId'),
      mark: _name(json, 'mark', TagMark.values),
    );

AccountRow _account(Map<String, Object?> json) {
  final id = _id(json);
  final currency = _string(json, 'currency');
  final decimalDigits = _int(json, 'decimalDigits');
  final openingBalanceMinor = _int(json, 'openingBalanceMinor');
  _money(openingBalanceMinor, currency, decimalDigits, 'Account $id');
  final type = _name(json, 'type', AccountType.values);
  final debt = type == AccountType.debt.name;
  // No screen made a debt before version 9, though the type was there: such
  // an account becomes a debt that is owed to the person.
  final side = json['debtSide'] == null && debt
      ? DebtSide.lent.name
      : _field<String?>(json, 'debtSide');
  if (side != null) {
    if (!debt) _damaged('Account $id of type $type has a debt side');
    if (!DebtSide.values.any((value) => value.name == side)) {
      _damaged('debtSide $side is unknown');
    }
  }
  final dueOn = _field<String?>(json, 'debtDueOn');
  if (dueOn != null) {
    if (!debt) _damaged('Account $id of type $type has a day of a debt');
    _obeying('$dueOn is not a date', () => CivilDate.parse(dueOn));
  }
  return AccountRow(
    id: id,
    createdAt: _moment(json, 'createdAt'),
    updatedAt: _moment(json, 'updatedAt'),
    name: _string(json, 'name'),
    type: type,
    currency: currency,
    decimalDigits: decimalDigits,
    openingBalanceMinor: openingBalanceMinor,
    lastDigits: _field<String?>(json, 'lastDigits'),
    art: _name(json, 'art', AccountArt.values),
    // A debt never counts towards the capital (ADR 0029).
    includeInTotals: _field<bool>(json, 'includeInTotals') && !debt,
    archived: _field<bool>(json, 'archived'),
    sortOrder: _int(json, 'sortOrder'),
    importId: _field<String?>(json, 'importId'),
    debtSide: side,
    debtDueOn: dueOn,
    debtReminds: (_field<bool?>(json, 'debtReminds') ?? false) && debt,
  );
}

ImportRow _import(Map<String, Object?> json) {
  final firstDay = _string(json, 'firstDay');
  final lastDay = _string(json, 'lastDay');
  for (final day in [firstDay, lastDay]) {
    _obeying('$day is not a date', () => CivilDate.parse(day));
  }
  return ImportRow(
    id: _id(json),
    createdAt: _moment(json, 'createdAt'),
    updatedAt: _moment(json, 'updatedAt'),
    fileName: _string(json, 'fileName'),
    format: _field<String?>(json, 'format'),
    firstDay: firstDay,
    lastDay: lastDay,
  );
}

CategoryRow _category(Map<String, Object?> json) {
  final color = _field<String?>(json, 'color');
  if (color != null && !_color.hasMatch(color)) {
    _damaged('Color $color is not #rrggbb');
  }
  return CategoryRow(
    id: _id(json),
    createdAt: _moment(json, 'createdAt'),
    updatedAt: _moment(json, 'updatedAt'),
    parentId: _field<String?>(json, 'parentId'),
    kind: _name(json, 'kind', CategoryKind.values),
    name: _string(json, 'name'),
    icon: _field<String?>(json, 'icon'),
    color: color,
    archived: _field<bool>(json, 'archived'),
    sortOrder: _int(json, 'sortOrder'),
    importId: _field<String?>(json, 'importId'),
  );
}

final _color = RegExp(r'^#[0-9a-fA-F]{6}$');

/// Categories have two levels, and a subcategory has the kind of its parent.
void _checkParent(CategoryRow category, Map<String, CategoryRow> categories) {
  final parentId = category.parentId;
  if (parentId == null) return;
  final parent = categories[parentId];
  if (parent == null || parentId == category.id) {
    _damaged('Category ${category.id} has no parent $parentId');
  }
  if (parent.kind != category.kind || parent.parentId != null) {
    _damaged('Category ${category.id} cannot be inside $parentId');
  }
}

TransactionRow _transaction(Map<String, Object?> json) {
  final occurredOn = _string(json, 'occurredOn');
  _obeying('$occurredOn is not a date', () => CivilDate.parse(occurredOn));
  return TransactionRow(
    id: _id(json),
    createdAt: _moment(json, 'createdAt'),
    updatedAt: _moment(json, 'updatedAt'),
    kind: _name(json, 'kind', TransactionKind.values),
    occurredOn: occurredOn,
    occurredAt: json['occurredAt'] == null ? null : _moment(json, 'occurredAt'),
    note: _string(json, 'note'),
    status: _name(json, 'status', TransactionStatus.values),
    source: _name(json, 'source', TransactionSource.values),
    importId: _field<String?>(json, 'importId'),
  );
}

EntryRow _entry(Map<String, Object?> json, String transactionId) => EntryRow(
  id: _id(json),
  createdAt: _moment(json, 'createdAt'),
  updatedAt: _moment(json, 'updatedAt'),
  transactionId: transactionId,
  accountId: _string(json, 'accountId'),
  amountMinor: _int(json, 'amountMinor'),
);

AllocationRow _allocation(Map<String, Object?> json, String transactionId) =>
    AllocationRow(
      id: _id(json),
      createdAt: _moment(json, 'createdAt'),
      updatedAt: _moment(json, 'updatedAt'),
      transactionId: transactionId,
      categoryId: _field<String?>(json, 'categoryId'),
      amountMinor: _int(json, 'amountMinor'),
    );

/// Checks the entries and the allocations of [transaction] against the rules
/// of its kind (ADR 0009), which the drafts of the ledger keep.
void _checkLegs(
  TransactionRow transaction,
  List<EntryRow> entries,
  List<AllocationRow> allocations,
  Map<String, AccountRow> accounts,
  Map<String, CategoryRow> categories,
) {
  final id = transaction.id;
  final day = CivilDate.parse(transaction.occurredOn);
  Money amountOf(EntryRow entry) {
    final account =
        accounts[entry.accountId] ??
        _damaged('Transaction $id moves money on no account');
    return _money(
      entry.amountMinor,
      account.currency,
      account.decimalDigits,
      'Transaction $id',
    );
  }

  final broken = 'Transaction $id breaks the rules of its kind';
  switch (TransactionKind.values.byName(transaction.kind)) {
    case final kind && (TransactionKind.expense || TransactionKind.income):
      if (entries.length != 1) _damaged('Transaction $id has no one entry');
      final entry = entries.single;
      final amount = amountOf(entry);
      Money partOf(AllocationRow allocation) => _money(
        allocation.amountMinor,
        amount.currency.code,
        amount.currency.decimalDigits,
        'Transaction $id',
      );
      final split = [
        for (final allocation in allocations)
          if (allocation.categoryId == null)
            Allocation(categoryId: null, amount: partOf(allocation))
          else if (categories[allocation.categoryId] case final category?
              when category.kind == kind.name)
            Allocation(categoryId: category.id, amount: partOf(allocation))
          else
            _damaged('Transaction $id goes to no ${kind.name} category'),
      ];
      final total = _obeying(broken, () {
        final draft = kind == TransactionKind.expense
            ? TransactionDraft.expense(
                accountId: entry.accountId,
                allocations: split,
                occurredOn: day,
              )
            : TransactionDraft.income(
                accountId: entry.accountId,
                allocations: split,
                occurredOn: day,
              );
        return draft.entries.single.amount;
      });
      if (total != amount) {
        _damaged('The categories of transaction $id miss its amount');
      }
    case TransactionKind.transfer:
      final sent = entries.where((entry) => entry.amountMinor < 0);
      final received = entries.where((entry) => entry.amountMinor > 0);
      if (entries.length != 2 ||
          sent.length != 1 ||
          received.length != 1 ||
          allocations.isNotEmpty) {
        _damaged('Transfer $id does not move money between two accounts');
      }
      final (from, to) = (amountOf(sent.single), amountOf(received.single));
      _obeying(
        broken,
        () => TransactionDraft.transfer(
          fromAccountId: sent.single.accountId,
          sent: -from,
          toAccountId: received.single.accountId,
          received: to,
          occurredOn: day,
        ),
      );
    case TransactionKind.adjustment:
      if (entries.length != 1 || allocations.isNotEmpty) {
        _damaged('Adjustment $id is not one entry');
      }
      final change = amountOf(entries.single);
      _obeying(
        broken,
        () => TransactionDraft.adjustment(
          accountId: entries.single.accountId,
          change: change,
          occurredOn: day,
        ),
      );
  }
}

/// A regular payment, checked as the ledger checks one that it adds: its
/// accounts and its category exist and fit its kind (ADR 0023).
ScheduleRow _schedule(
  Map<String, Object?> json,
  Map<String, AccountRow> accounts,
  Map<String, CategoryRow> categories,
) {
  final id = _id(json);
  final kind = _name(json, 'kind', TransactionKind.values);
  final name = _string(json, 'name');
  if (name.trim().isEmpty) _damaged('Schedule $id has no name');
  final accountId = _string(json, 'accountId');
  final toAccountId = _field<String?>(json, 'toAccountId');
  final categoryId = _field<String?>(json, 'categoryId');
  final account =
      accounts[accountId] ?? _damaged('Schedule $id has no account $accountId');
  final amountMinor = _int(json, 'amountMinor');
  final amount = _money(
    amountMinor,
    account.currency,
    account.decimalDigits,
    'Schedule $id',
  );
  if (!amount.isPositive) _damaged('Schedule $id moves no positive amount');
  final day = _int(json, 'day');
  if (day < 1 || day > 31) _damaged('Schedule $id falls on no day $day');
  final advanceDay = _field<int?>(json, 'advanceDay');
  if (advanceDay != null &&
      (advanceDay < 1 ||
          advanceDay > 31 ||
          advanceDay == day ||
          json['every'] != ScheduleEvery.month.name)) {
    _damaged('Schedule $id has no advance on day $advanceDay');
  }
  final advanceAmountMinor = _field<int?>(json, 'advanceAmountMinor');
  if (advanceAmountMinor != null) {
    final advance = _money(
      advanceAmountMinor,
      account.currency,
      account.decimalDigits,
      'Schedule $id',
    );
    if (advanceDay == null || !advance.isPositive) {
      _damaged('Schedule $id has an advance of $advanceAmountMinor');
    }
  }
  final nextOn = _string(json, 'nextOn');
  _obeying('$nextOn is not a date', () => CivilDate.parse(nextOn));
  switch (TransactionKind.values.byName(kind)) {
    case TransactionKind.transfer:
      final to = accounts[toAccountId];
      if (to == null || toAccountId == accountId || categoryId != null) {
        _damaged('Schedule $id does not move money between two accounts');
      }
      if (to.currency != account.currency) {
        _damaged('Schedule $id moves money between currencies');
      }
    case TransactionKind.expense || TransactionKind.income:
      if (toAccountId != null) _damaged('Schedule $id goes to an account');
      if (categoryId != null && categories[categoryId]?.kind != kind) {
        _damaged('Schedule $id goes to no $kind category');
      }
    case TransactionKind.adjustment:
      _damaged('Schedule $id adjusts a balance');
  }
  final lastDone = _field<String?>(json, 'lastDone');
  final lastFrom = _field<String?>(json, 'lastFrom');
  final lastOn = _field<String?>(json, 'lastOn');
  if (lastDone == null) {
    if (lastFrom != null || lastOn != null || json['lastAt'] != null) {
      _damaged('Schedule $id has times done, but not how');
    }
  } else {
    if (!ScheduleDone.values.any((value) => value.name == lastDone)) {
      _damaged('lastDone $lastDone is unknown');
    }
    if (lastFrom == null || lastOn == null) {
      _damaged('Schedule $id was $lastDone on no times');
    }
    final from = _obeying(
      '$lastFrom is not a date',
      () => CivilDate.parse(lastFrom),
    );
    final on = _obeying('$lastOn is not a date', () => CivilDate.parse(lastOn));
    if (on.compareTo(from) < 0) {
      _damaged('Schedule $id was done from $lastFrom back to $lastOn');
    }
  }
  return ScheduleRow(
    id: id,
    createdAt: _moment(json, 'createdAt'),
    updatedAt: _moment(json, 'updatedAt'),
    kind: kind,
    name: name,
    accountId: accountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    amountMinor: amountMinor,
    every: _name(json, 'every', ScheduleEvery.values),
    day: day,
    advanceDay: advanceDay,
    advanceAmountMinor: advanceAmountMinor,
    nextOn: nextOn,
    onDay: _name(json, 'onDay', ScheduleOnDay.values),
    reminder: _name(json, 'reminder', ScheduleReminder.values),
    lastDone: lastDone,
    lastFrom: lastFrom,
    lastOn: lastOn,
    lastTransactionId: _field<String?>(json, 'lastTransactionId'),
    lastImportId: _field<String?>(json, 'lastImportId'),
    lastAt: lastDone == null ? null : _moment(json, 'lastAt'),
    madeFrom: _field<String?>(json, 'madeFrom'),
  );
}

/// Money as the ledger would read it, with the currency of an account.
Money _money(int minorUnits, String code, int decimalDigits, String whose) =>
    _obeying(
      '$whose has no amount in $code',
      () => Money(
        minorUnits,
        Currency.custom(code, decimalDigits: decimalDigits),
      ),
    );

/// Runs [rules], which throw when a rule of the ledger breaks, and says
/// [broken] when one does.
T _obeying<T>(String broken, T Function() rules) {
  try {
    return rules();
  } on Object {
    _damaged(broken);
  }
}

Never _damaged(String message) =>
    throw LedgerCopyException(LedgerCopyProblem.damaged, message);

T _field<T>(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is T) return value;
  _damaged('$key is not $T');
}

String _string(Map<String, Object?> json, String key) =>
    _field<String>(json, key);

int _int(Map<String, Object?> json, String key) => _field<int>(json, key);

String _id(Map<String, Object?> json) {
  final id = _string(json, 'id');
  if (id.isEmpty) _damaged('An empty id');
  return id;
}

DateTime _moment(Map<String, Object?> json, String key) =>
    DateTime.tryParse(_string(json, key))?.toUtc() ??
    _damaged('$key is not a moment');

/// The name in [key], which has to be one of [values].
String _name(Map<String, Object?> json, String key, List<Enum> values) {
  final name = _string(json, key);
  if (!values.any((value) => value.name == name)) {
    _damaged('$key $name is unknown');
  }
  return name;
}

List<Object?> _list(Map<String, Object?> json, String key) =>
    _field<List<Object?>>(json, key);

Map<String, Object?> _object(Object? item) =>
    item is Map<String, Object?> ? item : _damaged('Not an object');
