import 'dart:async';

import 'package:ledger/ledger.dart' hide Category;
import 'package:ledger/ledger.dart' as ledger show Category;
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart';

/// Keeps what the screens read and write in memory.
final class FakeRepository implements TransactionsRepository {
  /// Creates a repository with [operations], the latest first.
  FakeRepository({
    this.accountList = const [],
    this.expenses = const [],
    this.income = const [],
    List<Operation> operations = const [],
  }) : _operations = operations;

  /// The accounts.
  List<Account> accountList;

  /// The categories of expenses.
  List<ledger.Category> expenses;

  /// The categories of income.
  List<ledger.Category> income;

  /// What was recorded.
  final recorded = <TransactionDraft>[];

  /// What was amended, by id.
  final amended = <String, TransactionDraft>{};

  /// The months with operations.
  List<CivilDate> monthList = const [];

  /// The error of the next write.
  Exception? failure;

  /// The error of the next read.
  Exception? readFailure;

  List<Operation> _operations;
  final _changes = StreamController<void>.broadcast();

  /// The operations, whose change reaches those who follow them.
  List<Operation> get operations => _operations;
  set operations(List<Operation> value) {
    _operations = value;
    _changes.add(null);
  }

  @override
  Future<List<Account>> accounts() async {
    if (readFailure case final failure?) throw failure;
    return accountList;
  }

  @override
  Future<List<ledger.Category>> categories(CategoryKind kind) async =>
      kind == CategoryKind.expense ? expenses : income;

  @override
  Future<String?> lastAccountId() async => null;

  @override
  Future<void> record(TransactionDraft draft) async {
    if (failure case final failure?) throw failure;
    recorded.add(draft);
  }

  @override
  Stream<List<Operation>> watchOperations(CivilDate month) => _follow(
    () => [
      for (final operation in operations)
        if (operation.day.year == month.year &&
            operation.day.month == month.month)
          operation,
    ],
  );

  @override
  Stream<Operation?> watchOperation(String id) => _follow(
    () => operations.where((operation) => operation.id == id).firstOrNull,
  );

  Stream<T> _follow<T>(T Function() read) => Stream.multi((controller) {
    if (readFailure case final failure?) {
      controller.addError(failure);
    } else {
      controller.add(read());
    }
    final changes = _changes.stream.listen((_) => controller.add(read()));
    controller.onCancel = changes.cancel;
  });

  @override
  Future<List<CivilDate>> months() async => monthList;

  @override
  Future<void> amend(String id, TransactionDraft draft) async {
    if (failure case final failure?) throw failure;
    amended[id] = draft;
  }

  @override
  Future<void> delete(String id) async {
    if (failure case final failure?) throw failure;
    operations = [
      for (final operation in operations)
        if (operation.id != id) operation,
    ];
  }
}

/// An account for tests.
Account testAccount(String name, {Currency currency = Currency.rub}) => Account(
  id: name,
  name: name,
  type: AccountType.debit,
  openingBalance: Money.zero(currency),
  includeInTotals: true,
  archived: false,
  sortOrder: 0,
);

/// A category for tests.
ledger.Category testCategory(
  String name, {
  CategoryKind kind = CategoryKind.expense,
}) => ledger.Category(
  id: name,
  kind: kind,
  name: name,
  archived: false,
  sortOrder: 0,
  icon: 'cart',
  color: '#4ade80',
);

/// An operation for tests. Its amount is what it does to [account].
Operation testOperation(
  String id, {
  required Money amount,
  required Account account,
  Account? toAccount,
  Money? received,
  ledger.Category? category,
  TransactionKind? kind,
  CivilDate? day,
  DateTime? at,
  String note = '',
  TransactionSource source = TransactionSource.manual,
}) => Operation(
  transaction: Transaction(
    id: id,
    kind:
        kind ??
        (amount.isNegative ? TransactionKind.expense : TransactionKind.income),
    occurredOn: day ?? CivilDate(2026, 10, 31),
    occurredAt: at,
    note: note,
    status: TransactionStatus.cleared,
    source: source,
    entries: [
      Entry(accountId: account.id, amount: amount),
      if (toAccount != null)
        Entry(accountId: toAccount.id, amount: received ?? -amount),
    ],
    allocations: [
      if (category != null)
        Allocation(categoryId: category.id, amount: amount.abs()),
    ],
  ),
  account: account,
  toAccount: toAccount,
  category: category,
);
