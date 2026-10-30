import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late BirkaDatabase database;

  setUp(() => database = BirkaDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('creates every table of the schema', () async {
    expect(database.allTables.map((table) => table.actualTableName), [
      'accounts',
      'categories',
      'transactions',
      'entries',
      'allocations',
      'changes',
    ]);
    // Reading from a table fails if it does not exist.
    await expectLater(database.select(database.entries).get(), completes);
  });

  test('foreign keys are on', () async {
    final at = DateTime.utc(2026, 10, 30);

    await expectLater(
      database
          .into(database.entries)
          .insert(
            EntriesCompanion.insert(
              id: 'entry',
              createdAt: at,
              updatedAt: at,
              transactionId: 'no such transaction',
              accountId: 'no such account',
              amountMinor: 100,
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('dates survive with their milliseconds, in UTC', () async {
    final at = DateTime.utc(2026, 10, 30, 12, 30, 15, 123);
    await database
        .into(database.changes)
        .insert(
          ChangesCompanion.insert(
            entity: 'accounts',
            entityId: 'id',
            operation: 'insert',
            changedAt: at,
          ),
        );

    final change = await database.select(database.changes).getSingle();
    expect(change.changedAt, at);
    expect(change.sequence, 1);
  });
}
