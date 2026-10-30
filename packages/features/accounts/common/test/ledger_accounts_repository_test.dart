@TestOn('vm')
library;

import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_common/src/data/ledger_accounts_repository.dart';
import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart' show LedgerRepository;
import 'package:money/money.dart';
import 'package:test/test.dart';

void main() {
  late BirkaDatabase database;
  late AccountsRepository repository;
  final draft = AccountDraft(
    name: 'Card',
    type: AccountType.debit,
    openingBalance: Money(100000, Currency.rub),
    art: AccountArt.sapphire,
    includeInTotals: true,
    lastDigits: '4568',
  );

  setUp(() {
    database = BirkaDatabase(NativeDatabase.memory());
    repository = LedgerAccountsRepository(LedgerRepository(database));
  });
  tearDown(() => database.close());

  test('a new account comes back with its balance and fields', () async {
    await repository.add(draft);

    final row = (await repository.watchAccounts().first).single;
    expect(row.balance, Money(100000, Currency.rub));
    expect(row.account.lastDigits, '4568');
    expect(row.account.art, AccountArt.sapphire);
  });

  test('a change replaces the fields and can drop the digits', () async {
    await repository.add(draft);
    final id = (await repository.watchAccounts().first).single.account.id;

    await repository.update(
      id,
      AccountDraft(
        name: 'Salary',
        type: AccountType.credit,
        openingBalance: Money(-50000, Currency.rub),
        art: AccountArt.amber,
        includeInTotals: false,
      ),
    );

    final account = (await repository.account(id))!;
    expect(account.name, 'Salary');
    expect(account.type, AccountType.credit);
    expect(account.openingBalance, Money(-50000, Currency.rub));
    expect(account.lastDigits, isNull);
    expect(account.art, AccountArt.amber);
    expect(account.includeInTotals, isFalse);
  });

  test('an archived account stays in the stream', () async {
    await repository.add(draft);
    final id = (await repository.watchAccounts().first).single.account.id;

    await repository.setArchived(id, archived: true);

    final row = (await repository.watchAccounts().first).single;
    expect(row.account.archived, isTrue);
  });
}
