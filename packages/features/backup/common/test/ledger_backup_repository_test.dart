@TestOn('vm')
library;

import 'package:backup_common/src/data/ledger_backup_repository.dart';
import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late LedgerBackupRepository repository;

  setUp(() {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    repository = LedgerBackupRepository(ledger);
  });

  tearDown(() => database.close());

  test('a table names every operation, archived names included', () async {
    final card = await ledger.addAccount(
      name: 'Card',
      type: AccountType.debit,
      openingBalance: Money(0, Currency.rub),
    );
    final cafe = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Cafe',
    );
    final salary = await ledger.addCategory(
      kind: CategoryKind.income,
      name: 'Salary',
    );
    for (var day = 1; day <= 250; day++) {
      await ledger.record(
        TransactionDraft.expense(
          accountId: card.id,
          allocations: [
            Allocation(categoryId: cafe.id, amount: Money(100, Currency.rub)),
          ],
          occurredOn: CivilDate(2026, 1, 1 + day % 28),
        ),
      );
    }
    await ledger.updateAccount(card.id, archived: true);
    await ledger.updateCategory(cafe.id, archived: true);

    final export = await repository.operations();

    expect(export.transactions, hasLength(250));
    expect(export.accounts.map((it) => it.id), [card.id]);
    expect(
      export.categories.map((it) => it.id),
      unorderedEquals([cafe.id, salary.id]),
    );
  });
}
