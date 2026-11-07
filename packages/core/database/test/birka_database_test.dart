import 'dart:io';

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late BirkaDatabase database;

  setUp(() => database = BirkaDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('creates every table of the schema', () async {
    expect(database.allTables.map((table) => table.actualTableName), [
      'imports',
      'accounts',
      'categories',
      'transactions',
      'entries',
      'allocations',
      'changes',
      'exchange_rates',
      'schedules',
      'notices',
    ]);
    // Reading from a table fails if it does not exist.
    await expectLater(database.select(database.entries).get(), completes);
    await expectLater(database.select(database.schedules).get(), completes);
    await expectLater(database.select(database.notices).get(), completes);
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

  // In a browser the storage can keep the tables of a first opening without
  // the version that drift writes after them (ADR 0015).
  test(
    'a first opening that stopped half way is finished by the next',
    () async {
      final folder = Directory.systemTemp.createTempSync('birka-database');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/birka.sqlite');
      final first = BirkaDatabase(NativeDatabase(file));
      await first.select(first.accounts).get();
      await first.customStatement('DROP INDEX entries_account');
      await first.customStatement('DROP TABLE exchange_rates');
      await first.customStatement('PRAGMA user_version = 0');
      await first.close();

      final next = BirkaDatabase(NativeDatabase(file));
      addTearDown(next.close);

      await expectLater(next.select(next.accounts).get(), completion(isEmpty));
      await expectLater(next.select(next.exchangeRates).get(), completes);
      final indexes = await next
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      expect(
        indexes.map((row) => row.read<String>('name')),
        contains('entries_account'),
      );
      final version = await next
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), next.schemaVersion);
    },
  );
}
