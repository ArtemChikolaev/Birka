@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:overview_common/overview_common.dart' show OverviewRepository;
import 'package:overview_common/src/data/ledger_overview_repository.dart';
import 'package:test/test.dart';

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late OverviewRepository repository;
  final today = CivilDate(2026, 10, 31);
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

  setUp(() {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    repository = LedgerOverviewRepository(ledger);
  });
  tearDown(() => database.close());

  test('reads the accounts in everyday use with their balances', () async {
    final card = await ledger.addAccount(
      name: 'Card',
      type: AccountType.debit,
      openingBalance: rub(1000),
    );
    final old = await ledger.addAccount(
      name: 'Old',
      type: AccountType.debit,
      openingBalance: rub(5),
    );
    await ledger.updateAccount(old.id, archived: true);

    final accounts = await repository.watchAccounts().first;

    expect(accounts.single.account.id, card.id);
    expect(accounts.single.balance, rub(1000));
  });

  test('reads what days changed and what the month cost', () async {
    final card = await ledger.addAccount(
      name: 'Card',
      type: AccountType.debit,
      openingBalance: rub(1000),
    );
    final food = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Food',
    );
    final salary = await ledger.addCategory(
      kind: CategoryKind.income,
      name: 'Salary',
    );
    await ledger.record(
      TransactionDraft.expense(
        accountId: card.id,
        allocations: [Allocation(categoryId: food.id, amount: rub(300))],
        occurredOn: today,
      ),
    );
    await ledger.record(
      TransactionDraft.income(
        accountId: card.id,
        allocations: [Allocation(categoryId: salary.id, amount: rub(900))],
        occurredOn: today,
      ),
    );

    final changes = await repository.watchDayChanges(from: today).first;
    final spending = await repository
        .watchSpending(from: CivilDate(2026, 10, 1), to: today)
        .first;

    expect(changes.single.change, rub(600));
    expect(spending.single.category.name, 'Food');
    expect(spending.single.total, rub(300));
  });
}
