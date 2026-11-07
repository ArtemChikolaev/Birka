@TestOn('vm')
library;

import 'package:database/src/birka_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:test/test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;
import 'generated/schema_v6.dart' as v6;

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

  test(
    'a transaction keeps its category and comes from no import in v4',
    () async {
      const at = '2026-11-04T12:00:00.000Z';
      await verifier.testWithDataIntegrity(
        oldVersion: 3,
        newVersion: 4,
        createOld: v3.DatabaseAtV3.new,
        createNew: v4.DatabaseAtV4.new,
        openTestedDatabase: BirkaDatabase.new,
        createItems: (batch, old) {
          batch
            ..insert(
              old.accounts,
              v3.AccountsCompanion.insert(
                id: 'card',
                createdAt: at,
                updatedAt: at,
                name: 'Card',
                type: 'debit',
                currency: 'RUB',
                decimalDigits: 2,
              ),
            )
            ..insert(
              old.categories,
              v3.CategoriesCompanion.insert(
                id: 'cafe',
                createdAt: at,
                updatedAt: at,
                kind: 'expense',
                name: 'Cafe',
              ),
            )
            ..insert(
              old.transactions,
              v3.TransactionsCompanion.insert(
                id: 'coffee',
                createdAt: at,
                updatedAt: at,
                kind: 'expense',
                occurredOn: '2026-10-03',
                status: 'cleared',
                source: 'manual',
              ),
            )
            ..insert(
              old.entries,
              v3.EntriesCompanion.insert(
                id: 'coffee-entry',
                createdAt: at,
                updatedAt: at,
                transactionId: 'coffee',
                accountId: 'card',
                amountMinor: -42000,
              ),
            )
            ..insert(
              old.allocations,
              v3.AllocationsCompanion.insert(
                id: 'coffee-cafe',
                createdAt: at,
                updatedAt: at,
                transactionId: 'coffee',
                categoryId: 'cafe',
                amountMinor: 42000,
              ),
            );
        },
        validateItems: (migrated) async {
          final allocation = await migrated
              .select(migrated.allocations)
              .getSingle();
          expect(allocation.categoryId, 'cafe');
          expect(allocation.amountMinor, 42000);
          final transaction = await migrated
              .select(migrated.transactions)
              .getSingle();
          expect(transaction.importId, isNull);
          expect(
            (await migrated.select(migrated.accounts).getSingle()).importId,
            isNull,
          );
          expect(
            (await migrated.select(migrated.categories).getSingle()).importId,
            isNull,
          );
          expect(await migrated.select(migrated.imports).get(), isEmpty);
        },
      );
    },
  );

  test('the ledger keeps its rows and gets regular payments in v5', () async {
    const at = '2026-11-06T12:00:00.000Z';
    await verifier.testWithDataIntegrity(
      oldVersion: 4,
      newVersion: 5,
      createOld: v4.DatabaseAtV4.new,
      createNew: v5.DatabaseAtV5.new,
      openTestedDatabase: BirkaDatabase.new,
      createItems: (batch, old) {
        batch
          ..insert(
            old.accounts,
            v4.AccountsCompanion.insert(
              id: 'card',
              createdAt: at,
              updatedAt: at,
              name: 'Card',
              type: 'debit',
              currency: 'RUB',
              decimalDigits: 2,
            ),
          )
          ..insert(
            old.categories,
            v4.CategoriesCompanion.insert(
              id: 'home',
              createdAt: at,
              updatedAt: at,
              kind: 'expense',
              name: 'Home',
            ),
          )
          ..insert(
            old.transactions,
            v4.TransactionsCompanion.insert(
              id: 'rent',
              createdAt: at,
              updatedAt: at,
              kind: 'expense',
              occurredOn: '2026-10-25',
              status: 'cleared',
              source: 'manual',
            ),
          );
      },
      validateItems: (migrated) async {
        expect(
          (await migrated.select(migrated.transactions).getSingle()).id,
          'rent',
        );
        expect(await migrated.select(migrated.schedules).get(), isEmpty);
        await migrated
            .into(migrated.schedules)
            .insert(
              v5.SchedulesCompanion.insert(
                id: 'rent-monthly',
                createdAt: at,
                updatedAt: at,
                kind: 'expense',
                name: 'Rent',
                accountId: 'card',
                categoryId: const Value('home'),
                amountMinor: 4500000,
                every: 'month',
                day: 25,
                nextOn: '2026-11-25',
                onDay: 'ask',
                reminder: 'onDay',
              ),
            );
        final schedule = await migrated.select(migrated.schedules).getSingle();
        expect(schedule.accountId, 'card');
        expect(schedule.toAccountId, isNull);
        expect(schedule.deletedAt, isNull);
      },
    );
  });

  test('a regular payment keeps its rule and has nothing done in v6', () async {
    const at = '2026-11-07T12:00:00.000Z';
    await verifier.testWithDataIntegrity(
      oldVersion: 5,
      newVersion: 6,
      createOld: v5.DatabaseAtV5.new,
      createNew: v6.DatabaseAtV6.new,
      openTestedDatabase: BirkaDatabase.new,
      createItems: (batch, old) {
        batch
          ..insert(
            old.accounts,
            v5.AccountsCompanion.insert(
              id: 'card',
              createdAt: at,
              updatedAt: at,
              name: 'Card',
              type: 'debit',
              currency: 'RUB',
              decimalDigits: 2,
            ),
          )
          ..insert(
            old.schedules,
            v5.SchedulesCompanion.insert(
              id: 'rent-monthly',
              createdAt: at,
              updatedAt: at,
              kind: 'expense',
              name: 'Rent',
              accountId: 'card',
              amountMinor: 4500000,
              every: 'month',
              day: 25,
              nextOn: '2026-11-25',
              onDay: 'ask',
              reminder: 'onDay',
            ),
          );
      },
      validateItems: (migrated) async {
        final schedule = await migrated.select(migrated.schedules).getSingle();
        expect(schedule.name, 'Rent');
        expect(schedule.amountMinor, 4500000);
        expect(schedule.nextOn, '2026-11-25');
        expect(schedule.lastDone, isNull);
        expect(schedule.lastFrom, isNull);
        expect(schedule.lastOn, isNull);
        expect(schedule.lastTransactionId, isNull);
        expect(schedule.lastImportId, isNull);
        expect(schedule.lastAt, isNull);
      },
    );
  });
}
