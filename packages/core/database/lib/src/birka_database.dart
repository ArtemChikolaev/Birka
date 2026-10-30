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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
