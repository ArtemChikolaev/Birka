@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

final class _Source implements RateSource {
  DayRates? rates;
  Exception? failure;
  int reads = 0;

  @override
  Future<DayRates> latest() async {
    reads++;
    if (failure case final failure?) throw failure;
    return rates!;
  }

  @override
  Future<DayRates?> on(CivilDate day) async => null;
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

    setUp(() {
      source = _Source()..rates = dollarAt('80', saturday);
      now = DateTime(2026, 10, 31, 12);
      updater = RatesUpdater(repository, source, now: () => now);
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
  });
}
