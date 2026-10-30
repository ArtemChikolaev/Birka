import 'package:database/src/birka_database.steps.dart';
import 'package:database/src/tables.dart';
import 'package:drift/drift.dart';

export 'package:database/src/tables.dart';

part 'birka_database.g.dart';

/// The one local database of Birka (ADR 0009).
@DriftDatabase(
  tables: [Accounts, Categories, Transactions, Entries, Allocations, Changes],
)
class BirkaDatabase extends _$BirkaDatabase {
  /// Creates the database on a connection that the host opens.
  BirkaDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.addColumn(schema.accounts, schema.accounts.lastDigits);
        await m.addColumn(schema.accounts, schema.accounts.art);
      },
    ),
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
