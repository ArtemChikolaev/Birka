@TestOn('vm')
library;

import 'dart:async';

import 'package:database/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

final class _Source implements RateSource {
  DayRates? rates;
  Exception? failure;
  Exception? pastFailure;
  int reads = 0;
  void Function()? whenAsked;
  final past = <CivilDate, DayRates>{};
  final asked = <CivilDate>[];

  @override
  Future<DayRates> latest() async {
    reads++;
    if (failure case final failure?) throw failure;
    return rates!;
  }

  @override
  Future<DayRates?> on(CivilDate day) async {
    asked.add(day);
    whenAsked?.call();
    if (pastFailure case final failure?) throw failure;
    return past[day];
  }
}

void main() {
  late BirkaDatabase database;
  late RatesRepository repository;
  final friday = CivilDate(2026, 10, 30);
  final saturday = CivilDate(2026, 10, 31);

  DayRates dollarAt(String rubles, CivilDate day) =>
      DayRates(day, {'USD': Decimal.parse(rubles)});

  setUp(() {
    database = BirkaDatabase(NativeDatabase.memory());
    repository = RatesRepository(database);
  });
  tearDown(() => database.close());

  group('the repository', () {
    test('has no rates at first', () async {
      expect(await repository.latestDay(), isNull);
      expect((await repository.watchRates().first).latestDay, isNull);
    });

    test('keeps only the currencies that Birka offers', () async {
      await repository.keep(
        DayRates(saturday, {
          'USD': Decimal.fromInt(80),
          'XDR': Decimal.fromInt(100),
        }),
      );

      final book = await repository.watchRates().first;

      expect(book.canConvert(Currency.usd, Currency.rub), isTrue);
      expect(book.canConvert(Currency.iso('XDR'), Currency.rub), isFalse);
    });

    test('knows the days it has', () async {
      await repository.keep(dollarAt('80', friday));
      await repository.keep(dollarAt('81', saturday));

      expect(await repository.keptDays(), {friday, saturday});
    });

    test('gives back what it keeps, digit by digit', () async {
      await repository.keep(dollarAt('80.5573', saturday));

      final book = await repository.watchRates().first;

      expect(book.latestDay, saturday);
      expect(
        book.convert(Money(1000000, Currency.usd), Currency.rub),
        Money(80557300, Currency.rub),
      );
    });

    test('knows the latest day', () async {
      await repository.keep(dollarAt('81', saturday));
      await repository.keep(dollarAt('80', friday));

      expect(await repository.latestDay(), saturday);
    });

    test('a day kept again takes the new rate', () async {
      await repository.keep(dollarAt('80', saturday));
      await repository.keep(dollarAt('90', saturday));

      final book = await repository.watchRates().first;

      expect(
        book.convert(Money(100, Currency.usd), Currency.rub),
        Money(9000, Currency.rub),
      );
    });

    test('tells those who follow', () async {
      final books = repository.watchRates();
      expect(
        books.map((book) => book.latestDay),
        emitsInOrder([null, saturday]),
      );

      await pumpEventQueue();
      await repository.keep(dollarAt('80', saturday));
    });
  });

  group('the updater', () {
    late _Source source;
    late DateTime now;
    late RatesUpdater updater;
    late LedgerRepository ledger;
    late BaseCurrency baseCurrency;

    RatesUpdater updaterOn(Currency? base) {
      baseCurrency = BaseCurrency(base);
      return RatesUpdater(
        repository,
        source,
        ledger,
        baseCurrency,
        now: () => now,
        gap: Duration.zero,
      );
    }

    /// Records an expense in [currency] on each of [days], from an account
    /// that counts after the one in rubles.
    Future<void> spentOn(Currency currency, List<CivilDate> days) async {
      final accounts = await ledger.watchAccounts().first;
      final account =
          accounts.where((it) => it.currency == currency).firstOrNull ??
          await ledger.addAccount(
            name: currency.code,
            type: AccountType.cash,
            openingBalance: Money.zero(currency),
          );
      final category = await ledger.addCategory(
        kind: CategoryKind.expense,
        name: 'Food ${currency.code}',
      );
      for (final day in days) {
        await ledger.record(
          TransactionDraft.expense(
            accountId: account.id,
            allocations: [
              Allocation(categoryId: category.id, amount: Money(100, currency)),
            ],
            occurredOn: day,
          ),
        );
      }
    }

    setUp(() async {
      source = _Source()..rates = dollarAt('80', saturday);
      now = DateTime(2026, 10, 31, 12);
      ledger = LedgerRepository(database);
      updater = updaterOn(null);
      await ledger.addAccount(
        name: 'Card',
        type: AccountType.debit,
        openingBalance: const Money.zero(Currency.rub),
      );
    });

    test('brings the first rates', () async {
      await updater.refresh();

      expect(await repository.latestDay(), saturday);
    });

    test('leaves today alone once it has rates', () async {
      await updater.refresh();
      await updater.refresh();

      expect(source.reads, 1);
    });

    test('asks again on a day that has no rates of its own', () async {
      await updater.refresh();
      now = DateTime(2026, 11, 1, 12);

      await updater.refresh();

      expect(source.reads, 2);
      expect(await repository.latestDay(), saturday);
    });

    test('keeps the last rates when the network is down', () async {
      await updater.refresh();
      now = DateTime(2026, 11, 2, 12);
      source.failure = Exception('offline');

      await updater.refresh();

      expect(await repository.latestDay(), saturday);
    });

    test('a failure of the first read is quiet too', () async {
      source.failure = Exception('offline');

      await updater.refresh();

      expect(await repository.latestDay(), isNull);
    });

    group('the history', () {
      final thursday = CivilDate(2026, 10, 29);
      final sunday = CivilDate(2026, 10, 25);

      test('brings the days of other currencies, the latest first', () async {
        source.past[friday] = dollarAt('70', friday);
        source.past[thursday] = dollarAt('60', thursday);
        await spentOn(Currency.usd, [thursday, friday]);

        await updater.refresh();

        expect(source.asked, [friday, thursday]);
        final book = await repository.watchRates().first;
        expect(
          book.convert(Money(100, Currency.usd), Currency.rub, on: thursday),
          Money(6000, Currency.rub),
        );
        expect(
          book.convert(Money(100, Currency.usd), Currency.rub, on: friday),
          Money(7000, Currency.rub),
        );
      });

      test('asks for no day twice', () async {
        source.past[friday] = dollarAt('70', friday);
        await spentOn(Currency.usd, [friday]);

        await updater.refresh();
        await updater.refresh();

        expect(source.asked, [friday]);
      });

      test('leaves alone the days it already has', () async {
        await repository.keep(dollarAt('70', friday));
        await spentOn(Currency.usd, [friday]);

        await updater.refresh();

        expect(source.asked, isEmpty);
      });

      test('a day without rates keeps those of the day before it', () async {
        final saturdayBefore = CivilDate(2026, 10, 24);
        source.past[saturdayBefore] = dollarAt('50', saturdayBefore);
        await spentOn(Currency.usd, [sunday]);

        await updater.refresh();

        expect(source.asked, [sunday, saturdayBefore]);
        expect(await repository.keptDays(), {saturday, sunday});
        final book = await repository.watchRates().first;
        expect(
          book.convert(Money(100, Currency.usd), Currency.rub, on: sunday),
          Money(5000, Currency.rub),
        );
      });

      test('needs nothing for the currency of the totals', () async {
        await spentOn(Currency.rub, [friday]);

        await updater.refresh();

        expect(source.asked, isEmpty);
      });

      test('follows the currency picked for totals', () async {
        await spentOn(Currency.usd, [friday]);
        await spentOn(Currency.rub, [thursday]);
        source.past[thursday] = dollarAt('60', thursday);

        await updaterOn(Currency.usd).refresh();

        expect(source.asked, [thursday]);
      });

      test('does not look past today', () async {
        await spentOn(Currency.usd, [CivilDate(2026, 11, 5)]);

        await updater.refresh();

        expect(source.asked, isEmpty);
      });

      test('stops at the first failure and keeps what it has', () async {
        source.pastFailure = Exception('offline');
        await spentOn(Currency.usd, [thursday, friday]);

        await updater.refresh();

        expect(source.asked, [friday]);
        expect(await repository.keptDays(), {saturday});
      });

      test('leaves the rest of a long history for the next run', () async {
        final days = [
          for (var day = 1; day <= 30; day++) CivilDate(2026, 9, day),
        ];
        for (final day in days) {
          source.past[day] = dollarAt('70', day);
        }
        await spentOn(Currency.usd, days);

        await updater.refresh();
        expect(source.asked, hasLength(25));
        expect(source.asked.first, CivilDate(2026, 9, 30));

        await updater.refresh();
        expect(source.asked, hasLength(30));
        expect(source.asked.last, CivilDate(2026, 9, 1));
      });

      test('ends the run after two weeks of nothing', () async {
        final older = CivilDate(2026, 9, 1);
        source.past[older] = dollarAt('50', older);
        await spentOn(Currency.usd, [older, sunday]);

        await updater.refresh();

        expect(source.asked, hasLength(13));
        expect(await repository.keptDays(), {saturday});
      });

      test('runs once at a time', () async {
        source.past[friday] = dollarAt('70', friday);
        await spentOn(Currency.usd, [friday]);

        await Future.wait([updater.refresh(), updater.refresh()]);

        expect(source.reads, 1);
        expect(source.asked, [friday]);
      });

      test('turns to a base currency picked during a run', () async {
        final wednesday = CivilDate(2026, 10, 28);
        source
          ..past[friday] = dollarAt('70', friday)
          ..past[thursday] = dollarAt('60', thursday)
          ..whenAsked = () {
            source.whenAsked = null;
            baseCurrency.choose(Currency.usd);
            unawaited(updater.refresh());
          };
        await spentOn(Currency.usd, [wednesday, friday]);
        await spentOn(Currency.rub, [thursday]);
        now = DateTime(2026, 11, 1, 12);

        await updater.refresh();

        expect(source.asked, [friday, thursday]);
        expect(source.reads, 1);
      });

      test('asks for nothing twice when called during a run', () async {
        source
          ..past[friday] = dollarAt('70', friday)
          ..whenAsked = () {
            source.whenAsked = null;
            unawaited(updater.refresh());
          };
        await spentOn(Currency.usd, [friday]);

        await updater.refresh();

        expect(source.asked, [friday]);
      });

      test('runs again after a failure', () async {
        source.failure = Exception('offline');
        await updater.refresh();
        source.failure = null;

        await updater.refresh();

        expect(source.reads, 2);
      });
    });
  });
}
