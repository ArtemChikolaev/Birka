import 'package:database/src/birka_database.steps.dart';
import 'package:database/src/tables.dart';
import 'package:drift/drift.dart';

export 'package:database/src/tables.dart';

part 'birka_database.g.dart';

/// The one local database of Birka (ADR 0009).
@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Entries,
    Allocations,
    Changes,
    ExchangeRates,
    Imports,
    Schedules,
    Notices,
    Tags,
    TransactionTags,
  ],
)
class BirkaDatabase extends _$BirkaDatabase {
  /// Creates the database on a connection that the host opens.
  BirkaDatabase(super.e);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // Tables come with IF NOT EXISTS already, and indexes get it here, so that
    // a first opening that stopped half way is finished by the next (ADR 0015).
    onCreate: (m) async {
      for (final entity in allSchemaEntities) {
        if (entity is Index) {
          await customStatement(
            entity.createStatementsByDialect[SqlDialect.sqlite]!.replaceFirst(
              'CREATE INDEX ',
              'CREATE INDEX IF NOT EXISTS ',
            ),
          );
        } else {
          await m.create(entity);
        }
      }
    },
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.addColumn(schema.accounts, schema.accounts.lastDigits);
        await m.addColumn(schema.accounts, schema.accounts.art);
      },
      from2To3: (m, schema) => m.createTable(schema.exchangeRates),
      from3To4: (m, schema) async {
        await m.createTable(schema.imports);
        await m.addColumn(schema.accounts, schema.accounts.importId);
        await m.addColumn(schema.categories, schema.categories.importId);
        await m.addColumn(schema.transactions, schema.transactions.importId);
        await m.createIndex(schema.transactionsImport);
        // SQLite cannot drop NOT NULL from a column, so the table is built
        // again with its rows.
        await m.alterTable(TableMigration(schema.allocations));
      },
      from4To5: (m, schema) async {
        await m.createTable(schema.schedules);
        await m.createIndex(schema.schedulesNextOn);
      },
      from5To6: (m, schema) async {
        final schedules = schema.schedules;
        await m.addColumn(schedules, schedules.lastDone);
        await m.addColumn(schedules, schedules.lastFrom);
        await m.addColumn(schedules, schedules.lastOn);
        await m.addColumn(schedules, schedules.lastTransactionId);
        await m.addColumn(schedules, schedules.lastImportId);
        await m.addColumn(schedules, schedules.lastAt);
      },
      from6To7: (m, schema) =>
          m.addColumn(schema.schedules, schema.schedules.advanceDay),
      from7To8: (m, schema) async {
        await m.createTable(schema.notices);
        await m.createIndex(schema.noticesCreatedAt);
      },
      from8To9: (m, schema) =>
          m.addColumn(schema.schedules, schema.schedules.madeFrom),
      from9To10: (m, schema) =>
          m.addColumn(schema.schedules, schema.schedules.advanceAmountMinor),
      from10To11: (m, schema) async {
        await m.createTable(schema.tags);
        await m.createTable(schema.transactionTags);
        await m.createIndex(schema.transactionTagsTransaction);
        await m.createIndex(schema.transactionTagsTag);
      },
    ),
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
