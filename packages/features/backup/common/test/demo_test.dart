@TestOn('vm')
library;

import 'package:backup_common/backup_common.dart';
import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  final now = DateTime(2026, 11, 3, 18, 30);
  late BirkaDatabase database;
  late LedgerRepository ledger;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
  });

  tearDown(() async {
    await database.close();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  group('the state of the demo', () {
    test('starts off, in the ledger of the device', () {
      final store = FakeSettingsStore();

      expect(demoStateIn(store), DemoState.off);
      expect(databaseNameIn(store), 'birka');
    });

    test('a demo that comes on opens its own database, fresh', () async {
      final store = FakeSettingsStore();

      await turnDemo(store, on: true);

      expect(demoStateIn(store), DemoState.fresh);
      expect(databaseNameIn(store), 'birka-demo');
    });

    test('a fresh demo fills once and stays as it is after', () async {
      final store = FakeSettingsStore();
      await turnDemo(store, on: true);

      await settleDemo(store, ledger, now: now);
      final filled = await ledger.watchCounts().first;
      await ledger.wipe();
      await settleDemo(store, ledger, now: now);

      expect(filled.transactions, greaterThan(100));
      expect(demoStateIn(store), DemoState.on);
      expect((await ledger.watchCounts().first).transactions, 0);
    });

    test('a demo that goes off opens the ledger of the device', () async {
      final store = FakeSettingsStore({'demo': 'on'});

      await turnDemo(store, on: false);

      expect(demoStateIn(store), DemoState.off);
      expect(databaseNameIn(store), 'birka');
    });

    test('an unknown value counts as off', () {
      expect(demoStateIn(FakeSettingsStore({'demo': 'maybe'})), DemoState.off);
    });
  });

  group('the demo', () {
    test(
      'holds four accounts in three currencies and every category',
      () async {
        await fillDemo(ledger, now: now);

        final accounts = await ledger.watchAccounts().first;
        expect(accounts.map((it) => it.name), [
          'Зарплатная карта',
          'Наличные',
          'Накопления',
          'Карта в евро',
        ]);
        expect(accounts.map((it) => it.currency).toSet(), {
          Currency.rub,
          Currency.usd,
          Currency.eur,
        });
        final counts = await ledger.watchCounts().first;
        expect(counts.categories, categoryPresets.length);
      },
    );

    test('covers half a year up to today', () async {
      await fillDemo(ledger, now: now);

      final months = await ledger.months();
      expect(months, hasLength(6));
      expect(months.first, CivilDate(2026, 11, 1));
      expect(months.last, CivilDate(2026, 6, 1));
    });

    test('leaves no account below zero', () async {
      await fillDemo(ledger, now: now);

      for (final account in await ledger.watchAccounts().first) {
        expect(
          (await ledger.balance(account.id)).isNegative,
          isFalse,
          reason: account.name,
        );
      }
    });

    test('is the same demo for the same moment', () async {
      Future<List<Money>> balances() async => [
        for (final account in await ledger.watchAccounts().first)
          await ledger.balance(account.id),
      ];
      await fillDemo(ledger, now: now);
      final counts = await ledger.watchCounts().first;
      final first = await balances();

      await fillDemo(ledger, now: now);

      expect(await ledger.watchCounts().first, counts);
      expect(await balances(), first);
    });

    test('takes the place of whatever the ledger held', () async {
      await ledger.addAccount(
        name: 'Своя карта',
        type: AccountType.debit,
        openingBalance: Money(100, Currency.rub),
      );

      await fillDemo(ledger, now: now);

      final names = (await ledger.watchAccounts().first).map((it) => it.name);
      expect(names, isNot(contains('Своя карта')));
    });
  });
}
