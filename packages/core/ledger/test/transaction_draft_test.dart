import 'dart:math';

import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
Money eur(int minorUnits) => Money(minorUnits, Currency.eur);

Allocation part(String categoryId, Money amount) =>
    Allocation(categoryId: categoryId, amount: amount);

void main() {
  final today = CivilDate(2026, 10, 30);

  group('expense', () {
    test('is one negative entry of the sum of its allocations', () {
      final draft = TransactionDraft.expense(
        accountId: 'card',
        allocations: [part('cafe', rub(25000)), part('food', rub(12000))],
        occurredOn: today,
      );

      expect(draft.kind, TransactionKind.expense);
      expect(draft.entries.single.accountId, 'card');
      expect(draft.entries.single.amount, rub(-37000));
      expect(draft.allocations, hasLength(2));
    });

    test('needs a category', () {
      expect(
        () => TransactionDraft.expense(
          accountId: 'card',
          allocations: const [],
          occurredOn: today,
        ),
        throwsArgumentError,
      );
    });

    test('needs positive allocations', () {
      for (final amount in [rub(0), rub(-100)]) {
        expect(
          () => TransactionDraft.expense(
            accountId: 'card',
            allocations: [part('cafe', amount)],
            occurredOn: today,
          ),
          throwsArgumentError,
        );
      }
    });

    test('keeps to one currency', () {
      expect(
        () => TransactionDraft.expense(
          accountId: 'card',
          allocations: [part('cafe', rub(100)), part('food', eur(100))],
          occurredOn: today,
        ),
        throwsArgumentError,
      );
    });

    test('allocations always add up to the entry', () {
      final random = Random(20261030);
      for (var i = 0; i < 1000; i++) {
        final amounts = [
          for (var part = random.nextInt(5); part >= 0; part--)
            rub(1 + random.nextInt(1 << 30)),
        ];
        final draft = TransactionDraft.expense(
          accountId: 'card',
          allocations: [for (final amount in amounts) part('cafe', amount)],
          occurredOn: today,
        );

        final total = draft.allocations.fold(
          rub(0),
          (sum, allocation) => sum + allocation.amount,
        );
        expect(draft.entries.single.amount, -total);
      }
    });
  });

  test('income is one positive entry of the sum of its allocations', () {
    final draft = TransactionDraft.income(
      accountId: 'card',
      allocations: [part('salary', rub(21000000))],
      occurredOn: today,
    );

    expect(draft.kind, TransactionKind.income);
    expect(draft.entries.single.amount, rub(21000000));
  });

  group('transfer', () {
    test('in one currency moves the same amount', () {
      final draft = TransactionDraft.transfer(
        fromAccountId: 'card',
        sent: rub(50000),
        toAccountId: 'savings',
        received: rub(50000),
        occurredOn: today,
      );

      expect(draft.kind, TransactionKind.transfer);
      expect(draft.allocations, isEmpty);
      expect(draft.entries[0].accountId, 'card');
      expect(draft.entries[0].amount, rub(-50000));
      expect(draft.entries[1].accountId, 'savings');
      expect(draft.entries[1].amount, rub(50000));
    });

    test('between currencies keeps both amounts as they happened', () {
      final draft = TransactionDraft.transfer(
        fromAccountId: 'card',
        sent: rub(10000000),
        toAccountId: 'euro',
        received: eur(100123),
        occurredOn: today,
      );

      expect(draft.entries[0].amount, rub(-10000000));
      expect(draft.entries[1].amount, eur(100123));
    });

    test('needs two different accounts', () {
      expect(
        () => TransactionDraft.transfer(
          fromAccountId: 'card',
          sent: rub(100),
          toAccountId: 'card',
          received: rub(100),
          occurredOn: today,
        ),
        throwsArgumentError,
      );
    });

    test('needs positive amounts', () {
      expect(
        () => TransactionDraft.transfer(
          fromAccountId: 'card',
          sent: rub(-100),
          toAccountId: 'savings',
          received: rub(100),
          occurredOn: today,
        ),
        throwsArgumentError,
      );
    });

    test('in one currency cannot change the amount', () {
      expect(
        () => TransactionDraft.transfer(
          fromAccountId: 'card',
          sent: rub(100),
          toAccountId: 'savings',
          received: rub(99),
          occurredOn: today,
        ),
        throwsArgumentError,
      );
    });
  });

  group('adjustment', () {
    test('is one entry without categories, up or down', () {
      for (final change in [rub(500), rub(-500)]) {
        final draft = TransactionDraft.adjustment(
          accountId: 'cash',
          change: change,
          occurredOn: today,
        );

        expect(draft.kind, TransactionKind.adjustment);
        expect(draft.entries.single.amount, change);
        expect(draft.allocations, isEmpty);
      }
    });

    test('has to change something', () {
      expect(
        () => TransactionDraft.adjustment(
          accountId: 'cash',
          change: rub(0),
          occurredOn: today,
        ),
        throwsArgumentError,
      );
    });
  });
}
