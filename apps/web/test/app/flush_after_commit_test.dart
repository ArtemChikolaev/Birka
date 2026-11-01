import 'dart:async';

import 'package:birka_web/app/flush_after_commit.dart';
import 'package:database/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late BirkaDatabase database;
  late int flushes;
  late Completer<void>? held;

  setUp(() async {
    flushes = 0;
    held = null;
    database = BirkaDatabase(
      NativeDatabase.memory().interceptWith(
        FlushAfterCommit(() async {
          flushes++;
          await held?.future;
        }),
      ),
    );
    await database.customSelect('SELECT 1').get();
    flushes = 0;
  });
  tearDown(() => database.close());

  ExchangeRatesCompanion rate(String currency) => ExchangeRatesCompanion.insert(
    day: '2026-10-31',
    currency: currency,
    rubles: '80',
  );

  test('a transaction waits for the storage', () async {
    final stored = Completer<void>();
    held = stored;
    var finished = false;

    final write = database
        .transaction(
          () => database.into(database.exchangeRates).insert(rate('USD')),
        )
        .then((_) => finished = true);
    await pumpEventQueue();

    expect(flushes, 1);
    expect(finished, isFalse);

    stored.complete();
    await write;
    expect(finished, isTrue);
  });

  test('it is committed by then', () async {
    final stored = Completer<void>();
    held = stored;

    final write = database.transaction(
      () => database.into(database.exchangeRates).insert(rate('USD')),
    );
    await pumpEventQueue();

    expect(await database.select(database.exchangeRates).get(), hasLength(1));

    stored.complete();
    await write;
  });

  test('a batch waits too', () async {
    await database.batch(
      (batch) => batch.insertAll(database.exchangeRates, [
        rate('USD'),
        rate('EUR'),
      ]),
    );

    expect(flushes, 1);
  });

  test('a transaction that fails has nothing to wait for', () async {
    await expectLater(
      database.transaction<void>(() async {
        await database.into(database.exchangeRates).insert(rate('USD'));
        throw StateError('no');
      }),
      throwsStateError,
    );

    expect(flushes, 0);
    expect(await database.select(database.exchangeRates).get(), isEmpty);
  });

  test('a read does not wait', () async {
    await database.select(database.exchangeRates).get();

    expect(flushes, 0);
  });
}
