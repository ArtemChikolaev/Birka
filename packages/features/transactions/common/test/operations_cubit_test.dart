import 'package:money/money.dart';
import 'package:test/test.dart';
import 'package:transactions_common/transactions_common.dart';

import 'fake_transactions_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);
  final october = CivilDate(2026, 10, 1);
  final september = CivilDate(2026, 9, 1);
  final card = testAccount('card');
  final cafe = testCategory('cafe');

  late FakeTransactionsRepository repository;
  late DateTime now;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<OperationsCubit> open() async {
    final cubit = OperationsCubit(repository, now: () => now);
    addTearDown(cubit.close);
    await settle();
    return cubit;
  }

  setUp(() {
    now = DateTime(2026, 10, 31, 9, 30);
    repository = FakeTransactionsRepository(
      operations: [
        testOperation(
          'coffee',
          amount: rub(-25000),
          account: card,
          category: cafe,
          note: 'Coffee',
        ),
        testOperation(
          'pay',
          amount: rub(10000000),
          account: card,
          day: CivilDate(2026, 10, 30),
        ),
        testOperation(
          'move',
          amount: rub(-90000),
          account: card,
          toAccount: testAccount('euro', currency: Currency.eur),
          received: eur(1000),
          kind: TransactionKind.transfer,
          day: CivilDate(2026, 10, 30),
        ),
        testOperation(
          'old',
          amount: rub(-100),
          account: card,
          day: CivilDate(2026, 9, 15),
        ),
      ],
    );
  });

  test('opens on the current month, day by day', () async {
    final list = await open();

    expect(list.state.status, OperationsStatus.ready);
    expect(list.state.today, CivilDate(2026, 10, 31));
    expect(list.state.month, october);
    expect(list.state.days.map((day) => day.operations.length), [1, 2]);
    expect(list.state.expenses, [rub(-25000)]);
    expect(list.state.income, [rub(10000000)]);
  });

  test('follows the ledger', () async {
    final list = await open();

    repository.operations = repository.operations.skip(1).toList();
    await settle();

    expect(list.state.expenses, isEmpty);
  });

  test('a filter narrows the days and the totals', () async {
    final list = await open();

    list.filterChanged(OperationsFilter.income);
    expect(list.state.shown.single.id, 'pay');
    expect(list.state.expenses, isEmpty);
    expect(list.state.income, [rub(10000000)]);
    expect(list.state.isNarrowed, isTrue);

    list.filterChanged(OperationsFilter.transfers);
    expect(list.state.shown.single.id, 'move');
    expect(list.state.days.single.total, isEmpty);

    list.filterChanged(OperationsFilter.expenses);
    expect(list.state.shown.single.id, 'coffee');
  });

  test('the search narrows them too', () async {
    final list = await open();

    list.queryChanged('coffee');
    expect(list.state.shown.single.id, 'coffee');
    expect(list.state.isNarrowed, isTrue);

    list.queryChanged('');
    expect(list.state.shown, hasLength(3));
    expect(list.state.isNarrowed, isFalse);
  });

  test('another month follows that month', () async {
    final list = await open();

    await list.monthChanged(september);
    expect(list.state.month, september);
    await settle();

    expect(list.state.shown.single.id, 'old');
    repository.operations = const [];
    await settle();
    expect(list.state.shown, isEmpty);
  });

  test('the same month is not read again', () async {
    final list = await open();

    await list.monthChanged(october);

    expect(repository.followed, [october]);
    expect(list.state.status, OperationsStatus.ready);
  });

  test('offers the current month and those with operations', () async {
    repository.monthList = [september, CivilDate(2025, 12, 1)];
    final list = await open();

    expect(await list.months(), [october, september, CivilDate(2025, 12, 1)]);

    repository.monthList = [october, september];
    expect(await list.months(), [october, september]);
  });

  test('still offers the months it knows when it cannot read them', () async {
    final list = await open();
    await list.monthChanged(september);
    await settle();

    repository.readFailure = Exception('disk');

    expect(await list.months(), [october, september]);
  });

  test('reports a failure and reads again', () async {
    repository.readFailure = Exception('disk');
    final list = await open();
    expect(list.state.status, OperationsStatus.failed);

    repository.readFailure = null;
    await list.retry();
    await settle();

    expect(list.state.status, OperationsStatus.ready);
    expect(list.state.shown, hasLength(3));
  });

  test('a failure while following says so', () async {
    final list = await open();

    repository.breakOperations(Exception('disk'));
    await settle();

    expect(list.state.status, OperationsStatus.failed);
  });

  test('deletes, and the ledger takes the row away', () async {
    final list = await open();

    await list.delete('coffee');
    await settle();

    expect(list.state.shown.map((it) => it.id), ['pay', 'move']);
    expect(list.state.deleteFailed, isFalse);
  });

  test('a failed delete says so until the next change', () async {
    repository.failure = Exception('disk full');
    final list = await open();

    await list.delete('coffee');
    expect(list.state.deleteFailed, isTrue);
    expect(list.state.shown, hasLength(3));

    list.queryChanged('c');
    expect(list.state.deleteFailed, isFalse);
  });

  test('closing during a delete stays quiet', () async {
    repository.failure = Exception('disk full');
    final list = await open();

    final deleting = list.delete('coffee');
    await list.close();

    await expectLater(deleting, completes);
  });

  group('after a night', () {
    test('the same day changes nothing', () async {
      final list = await open();
      final before = list.state;

      await list.calendarChecked();

      expect(list.state, same(before));
    });

    test('the next day moves today', () async {
      final list = await open();
      now = DateTime(2026, 11, 1, 8);

      await list.calendarChecked();
      await settle();

      expect(list.state.today, CivilDate(2026, 11, 1));
      expect(list.state.month, CivilDate(2026, 11, 1));
    });

    test('a list on an older month stays there', () async {
      final list = await open();
      await list.monthChanged(september);
      await settle();
      now = DateTime(2026, 11, 1, 8);

      await list.calendarChecked();

      expect(list.state.today, CivilDate(2026, 11, 1));
      expect(list.state.month, september);
    });
  });
}
