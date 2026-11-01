@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:onboarding_common/src/data/ledger_onboarding_repository.dart';
import 'package:onboarding_common/src/domain/first_account.dart';
import 'package:onboarding_common/src/domain/ready_category.dart';
import 'package:test/test.dart';

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late LedgerOnboardingRepository repository;

  const groceries = ReadyCategory(
    kind: CategoryKind.expense,
    name: 'Groceries',
    icon: 'cart',
    color: '#4ade80',
  );
  const salary = ReadyCategory(
    kind: CategoryKind.income,
    name: 'Salary',
    icon: 'briefcase',
    color: '#4ade80',
  );
  final card = FirstAccount(
    name: 'Card',
    type: AccountType.debit,
    balance: Money(125050, Currency.rub),
  );

  setUp(() {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    repository = LedgerOnboardingRepository(ledger);
  });
  tearDown(() => database.close());

  test('a new database holds no accounts', () async {
    expect(await repository.hasAccounts(), isFalse);
  });

  test('an archived account counts', () async {
    final account = await ledger.addAccount(
      name: 'Old',
      type: AccountType.cash,
      openingBalance: const Money.zero(Currency.rub),
    );
    await ledger.updateAccount(account.id, archived: true);

    expect(await repository.hasAccounts(), isTrue);
  });

  test('adds the account with what it holds, and the categories', () async {
    await repository.save(account: card, categories: const [groceries, salary]);

    final accounts = await ledger.watchAccountBalances().first;
    expect(accounts.single.account.name, 'Card');
    expect(accounts.single.balance, Money(125050, Currency.rub));
    final expenses = await ledger.watchCategories(CategoryKind.expense).first;
    expect(expenses.single.name, 'Groceries');
    expect(expenses.single.icon, 'cart');
    expect(expenses.single.color, '#4ade80');
    final income = await ledger.watchCategories(CategoryKind.income).first;
    expect(income.single.name, 'Salary');
  });

  test('adds categories without an account', () async {
    await repository.save(account: null, categories: const [groceries]);

    expect(await repository.hasAccounts(), isFalse);
    final expenses = await ledger.watchCategories(CategoryKind.expense).first;
    expect(expenses, hasLength(1));
  });

  test('keeps nothing when a part fails', () async {
    await database.customStatement('''
      CREATE TRIGGER no_salary BEFORE INSERT ON categories
      WHEN NEW.name = 'Salary'
      BEGIN SELECT RAISE(ABORT, 'no room'); END
    ''');

    await expectLater(
      repository.save(account: card, categories: const [groceries, salary]),
      throwsA(isA<Exception>()),
    );

    expect(await repository.hasAccounts(), isFalse);
    expect(await ledger.watchCategories(CategoryKind.expense).first, isEmpty);
  });
}
