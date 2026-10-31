import 'dart:async';

import 'package:ledger/ledger.dart' show TransactionSource, TransactionStatus;
import 'package:money/money.dart';
import 'package:test/test.dart';
import 'package:transactions_common/transactions_common.dart';

import 'fake_transactions_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final now = DateTime(2026, 10, 31, 9, 30);
  final today = CivilDate(2026, 10, 31);
  final yesterday = CivilDate(2026, 10, 30);

  late FakeTransactionsRepository repository;

  Future<QuickAddCubit> open() async {
    final cubit = QuickAddCubit(repository, now: () => now);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  void type(QuickAddCubit cubit, String digits) {
    for (final digit in digits.split('')) {
      cubit.digitTyped(int.parse(digit));
    }
  }

  setUp(() {
    repository = FakeTransactionsRepository(
      accountList: [
        testAccount('card'),
        testAccount('cash'),
        testAccount('euro', currency: Currency.eur),
      ],
      expenses: [testCategory('food'), testCategory('cafe')],
      income: [testCategory('salary', kind: CategoryKind.income)],
    );
  });

  group('opening', () {
    test('starts on an expense today, on the first account', () async {
      final form = await open();

      expect(form.state.status, QuickAddStatus.editing);
      expect(form.state.kind, TransactionKind.expense);
      expect(form.state.day, today);
      expect(form.state.yesterday, yesterday);
      expect(form.state.account?.id, 'card');
    });

    test('takes the account of the latest transaction', () async {
      repository.last = 'cash';
      expect((await open()).state.account?.id, 'cash');
    });

    test('skips an account that is no longer there', () async {
      repository.last = 'closed';
      expect((await open()).state.account?.id, 'card');
    });

    test('knows the day before the first of a month', () async {
      final cubit = QuickAddCubit(repository, now: () => DateTime(2026, 11));
      addTearDown(cubit.close);
      expect(cubit.state.yesterday, CivilDate(2026, 10, 31));
    });

    test('reports choices it cannot read', () async {
      repository.readFailure = Exception('disk');
      expect((await open()).state.status, QuickAddStatus.failedToRead);
    });

    test('reading again gets past a failure', () async {
      repository.readFailure = Exception('disk');
      final form = await open();

      repository.readFailure = null;
      await form.refresh();

      expect(form.state.status, QuickAddStatus.editing);
      expect(form.state.account?.id, 'card');
    });

    test('reading again finds a new account and keeps the choice', () async {
      final form = await open();
      form.accountChanged('cash');
      repository.accountList = [
        ...repository.accountList,
        testAccount('new'),
      ];

      await form.refresh();

      expect(form.state.accounts, hasLength(4));
      expect(form.state.account?.id, 'cash');
    });
  });

  group('the amount', () {
    test('adds up what was typed', () async {
      final form = await open();
      type(form, '250');
      form.operatorTyped(AmountOperator.add);
      type(form, '120');

      expect(form.state.amount, rub(37000));
      expect(form.state.editing.hasOperators, isTrue);
    });

    test('takes the point and goes back', () async {
      final form = await open();
      type(form, '12');
      form.pointTyped();
      type(form, '5');
      form
        ..backspaceTyped()
        ..backspaceTyped();

      expect(form.state.amount, rub(1200));
    });

    test('follows the digits of the currency of the account', () async {
      repository.accountList = [
        testAccount('yen', currency: Currency.iso('JPY')),
      ];
      final form = await open();
      type(form, '5');
      form.pointTyped();
      type(form, '5');

      expect(form.state.amount, Money(55, Currency.iso('JPY')));
    });
  });

  group('saving', () {
    test('an expense needs an amount and a category', () async {
      final form = await open();
      expect(form.state.canSave, isFalse);

      type(form, '250');
      expect(form.state.canSave, isFalse);

      form.categoryChanged('cafe');
      expect(form.state.canSave, isTrue);
    });

    test('an amount of zero or below cannot be saved', () async {
      final form = await open();
      form.categoryChanged('cafe');
      type(form, '0');
      expect(form.state.canSave, isFalse);

      form
        ..backspaceTyped()
        ..digitTyped(5)
        ..operatorTyped(AmountOperator.subtract)
        ..digitTyped(9);
      expect(form.state.canSave, isFalse);
    });

    test('a division by zero cannot be saved', () async {
      final form = await open();
      form.categoryChanged('cafe');
      type(form, '5');
      form.operatorTyped(AmountOperator.divide);
      type(form, '0');
      expect(form.state.amount, isNull);
      expect(form.state.canSave, isFalse);
    });

    test('records an expense of today with the moment', () async {
      final form = await open();
      type(form, '250');
      form
        ..categoryChanged('cafe')
        ..noteChanged('  Coffee ');
      await form.save();

      expect(form.state.status, QuickAddStatus.saved);
      final draft = repository.recorded.single;
      expect(draft.kind, TransactionKind.expense);
      expect(draft.entries.single.accountId, 'card');
      expect(draft.entries.single.amount, rub(-25000));
      expect(draft.allocations.single.categoryId, 'cafe');
      expect(draft.occurredOn, today);
      expect(draft.occurredAt, now);
      expect(draft.note, 'Coffee');
    });

    test('an earlier day has no moment', () async {
      final form = await open();
      type(form, '250');
      form
        ..categoryChanged('cafe')
        ..dayChanged(yesterday);
      await form.save();

      final draft = repository.recorded.single;
      expect(draft.occurredOn, yesterday);
      expect(draft.occurredAt, isNull);
    });

    test('records an income with a category of income', () async {
      final form = await open();
      form.kindChanged(TransactionKind.income);
      type(form, '1000');
      form.categoryChanged('salary');
      await form.save();

      final draft = repository.recorded.single;
      expect(draft.kind, TransactionKind.income);
      expect(draft.entries.single.amount, rub(100000));
    });

    test('a new kind drops the category of the old one', () async {
      final form = await open();
      form
        ..categoryChanged('cafe')
        ..kindChanged(TransactionKind.income);

      expect(form.state.category, isNull);
      expect(form.state.categories.single.id, 'salary');
    });

    test('does nothing while a field is missing', () async {
      final form = await open();
      await form.save();

      expect(repository.recorded, isEmpty);
      expect(form.state.status, QuickAddStatus.editing);
    });

    test('a failed save stays open and can be repeated', () async {
      repository.failure = Exception('disk full');
      final form = await open();
      type(form, '250');
      form.categoryChanged('cafe');
      await form.save();
      expect(form.state.status, QuickAddStatus.failed);

      repository.failure = null;
      await form.save();
      expect(form.state.status, QuickAddStatus.saved);
      expect(repository.recorded, hasLength(1));
    });

    test('a second tap during a save writes once', () async {
      final write = repository.gate = Completer<void>();
      final form = await open();
      type(form, '250');
      form.categoryChanged('cafe');

      final first = form.save();
      expect(form.state.canSave, isFalse);
      await form.save();
      write.complete();
      await first;
      await form.save();

      expect(repository.recorded, hasLength(1));
    });

    test('closing during a save lets the write finish', () async {
      final write = repository.gate = Completer<void>();
      final form = await open();
      type(form, '250');
      form.categoryChanged('cafe');

      final saving = form.save();
      await form.close();
      write.complete();
      await saving;

      expect(repository.recorded, hasLength(1));
    });

    test('closing during a save that fails stays quiet', () async {
      final write = repository.gate = Completer<void>();
      repository.failure = Exception('disk full');
      final form = await open();
      type(form, '250');
      form.categoryChanged('cafe');

      final saving = form.save();
      await form.close();
      write.complete();
      await saving;

      expect(repository.recorded, isEmpty);
    });
  });

  group('changing an operation', () {
    final moment = DateTime(2026, 10, 30, 8, 42);
    final card = testAccount('card');
    final cafe = testCategory('cafe');

    Future<QuickAddCubit> edit(Operation operation) async {
      repository.operations = [operation];
      final cubit = QuickAddCubit(
        repository,
        now: () => now,
        source: QuickAddSource.edit(operation.id),
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);
      return cubit;
    }

    test('fills the sheet', () async {
      final form = await edit(
        testOperation(
          'coffee',
          amount: rub(-25050),
          account: repository.accountList[1],
          category: cafe,
          day: yesterday,
          note: 'Lunch',
        ),
      );

      expect(form.state.status, QuickAddStatus.editing);
      expect(form.state.changesExisting, isTrue);
      expect(form.state.kind, TransactionKind.expense);
      expect(form.state.amount, rub(25050));
      expect(form.state.account?.id, 'cash');
      expect(form.state.category?.id, 'cafe');
      expect(form.state.day, yesterday);
      expect(form.state.note, 'Lunch');
      expect(form.state.canSave, isTrue);
    });

    test('a save amends it and records nothing new', () async {
      final form = await edit(
        testOperation(
          'coffee',
          amount: rub(-25000),
          account: card,
          category: cafe,
          day: yesterday,
          at: moment,
        ),
      );

      form.digitTyped(0);
      await form.save();

      expect(form.state.status, QuickAddStatus.saved);
      expect(repository.recorded, isEmpty);
      final draft = repository.amended['coffee'];
      expect(draft?.entries.single.amount, rub(-250000));
      expect(draft?.occurredOn, yesterday);
      expect(draft?.occurredAt, moment);
    });

    test('keeps how far it has come and where it came from', () async {
      final form = await edit(
        testOperation(
          'coffee',
          amount: rub(-25000),
          account: card,
          category: cafe,
          status: TransactionStatus.reconciled,
          source: TransactionSource.bank,
        ),
      );

      await form.save();

      final draft = repository.amended['coffee'];
      expect(draft?.status, TransactionStatus.reconciled);
      expect(draft?.source, TransactionSource.bank);
    });

    test('a new day forgets the moment of the old one', () async {
      final form = await edit(
        testOperation(
          'coffee',
          amount: rub(-25000),
          account: card,
          category: cafe,
          day: yesterday,
          at: moment,
        ),
      );

      form.dayChanged(CivilDate(2026, 10, 1));
      await form.save();

      expect(repository.amended['coffee']?.occurredAt, isNull);
    });

    test('moved to today it takes the moment of now', () async {
      final form = await edit(
        testOperation(
          'coffee',
          amount: rub(-25000),
          account: card,
          category: cafe,
          day: yesterday,
          at: moment,
        ),
      );

      form.dayChanged(today);
      await form.save();

      expect(repository.amended['coffee']?.occurredAt, now);
    });

    test('keeps an archived account and category among the choices', () async {
      final closed = testAccount('closed');
      final old = testCategory('old');
      final form = await edit(
        testOperation(
          'coffee',
          amount: rub(-25000),
          account: closed,
          category: old,
        ),
      );

      expect(form.state.account, closed);
      expect(form.state.category, old);
      expect(form.state.canSave, isTrue);
    });

    test('of a transfer fills both sides', () async {
      final form = await edit(
        testOperation(
          'move',
          amount: rub(-900000),
          account: card,
          toAccount: repository.accountList.last,
          received: Money(10000, Currency.eur),
          kind: TransactionKind.transfer,
        ),
      );

      expect(form.state.needsTwoAmounts, isTrue);
      expect(form.state.amount, rub(900000));
      expect(form.state.receivedAmount, Money(10000, Currency.eur));
      await form.save();
      expect(repository.amended['move']?.entries.last.accountId, 'euro');
    });

    test('reading the choices again keeps what was typed', () async {
      final form = await edit(
        testOperation(
          'coffee',
          amount: rub(-25000),
          account: card,
          category: cafe,
        ),
      );

      form.noteChanged('Tea');
      await form.refresh();

      expect(form.state.note, 'Tea');
      expect(form.state.amount, rub(25000));
    });

    test('an operation that is gone leaves an empty sheet', () async {
      final form = QuickAddCubit(
        repository,
        now: () => now,
        source: const QuickAddSource.edit('missing'),
      );
      addTearDown(form.close);
      await Future<void>.delayed(Duration.zero);

      expect(form.state.status, QuickAddStatus.editing);
      expect(form.state.changesExisting, isFalse);
      expect(form.state.sent.isEmpty, isTrue);
    });

    test('an operation it cannot read can be tried again', () async {
      repository
        ..operations = [
          testOperation('coffee', amount: rub(-250), account: card),
        ]
        ..readFailure = Exception('disk');
      final form = QuickAddCubit(
        repository,
        now: () => now,
        source: const QuickAddSource.edit('coffee'),
      );
      addTearDown(form.close);
      await Future<void>.delayed(Duration.zero);
      expect(form.state.status, QuickAddStatus.failedToRead);

      repository.readFailure = null;
      await form.refresh();

      expect(form.state.status, QuickAddStatus.editing);
      expect(form.state.changesExisting, isTrue);
    });
  });

  group('repeating an operation', () {
    final cafe = testCategory('cafe');

    Future<QuickAddCubit> repeat(Operation operation) async {
      repository.operations = [operation];
      final cubit = QuickAddCubit(
        repository,
        now: () => now,
        source: QuickAddSource.repeat(operation.id),
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);
      return cubit;
    }

    test('fills all of it but the day, and adds a new one', () async {
      final form = await repeat(
        testOperation(
          'coffee',
          amount: rub(-25000),
          account: repository.accountList[1],
          category: cafe,
          day: CivilDate(2026, 10, 1),
          at: DateTime(2026, 10, 1, 8),
          note: 'Coffee',
        ),
      );

      expect(form.state.changesExisting, isFalse);
      expect(form.state.day, today);

      await form.save();

      expect(repository.amended, isEmpty);
      final draft = repository.recorded.single;
      expect(draft.entries.single.accountId, 'cash');
      expect(draft.entries.single.amount, rub(-25000));
      expect(draft.allocations.single.categoryId, 'cafe');
      expect(draft.occurredOn, today);
      expect(draft.occurredAt, now);
      expect(draft.note, 'Coffee');
    });

    test('leaves out what has been archived since', () async {
      final form = await repeat(
        testOperation(
          'coffee',
          amount: rub(-25000),
          account: testAccount('closed'),
          category: testCategory('old'),
        ),
      );

      expect(form.state.account?.id, 'card');
      expect(form.state.category, isNull);
      expect(form.state.canSave, isFalse);
    });
  });

  group('a transfer', () {
    test('needs an amount and a second account', () async {
      final form = await open();
      form.kindChanged(TransactionKind.transfer);
      type(form, '100');
      expect(form.state.canSave, isFalse);

      form.toAccountChanged('cash');
      expect(form.state.canSave, isTrue);
    });

    test('cannot go to the account it leaves', () async {
      final form = await open();
      form
        ..kindChanged(TransactionKind.transfer)
        ..toAccountChanged('cash')
        ..accountChanged('cash');

      expect(form.state.toAccount, isNull);
      expect(form.state.targets.map((account) => account.id), [
        'card',
        'euro',
      ]);
    });

    test('in one currency moves one amount', () async {
      final form = await open();
      form
        ..kindChanged(TransactionKind.transfer)
        ..toAccountChanged('cash');
      type(form, '100');
      await form.save();

      expect(form.state.needsTwoAmounts, isFalse);
      final [from, to] = repository.recorded.single.entries;
      expect(from.amount, rub(-10000));
      expect(to.amount, rub(10000));
    });

    test('between currencies keeps both amounts as typed', () async {
      final form = await open();
      form
        ..kindChanged(TransactionKind.transfer)
        ..toAccountChanged('euro');
      expect(form.state.needsTwoAmounts, isTrue);

      type(form, '10000');
      expect(form.state.canSave, isFalse);

      form.editingChanged(received: true);
      type(form, '100');
      expect(form.state.canSave, isTrue);
      await form.save();

      final [from, to] = repository.recorded.single.entries;
      expect(from.amount, rub(-1000000));
      expect(to.amount, Money(10000, Currency.eur));
    });

    test('the second amount waits while the currency is the same', () async {
      final form = await open();
      form
        ..kindChanged(TransactionKind.transfer)
        ..toAccountChanged('cash')
        ..editingChanged(received: true);
      type(form, '100');

      expect(form.state.amount, rub(10000));
      expect(form.state.received.isEmpty, isTrue);
    });
  });

  group('the categories on the sheet', () {
    List<Category> named(int count) => [
      for (var i = 0; i < count; i++) testCategory('c$i'),
    ];

    test('all of them fit up to eight', () async {
      repository.expenses = named(8);
      final form = await open();

      expect(form.state.hasMoreCategories, isFalse);
      expect(form.state.shown, hasLength(8));
    });

    test('nine leave seven and a way to the rest', () async {
      repository.expenses = named(9);
      final form = await open();

      expect(form.state.hasMoreCategories, isTrue);
      expect(form.state.shown, hasLength(7));
    });

    test('one picked from the rest takes the last place', () async {
      repository.expenses = named(10);
      final form = await open();
      form.categoryChanged('c9');

      expect(form.state.shown.map((category) => category.id), [
        'c0',
        'c1',
        'c2',
        'c3',
        'c4',
        'c5',
        'c9',
      ]);
    });
  });
}
