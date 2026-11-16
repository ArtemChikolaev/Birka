@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:device_settings/device_settings.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_common/limits_common.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late LedgerLimitsRepository repository;
  late Category cafe;

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database, now: () => DateTime.utc(2026, 11, 18));
    repository = LedgerLimitsRepository(
      ledger,
      RatesRepository(database),
      BaseCurrency(null),
      MonthStart(1),
      now: () => DateTime(2026, 11, 18, 12),
    );
    await ledger.addAccount(
      name: 'Карта',
      type: AccountType.debit,
      openingBalance: Money(100000, Currency.rub),
    );
    await ledger.addAccount(
      name: 'Карта в евро',
      type: AccountType.debit,
      openingBalance: Money(10000, Currency.eur),
    );
    cafe = await ledger.addCategory(name: 'Кафе', kind: CategoryKind.expense);
  });

  tearDown(() => database.close());

  test('a limit set through it comes back with the categories', () async {
    final limit = CategoryLimit(Money(1200000, Currency.rub));
    await repository.setLimit(cafe.id, limit);
    final categories = await repository.watchCategories().first;
    expect(categories.single.limit, limit);
    await repository.setLimit(cafe.id, null);
    expect((await repository.watchCategories().first).single.limit, isNull);
  });

  test('the shown currency is that of the first account', () async {
    expect(await repository.watchShownCurrency().first, Currency.rub);
    expect(await repository.currencies(), [Currency.rub, Currency.eur]);
  });

  test('today and the month start come from the device', () async {
    expect(repository.today(), CivilDate(2026, 11, 18));
    expect(await repository.watchMonthStart().first, 1);
  });
}
