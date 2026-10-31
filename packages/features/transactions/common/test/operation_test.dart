import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';
import 'package:transactions_common/transactions_common.dart';

import 'fake_transactions_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);
  final card = testAccount('Карта');
  final euro = testAccount('Евро', currency: Currency.eur);
  final cafe = testCategory('Кафе');

  group('an operation', () {
    test('finds what its transaction names', () {
      final transaction = testOperation(
        't',
        amount: rub(-100),
        account: card,
        category: cafe,
      ).transaction;

      final operation = Operation.of(
        transaction,
        accounts: {card.id: card, euro.id: euro},
        categories: {cafe.id: cafe},
      );

      expect(operation.account, card);
      expect(operation.toAccount, isNull);
      expect(operation.category, cafe);
      expect(operation.amount, rub(-100));
      expect(operation.received, isNull);
    });

    test('of a transfer knows both accounts and both amounts', () {
      final transaction = testOperation(
        't',
        amount: rub(-90000),
        account: card,
        toAccount: euro,
        received: eur(1000),
        kind: TransactionKind.transfer,
      ).transaction;

      final operation = Operation.of(
        transaction,
        accounts: {card.id: card, euro.id: euro},
        categories: const {},
      );

      expect(operation.account, card);
      expect(operation.toAccount, euro);
      expect(operation.category, isNull);
      expect(operation.amount, rub(-90000));
      expect(operation.received, eur(1000));
    });

    test('counts only money spent or earned that has happened', () {
      expect(testOperation('e', amount: rub(-1)).counts, isTrue);
      expect(testOperation('i', amount: rub(1)).counts, isTrue);
      expect(
        testOperation(
          't',
          amount: rub(-1),
          toAccount: euro,
          kind: TransactionKind.transfer,
        ).counts,
        isFalse,
      );
      expect(
        testOperation(
          'a',
          amount: rub(1),
          kind: TransactionKind.adjustment,
        ).counts,
        isFalse,
      );
      expect(
        testOperation(
          'p',
          amount: rub(-1),
          status: TransactionStatus.planned,
        ).counts,
        isFalse,
      );
    });

    test('can be changed unless quick add could not show it all', () {
      expect(testOperation('e', amount: rub(-1)).canChange, isTrue);
      expect(
        testOperation(
          'a',
          amount: rub(1),
          kind: TransactionKind.adjustment,
        ).canChange,
        isFalse,
      );
      final split = Operation(
        transaction: Transaction(
          id: 's',
          kind: TransactionKind.expense,
          occurredOn: CivilDate(2026, 10, 31),
          note: '',
          status: TransactionStatus.cleared,
          source: TransactionSource.manual,
          entries: [Entry(accountId: 'card', amount: rub(-3))],
          allocations: [
            Allocation(categoryId: 'a', amount: rub(1)),
            Allocation(categoryId: 'b', amount: rub(2)),
          ],
        ),
      );
      expect(split.canChange, isFalse);
    });
  });

  group('the search', () {
    final lunch = testOperation(
      't',
      amount: rub(-25050),
      account: card,
      category: cafe,
      note: 'Обед с Алёной',
    );

    test('takes everything when empty', () {
      expect(lunch.matches(''), isTrue);
      expect(lunch.matches('   '), isTrue);
    });

    test('looks at the note and the names', () {
      expect(lunch.matches('обед'), isTrue);
      expect(lunch.matches('кафе'), isTrue);
      expect(lunch.matches('карта'), isTrue);
      expect(lunch.matches('такси'), isFalse);
    });

    test('ignores case and the letter ё', () {
      expect(lunch.matches('ОБЕД'), isTrue);
      expect(lunch.matches('ален'), isTrue);
      expect(lunch.matches('алён'), isTrue);
    });

    test('takes the whole part of an amount', () {
      expect(lunch.matches('250'), isTrue);
      expect(lunch.matches('25'), isFalse);
      expect(lunch.matches('2505'), isFalse);
    });

    test('takes a fraction with either mark', () {
      expect(lunch.matches('250,5'), isTrue);
      expect(lunch.matches('250.50'), isTrue);
      expect(lunch.matches('250,4'), isFalse);
    });

    test('needs every word', () {
      expect(lunch.matches('кафе 250'), isTrue);
      expect(lunch.matches('кафе 300'), isFalse);
    });

    test('sees both sides of a transfer', () {
      final transfer = testOperation(
        't',
        amount: rub(-90000),
        account: card,
        toAccount: euro,
        received: eur(1000),
        kind: TransactionKind.transfer,
      );

      expect(transfer.matches('евро'), isTrue);
      expect(transfer.matches('900'), isTrue);
      expect(transfer.matches('10'), isTrue);
    });
  });

  group('days', () {
    final today = CivilDate(2026, 10, 31);
    final yesterday = CivilDate(2026, 10, 30);

    test('group operations and keep their order', () {
      final days = groupByDay([
        testOperation('a', amount: rub(-1), day: today),
        testOperation('b', amount: rub(-2), day: today),
        testOperation('c', amount: rub(-3), day: yesterday),
      ]);

      expect(days.map((it) => it.day), [today, yesterday]);
      expect(days.first.operations.map((it) => it.id), ['a', 'b']);
    });

    test('come to what was spent and earned', () {
      final day = OperationDay(today, [
        testOperation('a', amount: rub(-250)),
        testOperation('b', amount: rub(1000)),
        testOperation('c', amount: eur(-5)),
        testOperation(
          'd',
          amount: rub(-100000),
          toAccount: card,
          kind: TransactionKind.transfer,
        ),
      ]);

      expect(day.total, [rub(750), eur(-5)]);
    });
  });

  group('a sum', () {
    test('keeps currencies apart in the order they came', () {
      expect(sumByCurrency([eur(1), rub(2), eur(3)]), [eur(4), rub(2)]);
    });

    test('of zero is left out', () {
      expect(sumByCurrency([rub(5), rub(-5), eur(1)]), [eur(1)]);
    });

    test('stops at the limit instead of breaking the list', () {
      final most = Money(Money.maxMinorUnits, Currency.rub);

      expect(sumByCurrency([most, most]), [most]);
      expect(sumByCurrency([-most, -most]), [-most]);
    });
  });
}
