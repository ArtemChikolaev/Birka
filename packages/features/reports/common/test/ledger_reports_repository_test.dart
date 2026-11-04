@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:reports_common/reports_common.dart' show ReportsRepository;
import 'package:reports_common/src/data/ledger_reports_repository.dart';
import 'package:test/test.dart';

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late RatesRepository rates;
  late BaseCurrency baseCurrency;
  late ReportsRepository repository;
  final today = CivilDate(2026, 10, 31);
  final october = CivilDate(2026, 10, 1);
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

  setUp(() {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    rates = RatesRepository(database);
    baseCurrency = BaseCurrency(Currency.usd);
    repository = LedgerReportsRepository(ledger, rates, baseCurrency);
  });
  tearDown(() => database.close());

  test('the main currency is that of the first account that counts', () async {
    expect(await repository.watchMainCurrency().first, isNull);

    await ledger.addAccount(
      name: 'Hidden',
      type: AccountType.cash,
      openingBalance: Money(0, Currency.usd),
      includeInTotals: false,
    );
    await ledger.addAccount(
      name: 'Euro',
      type: AccountType.cash,
      openingBalance: Money(0, Currency.eur),
    );
    await ledger.addAccount(
      name: 'Card',
      type: AccountType.debit,
      openingBalance: rub(0),
    );

    expect(await repository.watchMainCurrency().first, Currency.eur);
  });

  test('the base currency is the one picked', () async {
    expect(await repository.watchBaseCurrency().first, Currency.usd);
  });

  test('the rates are the kept ones', () async {
    await rates.keep(DayRates(today, {'USD': Decimal.fromInt(80)}));

    expect((await repository.watchRates().first).latestDay, today);
  });

  test('reads the days of a category and the months', () async {
    final card = await ledger.addAccount(
      name: 'Card',
      type: AccountType.debit,
      openingBalance: rub(0),
    );
    final food = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Food',
    );
    await ledger.record(
      TransactionDraft.expense(
        accountId: card.id,
        allocations: [Allocation(categoryId: food.id, amount: rub(300))],
        occurredOn: today,
      ),
    );

    final rows = await repository
        .watchDays(CategoryKind.expense, from: october, to: today)
        .first;

    expect(rows.single.category?.name, 'Food');
    expect(rows.single.day, today);
    expect(rows.single.total, rub(300));
    expect(await repository.months(), [october]);
  });
}
