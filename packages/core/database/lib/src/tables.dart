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

  /// The import that created the account, which takes it away again if
  /// nothing else uses it (ADR 0021).
  TextColumn get importId => text().nullable().references(Imports, #id)();
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

  /// The import that created the category, which takes it away again if
  /// nothing else uses it (ADR 0021).
  TextColumn get importId => text().nullable().references(Imports, #id)();
}

/// What happened: an expense, an income, a transfer or an adjustment.
@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_occurred_on', columns: {#occurredOn})
@TableIndex(name: 'transactions_import', columns: {#importId})
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

  /// The import that brought the transaction (ADR 0021).
  TextColumn get importId => text().nullable().references(Imports, #id)();
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

  /// The category, or `null` while the transaction waits for one, as an
  /// imported one can (ADR 0021).
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  /// The positive amount in minor units.
  IntColumn get amountMinor => integer()();
}

/// A statement that came in at once, so that it can go out at once
/// (ADR 0021).
@DataClassName('ImportRow')
class Imports extends Table with SyncedRow {
  /// The name of the file, as the person chose it.
  TextColumn get fileName => text()();

  /// The id of the known format of the file, such as `tbank`, or `null` for
  /// columns that a person named.
  TextColumn get format => text().nullable()();

  /// The day of its first operation as `YYYY-MM-DD`.
  TextColumn get firstDay => text()();

  /// The day of its last operation as `YYYY-MM-DD`.
  TextColumn get lastDay => text()();
}

/// A payment that comes again, such as the rent or a salary: a rule that
/// gives a transaction each time it comes (ADR 0023).
@DataClassName('ScheduleRow')
@TableIndex(name: 'schedules_next_on', columns: {#nextOn})
class Schedules extends Table with SyncedRow {
  /// `expense`, `income` or `transfer` of `TransactionKind` in the ledger.
  TextColumn get kind => text()();

  /// What the person calls it, which becomes the note of each transaction.
  TextColumn get name => text()();

  /// The account the money leaves, or the account an income reaches.
  TextColumn get accountId => text().references(Accounts, #id)();

  /// The account a transfer reaches.
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();

  /// The category of an expense or an income, or `null` to let each of its
  /// transactions wait in the inbox for one.
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  /// The positive amount in minor units of the currency of [accountId].
  IntColumn get amountMinor => integer()();

  /// One of the names of `ScheduleEvery` in the ledger.
  TextColumn get every => text()();

  /// The day of the month it falls on, every month or every year; a shorter
  /// month takes its last day.
  IntColumn get day => integer()();

  /// The day of the month of its advance, for a payment that comes twice a
  /// month, such as a salary: its advance on this day and the rest on [day].
  IntColumn get advanceDay => integer().nullable()();

  /// The amount of its advance in the minor units of its account, when the
  /// advance is not the same amount as the rest; `null` for halves.
  IntColumn get advanceAmountMinor => integer().nullable()();

  /// The civil date of its next time as `YYYY-MM-DD`.
  TextColumn get nextOn => text()();

  /// One of the names of `ScheduleOnDay` in the ledger.
  TextColumn get onDay => text()();

  /// One of the names of `ScheduleReminder` in the ledger.
  TextColumn get reminder => text()();

  /// How its last times were done, one of the names of `ScheduleDone` in the
  /// ledger, or `null` while none is done.
  TextColumn get lastDone => text().nullable()();

  /// The first of the times that [lastDone] did, as `YYYY-MM-DD`.
  TextColumn get lastFrom => text().nullable()();

  /// The last of the times that [lastDone] did, as `YYYY-MM-DD`.
  TextColumn get lastOn => text().nullable()();

  /// The transaction of the last of those times: the one a post gave or the
  /// one a statement brought. It names no row by a key, as it may be gone.
  TextColumn get lastTransactionId => text().nullable()();

  /// The import whose statement brought those times, which takes them back
  /// when it goes out.
  TextColumn get lastImportId => text().nullable()();

  /// When they were done.
  DateTimeColumn get lastAt => dateTime().nullable()();
}

/// What one unit of a currency cost in rubles on a day (ADR 0012). Any device
/// can fetch these again, so sync does not carry them.
@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table {
  /// The civil date as `YYYY-MM-DD`, which sorts as text.
  TextColumn get day => text()();

  /// The code of the currency.
  TextColumn get currency => text()();

  /// Rubles for one unit, as a decimal string.
  TextColumn get rubles => text()();

  @override
  Set<Column<Object>> get primaryKey => {day, currency};
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

/// What Birka told the person on this device, which the bell of the overview
/// shows (ADR 0026): a time of a regular payment that it reminded of or did
/// itself, with what became of that time, or an import of a statement. The
/// device keeps it as it keeps its settings: sync and the copies of the
/// ledger leave it out, and it lasts 90 days.
@DataClassName('NoticeRow')
@TableIndex(name: 'notices_created_at', columns: {#createdAt})
class Notices extends Table {
  /// A UUIDv7 string created on the device.
  TextColumn get id => text()();

  /// One of the names of `NoticeSource` in the ledger.
  TextColumn get source => text()();

  /// When it came: when Birka reminded of the time, did it or imported.
  DateTimeColumn get createdAt => dateTime()();

  /// When the person read it, or `null` while it is new.
  DateTimeColumn get readAt => dateTime().nullable()();

  /// The regular payment of a notice of a time. It names no row by a key, as
  /// the notices go before the ledger when the ledger is emptied.
  TextColumn get scheduleId => text().nullable()();

  /// The civil date of that time as `YYYY-MM-DD`.
  TextColumn get timeOn => text().nullable()();

  /// What the payment was called at that time.
  TextColumn get name => text().nullable()();

  /// One of the names of `TransactionKind` in the ledger: what the payment
  /// moves.
  TextColumn get kind => text().nullable()();

  /// The amount of the payment at that time, in minor units.
  IntColumn get amountMinor => integer().nullable()();

  /// The code of the currency of its account.
  TextColumn get currency => text().nullable()();

  /// The number of decimal digits of that currency.
  IntColumn get decimalDigits => integer().nullable()();

  /// Whether the time is the advance of a salary paid in halves.
  BoolColumn get advance => boolean().withDefault(const Constant(false))();

  /// Whether the payment posts itself instead of waiting for the person.
  BoolColumn get postsItself => boolean().withDefault(const Constant(false))();

  /// What became of the time, one of the names of `NoticeOutcome` in the
  /// ledger, or `null` while nothing has.
  TextColumn get outcome => text().nullable()();

  /// When it did.
  DateTimeColumn get outcomeAt => dateTime().nullable()();

  /// The next time of the payment after that, as `YYYY-MM-DD`.
  TextColumn get nextOn => text().nullable()();

  /// The import whose statement brought the time, which takes it back when
  /// the import goes out.
  TextColumn get foundBy => text().nullable()();

  /// The import of a notice of an import, by its id alone, as for
  /// [scheduleId].
  TextColumn get importId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {scheduleId, timeOn},
  ];
}
