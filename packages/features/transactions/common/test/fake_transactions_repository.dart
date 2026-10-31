import 'dart:async';

import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart';

/// Keeps the choices of quick add and the operations in memory.
final class FakeTransactionsRepository implements TransactionsRepository {
  /// Creates a repository with [accountList] and categories.
  FakeTransactionsRepository({
    this.accountList = const [],
    this.expenses = const [],
    this.income = const [],
    this.last,
    List<Operation> operations = const [],
  }) : _operations = operations;

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

  /// What was amended, by id.
  final amended = <String, TransactionDraft>{};

  /// The months that were asked for.
  final followed = <CivilDate>[];

  /// The months with operations.
  List<CivilDate> monthList = const [];

  List<Operation> _operations;
  final _changes = StreamController<void>.broadcast();

  /// The operations, whose change reaches those who follow them.
  List<Operation> get operations => _operations;
  set operations(List<Operation> value) {
    _operations = value;
    _changes.add(null);
  }

  /// Sends an error to those who follow the operations.
  void breakOperations(Object error) => _changes.addError(error);

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

  @override
  Stream<List<Operation>> watchOperations(CivilDate month) {
    followed.add(month);
    return _follow(
      () => [
        for (final operation in operations)
          if (operation.day.year == month.year &&
              operation.day.month == month.month)
            operation,
      ],
    );
  }

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
    final changes = _changes.stream.listen(
      (_) => controller.add(read()),
      onError: controller.addError,
    );
    controller.onCancel = changes.cancel;
  });

  @override
  Future<List<CivilDate>> months() async {
    if (readFailure case final failure?) throw failure;
    return monthList;
  }

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

/// An operation for tests. Its amount is what it does to [account].
Operation testOperation(
  String id, {
  required Money amount,
  Account? account,
  Account? toAccount,
  Money? received,
  Category? category,
  TransactionKind? kind,
  CivilDate? day,
  DateTime? at,
  String note = '',
  TransactionStatus status = TransactionStatus.cleared,
  TransactionSource source = TransactionSource.manual,
}) {
  final from = account ?? testAccount('card', currency: amount.currency);
  final picked =
      kind ??
      (amount.isNegative ? TransactionKind.expense : TransactionKind.income);
  return Operation(
    transaction: Transaction(
      id: id,
      kind: picked,
      occurredOn: day ?? CivilDate(2026, 10, 31),
      occurredAt: at,
      note: note,
      status: status,
      source: source,
      entries: [
        Entry(accountId: from.id, amount: amount),
        if (toAccount != null)
          Entry(accountId: toAccount.id, amount: received ?? -amount),
      ],
      allocations: [
        if (category != null)
          Allocation(categoryId: category.id, amount: amount.abs()),
      ],
    ),
    account: from,
    toAccount: toAccount,
    category: category,
  );
}
