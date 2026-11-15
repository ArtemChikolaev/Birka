@TestOn('vm')
library;

import 'dart:convert';

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

const groceries = Receipt(
  drive: '7380440700076541',
  document: '24611',
  sign: '2531297412',
  kind: ReceiptKind.sale,
);

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late Account card;
  late Category food;

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(
      database,
      now: () => DateTime.utc(2026, 11, 18, 7),
    );
    card = await ledger.addAccount(
      name: 'Карта',
      type: AccountType.debit,
      openingBalance: rub(4774950),
    );
    food = await ledger.addCategory(
      name: 'Продукты',
      kind: CategoryKind.expense,
      icon: 'cart',
      color: '#4ade80',
    );
  });

  tearDown(() => database.close());

  TransactionDraft fromReceipt(
    Receipt receipt, {
    CivilDate? day,
    int amount = 62000,
    String note = '',
  }) => TransactionDraft.expense(
    accountId: card.id,
    allocations: [Allocation(categoryId: food.id, amount: rub(amount))],
    occurredOn: day ?? CivilDate(2026, 11, 18),
    occurredAt: DateTime.utc(2026, 11, 18, 6, 12),
    note: note,
    source: TransactionSource.receipt,
  ).withReceipt(receipt);

  test('a transaction keeps the receipt it was made from', () async {
    final id = await ledger.record(fromReceipt(groceries));
    final saved = await ledger.watchTransaction(id).first;
    expect(saved!.source, TransactionSource.receipt);
    expect(saved.receipt, groceries);
    expect(saved.occurredAt, DateTime.utc(2026, 11, 18, 6, 12));
  });

  test('a transaction without a receipt has none', () async {
    final id = await ledger.record(
      TransactionDraft.expense(
        accountId: card.id,
        allocations: [Allocation(categoryId: food.id, amount: rub(37000))],
        occurredOn: CivilDate(2026, 11, 18),
      ),
    );
    expect((await ledger.watchTransaction(id).first)!.receipt, isNull);
  });

  test(
    'the same receipt is found, another one and a deleted one are not',
    () async {
      final id = await ledger.record(fromReceipt(groceries));
      expect((await ledger.transactionOfReceipt(groceries))?.id, id);
      const another = Receipt(
        drive: '7380440700076541',
        document: '24612',
        sign: '1190263553',
        kind: ReceiptKind.sale,
      );
      expect(await ledger.transactionOfReceipt(another), isNull);
      await ledger.delete(id);
      expect(await ledger.transactionOfReceipt(groceries), isNull);
    },
  );

  test('a till gives its latest transaction', () async {
    await ledger.record(
      fromReceipt(groceries, day: CivilDate(2026, 11, 16), note: 'Хлеб'),
    );
    final latest = await ledger.record(
      fromReceipt(
        const Receipt(
          drive: '7380440700076541',
          document: '24700',
          sign: '3301772001',
          kind: ReceiptKind.sale,
        ),
        note: 'Продукты у дома',
      ),
    );
    final till = await ledger.lastOfTill('7380440700076541');
    expect(till?.id, latest);
    expect(till?.note, 'Продукты у дома');
    expect(await ledger.lastOfTill('9999078900012345'), isNull);
  });

  test('an amended transaction keeps the receipt its draft brings', () async {
    final id = await ledger.record(fromReceipt(groceries));
    await ledger.amend(id, fromReceipt(groceries, amount: 61990));
    final amended = await ledger.watchTransaction(id).first;
    expect(amended!.receipt, groceries);
    expect(amended.entries.single.amount, rub(-61990));
  });

  test('a copy carries the receipt there and back', () async {
    await ledger.record(fromReceipt(groceries));
    final copy = LedgerCopy.parse((await ledger.copy()).encode());
    final json = jsonDecode(copy.encode()) as Map<String, Object?>;
    expect(json['version'], 11);
    final restoredDatabase = BirkaDatabase(NativeDatabase.memory());
    addTearDown(restoredDatabase.close);
    final restored = LedgerRepository(restoredDatabase);
    await restored.restore(copy);
    final transaction =
        (await restored.watchTransactions(limit: null).first).single;
    expect(transaction.receipt, groceries);
    expect(transaction.source, TransactionSource.receipt);
  });

  test('a copy of an older version restores without receipts', () async {
    await ledger.record(fromReceipt(groceries));
    final json =
        jsonDecode((await ledger.copy()).encode()) as Map<String, Object?>;
    json['version'] = 10;
    for (final transaction in json['transactions']! as List<Object?>) {
      (transaction! as Map<String, Object?>)
        ..remove('receipt')
        ..['source'] = 'manual';
    }
    final restoredDatabase = BirkaDatabase(NativeDatabase.memory());
    addTearDown(restoredDatabase.close);
    final restored = LedgerRepository(restoredDatabase);
    await restored.restore(LedgerCopy.parse(jsonEncode(json)));
    final transaction =
        (await restored.watchTransactions(limit: null).first).single;
    expect(transaction.receipt, isNull);
  });

  test('a receipt of an unknown kind damages the copy', () async {
    await ledger.record(fromReceipt(groceries));
    final json =
        jsonDecode((await ledger.copy()).encode()) as Map<String, Object?>;
    final transaction =
        (json['transactions']! as List<Object?>).single!
            as Map<String, Object?>;
    (transaction['receipt']! as Map<String, Object?>)['kind'] = 'gift';
    expect(
      () => LedgerCopy.parse(jsonEncode(json)),
      throwsA(isA<LedgerCopyException>()),
    );
  });

  test('a receipt kind tells spending from income', () {
    expect(ReceiptKind.sale.spends, isTrue);
    expect(ReceiptKind.payoutReturn.spends, isTrue);
    expect(ReceiptKind.saleReturn.spends, isFalse);
    expect(ReceiptKind.payout.spends, isFalse);
  });
}
