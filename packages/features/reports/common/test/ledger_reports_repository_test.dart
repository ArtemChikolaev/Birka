@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:reports_common/reports_common.dart' show ReportsRepository;
import 'package:reports_common/src/data/ledger_reports_repository.dart';
import 'package:test/test.dart';

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late ReportsRepository repository;
  final today = CivilDate(2026, 10, 31);
  final october = CivilDate(2026, 10, 1);
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

  setUp(() {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    repository = LedgerReportsRepository(ledger);
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

  test('reads the totals of a month and the months', () async {
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
        .watchTotals(CategoryKind.expense, from: october, to: today)
        .first;
    final months = await repository
        .watchMonthTotals(CategoryKind.expense, from: october, to: today)
        .first;

    expect(rows.single.category.name, 'Food');
    expect(rows.single.total, rub(300));
    expect(months.single.month, october);
    expect(months.single.total, rub(300));
    expect(await repository.months(), [october]);
  });
}
