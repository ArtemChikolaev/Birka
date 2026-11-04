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
  ],
)
class BirkaDatabase extends _$BirkaDatabase {
  /// Creates the database on a connection that the host opens.
  BirkaDatabase(super.e);

  @override
  int get schemaVersion => 4;

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
    ),
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
