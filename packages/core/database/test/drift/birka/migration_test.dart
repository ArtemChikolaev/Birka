@TestOn('vm')
library;

import 'package:database/src/birka_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:test/test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // Every pair of versions: the schema after the steps has to equal the
  // committed snapshot.
  const versions = GeneratedHelper.versions;
  for (final (i, from) in versions.indexed) {
    for (final to in versions.skip(i + 1)) {
      test('migrates from $from to $to', () async {
        final schema = await verifier.schemaAt(from);
        final database = BirkaDatabase(schema.newConnection());
        await verifier.migrateAndValidate(database, to);
        await database.close();
      });
    }
  }

  test('an account keeps its data and gets the default art in v2', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: BirkaDatabase.new,
      createItems: (batch, old) {
        batch.insert(
          old.accounts,
          v1.AccountsCompanion.insert(
            id: 'card',
            createdAt: '2026-10-30T12:00:00.000Z',
            updatedAt: '2026-10-30T12:00:00.000Z',
            name: 'Card',
            type: 'debit',
            currency: 'RUB',
            decimalDigits: 2,
            openingBalanceMinor: const Value(125000),
          ),
        );
      },
      validateItems: (migrated) async {
        final account = await migrated.select(migrated.accounts).getSingle();
        expect(account.name, 'Card');
        expect(account.openingBalanceMinor, 125000);
        expect(account.lastDigits, isNull);
        expect(account.art, 'emerald');
      },
    );
  });
}
