import 'package:drift/drift.dart';

/// The columns of every row that sync will carry (ADR 0009).
///
/// A row is never removed: deleting sets [deletedAt], and everything else
/// reads only rows where it is null.
mixin SyncedRow on Table {
  /// A UUIDv7 string created on the device.
  TextColumn get id => text()();

  /// When the row was created.
  DateTimeColumn get createdAt => dateTime()();

  /// When the row last changed.
  DateTimeColumn get updatedAt => dateTime()();

  /// The tombstone: when the row was deleted.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Where money lives. The currency of an account never changes.
@DataClassName('AccountRow')
class Accounts extends Table with SyncedRow {
  /// The name the user sees.
  TextColumn get name => text()();

  /// One of the names of `AccountType` in the ledger.
  TextColumn get type => text()();

  /// The code of the currency, such as `RUB`.
  TextColumn get currency => text()();

  /// The number of decimal digits of the currency.
  ///
  /// It is stored for currencies outside ISO 4217, which only the account
  /// knows.
  IntColumn get decimalDigits => integer()();

  /// The balance before the first entry, in minor units.
  IntColumn get openingBalanceMinor =>
      integer().withDefault(const Constant(0))();

  /// The last digits of the card, when the user gives them.
  TextColumn get lastDigits => text().nullable()();

  /// One of the names of `AccountArt` in the ledger.
  TextColumn get art => text().withDefault(const Constant('emerald'))();

  /// Whether the account counts towards the capital.
  BoolColumn get includeInTotals =>
      boolean().withDefault(const Constant(true))();

  /// Whether the account is hidden from everyday lists.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// The place of the account in lists.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// What money is spent on or earned from.
@DataClassName('CategoryRow')
class Categories extends Table with SyncedRow {
  /// The parent category, for subcategories.
  TextColumn get parentId => text().nullable().references(Categories, #id)();

  /// One of the names of `CategoryKind` in the ledger.
  TextColumn get kind => text()();

  /// The name the user sees.
  TextColumn get name => text()();

  /// The name of the icon.
  TextColumn get icon => text().nullable()();

  /// The color as `#rrggbb`.
  TextColumn get color => text().nullable()();

  /// Whether the category is hidden from pickers.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// The place of the category in lists.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// What happened: an expense, an income, a transfer or an adjustment.
@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_occurred_on', columns: {#occurredOn})
class Transactions extends Table with SyncedRow {
  /// One of the names of `TransactionKind` in the ledger.
  TextColumn get kind => text()();

  /// The civil date as `YYYY-MM-DD`, which sorts as text.
  TextColumn get occurredOn => text()();

  /// The moment, when it is known. Statements often give only the date.
  DateTimeColumn get occurredAt => dateTime().nullable()();

  /// The note of the user.
  TextColumn get note => text().withDefault(const Constant(''))();

  /// One of the names of `TransactionStatus` in the ledger.
  TextColumn get status => text()();

  /// One of the names of `TransactionSource` in the ledger.
  TextColumn get source => text()();
}

/// How a transaction moves money on an account.
@DataClassName('EntryRow')
@TableIndex(name: 'entries_transaction', columns: {#transactionId})
@TableIndex(name: 'entries_account', columns: {#accountId})
class Entries extends Table with SyncedRow {
  /// The transaction of the entry.
  TextColumn get transactionId => text().references(Transactions, #id)();

  /// The account the money moves on.
  TextColumn get accountId => text().references(Accounts, #id)();

  /// The signed amount in minor units of the currency of the account.
  IntColumn get amountMinor => integer()();
}

/// The part of a transaction that goes to a category.
@DataClassName('AllocationRow')
@TableIndex(name: 'allocations_transaction', columns: {#transactionId})
@TableIndex(name: 'allocations_category', columns: {#categoryId})
class Allocations extends Table with SyncedRow {
  /// The transaction of the allocation.
  TextColumn get transactionId => text().references(Transactions, #id)();

  /// The category.
  TextColumn get categoryId => text().references(Categories, #id)();

  /// The positive amount in minor units.
  IntColumn get amountMinor => integer()();
}

/// The outbox: every change of a synced row, in order, for sync later.
@DataClassName('ChangeRow')
class Changes extends Table {
  /// The order of the changes.
  IntColumn get sequence => integer().autoIncrement()();

  /// The name of the table of the row.
  TextColumn get entity => text()();

  /// The id of the row.
  TextColumn get entityId => text()();

  /// `insert`, `update` or `delete`.
  TextColumn get operation => text()();

  /// When the row changed.
  DateTimeColumn get changedAt => dateTime()();
}
