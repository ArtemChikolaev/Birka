@TestOn('vm')
library;

import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_common/src/data/ledger_accounts_repository.dart';
import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart'
    show
        CivilDate,
        LedgerRepository,
        TransactionDraft,
        TransactionKind,
        TransactionSource;
import 'package:money/money.dart';
import 'package:test/test.dart';

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late AccountsRepository repository;
  final now = DateTime(2026, 10, 31, 9, 30);
  final today = CivilDate(2026, 10, 31);
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final draft = AccountDraft(
    name: 'Card',
    type: AccountType.debit,
    currency: Currency.rub,
    balance: Money(100000, Currency.rub),
    art: AccountArt.sapphire,
    includeInTotals: true,
    lastDigits: '4568',
  );

  setUp(() {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    repository = LedgerAccountsRepository(ledger, now: () => now);
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
      const AccountDraft(
        name: 'Salary',
        type: AccountType.credit,
        currency: Currency.rub,
        art: AccountArt.amber,
        includeInTotals: false,
      ),
    );

    final account = (await repository.account(id))!.account;
    expect(account.name, 'Salary');
    expect(account.type, AccountType.credit);
    expect(account.lastDigits, isNull);
    expect(account.art, AccountArt.amber);
    expect(account.includeInTotals, isFalse);
  });

  test('a new account without a balance starts from zero', () async {
    await repository.add(
      const AccountDraft(
        name: 'Cash',
        type: AccountType.cash,
        currency: Currency.eur,
        art: AccountArt.emerald,
        includeInTotals: true,
      ),
    );

    final row = (await repository.watchAccounts().first).single;
    expect(row.balance, Money(0, Currency.eur));
  });

  group('a saved account with operations', () {
    late String id;

    AccountDraft holding(Money? balance) => AccountDraft(
      name: 'Card',
      type: AccountType.debit,
      currency: Currency.rub,
      balance: balance,
      art: AccountArt.sapphire,
      includeInTotals: true,
    );

    setUp(() async {
      await repository.add(draft);
      id = (await repository.watchAccounts().first).single.account.id;
      await ledger.record(
        TransactionDraft.adjustment(
          accountId: id,
          change: rub(-40000),
          occurredOn: CivilDate(2026, 10, 1),
        ),
      );
    });

    test('comes with what it holds, not what it started from', () async {
      final row = (await repository.account(id))!;

      expect(row.account.openingBalance, rub(100000));
      expect(row.balance, rub(60000));
    });

    test('a new balance becomes a correction of today', () async {
      await repository.update(id, holding(rub(75000)));

      expect((await repository.account(id))!.balance, rub(75000));
      final correction = (await ledger.watchTransactions().first).first;
      expect(correction.kind, TransactionKind.adjustment);
      expect(correction.entries.single.amount, rub(15000));
      expect(correction.occurredOn, today);
      expect(correction.occurredAt, now.toUtc());
      expect(correction.source, TransactionSource.manual);
    });

    test('what it started from and what happened stay', () async {
      await repository.update(id, holding(rub(0)));

      final row = (await repository.account(id))!;
      expect(row.account.openingBalance, rub(100000));
      expect(row.balance, rub(0));
      expect(await ledger.watchTransactions().first, hasLength(2));
    });

    test('a balance it already holds adds nothing', () async {
      await repository.update(id, holding(rub(60000)));

      expect(await ledger.watchTransactions().first, hasLength(1));
    });

    test('without a balance it stays as it is', () async {
      await repository.update(id, holding(null));

      expect((await repository.account(id))!.balance, rub(60000));
      expect(await ledger.watchTransactions().first, hasLength(1));
    });

    test('a correction that fails takes the other changes back', () async {
      final update = repository.update(
        id,
        AccountDraft(
          name: 'Renamed',
          type: AccountType.debit,
          currency: Currency.rub,
          balance: Money(1, Currency.eur),
          art: AccountArt.sapphire,
          includeInTotals: true,
        ),
      );

      await expectLater(update, throwsA(anything));
      expect((await repository.account(id))!.account.name, 'Card');
    });

    test('an account that is gone reports nothing', () async {
      expect(await repository.account('missing'), isNull);
    });
  });

  test('an archived account stays in the stream', () async {
    await repository.add(draft);
    final id = (await repository.watchAccounts().first).single.account.id;

    await repository.setArchived(id, archived: true);

    final row = (await repository.watchAccounts().first).single;
    expect(row.account.archived, isTrue);
  });
}
