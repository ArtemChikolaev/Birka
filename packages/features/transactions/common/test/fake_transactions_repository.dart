import 'dart:async';

import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart';

/// Keeps the choices of quick add in memory.
final class FakeTransactionsRepository implements TransactionsRepository {
  /// Creates a repository with [accountList] and categories.
  FakeTransactionsRepository({
    this.accountList = const [],
    this.expenses = const [],
    this.income = const [],
    this.last,
  });

  /// The accounts.
  List<Account> accountList;

  /// The categories of expenses.
  List<Category> expenses;

  /// The categories of income.
  List<Category> income;

  /// The account of the latest transaction.
  String? last;

  /// The error of the next write.
  Exception? failure;

  /// The error of the next read.
  Exception? readFailure;

  /// What the next write waits for.
  Completer<void>? gate;

  /// What was recorded.
  final recorded = <TransactionDraft>[];

  @override
  Future<List<Account>> accounts() async {
    if (readFailure case final failure?) throw failure;
    return accountList;
  }

  @override
  Future<List<Category>> categories(CategoryKind kind) async =>
      kind == CategoryKind.expense ? expenses : income;

  @override
  Future<String?> lastAccountId() async => last;

  @override
  Future<void> record(TransactionDraft draft) async {
    await gate?.future;
    if (failure case final failure?) throw failure;
    recorded.add(draft);
  }
}

/// An account for tests.
Account testAccount(String id, {Currency currency = Currency.rub}) => Account(
  id: id,
  name: id,
  type: AccountType.debit,
  openingBalance: Money.zero(currency),
  includeInTotals: true,
  archived: false,
  sortOrder: 0,
);

/// A category for tests.
Category testCategory(
  String id, {
  CategoryKind kind = CategoryKind.expense,
}) => Category(
  id: id,
  kind: kind,
  name: id,
  archived: false,
  sortOrder: 0,
);
