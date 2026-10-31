import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';
import 'package:transactions_common/transactions_common.dart';

import 'fake_transactions_repository.dart';

void main() {
  Transaction spent(String categoryId) => Transaction(
    id: categoryId,
    kind: TransactionKind.expense,
    occurredOn: CivilDate(2026, 10, 31),
    note: '',
    status: TransactionStatus.cleared,
    source: TransactionSource.manual,
    entries: const [],
    allocations: [
      Allocation(categoryId: categoryId, amount: Money(100, Currency.rub)),
    ],
  );

  List<String> ranked(List<Transaction> recent) => rankCategories([
    testCategory('a'),
    testCategory('b'),
    testCategory('c'),
  ], recent).map((category) => category.id).toList();

  test('without a history the order stays', () {
    expect(ranked(const []), ['a', 'b', 'c']);
  });

  test('frequent categories go first', () {
    expect(ranked([spent('c'), spent('c'), spent('b')]), ['c', 'b', 'a']);
  });

  test('equally frequent categories keep their order', () {
    expect(ranked([spent('c'), spent('b')]), ['b', 'c', 'a']);
  });

  test('a category that is gone does not get in the way', () {
    expect(ranked([spent('gone')]), ['a', 'b', 'c']);
  });
}
