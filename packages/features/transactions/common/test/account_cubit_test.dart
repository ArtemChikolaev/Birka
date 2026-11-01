import 'package:money/money.dart';
import 'package:test/test.dart';
import 'package:transactions_common/transactions_common.dart';

import 'fake_transactions_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final card = testAccount('card');
  final cash = testAccount('cash');

  late FakeTransactionsRepository repository;
  late DateTime now;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<AccountCubit> open([String id = 'card']) async {
    final cubit = AccountCubit(repository, id, now: () => now);
    addTearDown(cubit.close);
    await settle();
    return cubit;
  }

  setUp(() {
    now = DateTime(2026, 10, 31, 9, 30);
    repository =
        FakeTransactionsRepository(
            operations: [
              testOperation('coffee', amount: rub(-250), account: card),
              testOperation(
                'pay',
                amount: rub(1000),
                account: card,
                day: CivilDate(2026, 10, 30),
              ),
              testOperation('other', amount: rub(-5), account: cash),
            ],
          )
          ..balances = [AccountBalance(card, rub(5000))]
          ..dayChanges = [
            DayChange(CivilDate(2026, 9, 15), rub(300)),
            DayChange(CivilDate(2026, 10, 30), rub(1000)),
            DayChange(CivilDate(2026, 10, 31), rub(-250)),
          ];
  });

  test('starts by loading', () {
    final cubit = AccountCubit(repository, 'card', now: () => now);
    addTearDown(cubit.close);

    expect(cubit.state.status, AccountStatus.loading);
    expect(cubit.state.period, ChartPeriod.month);
  });

  test('shows the account with its operations, day by day', () async {
    final cubit = await open();

    expect(cubit.state.status, AccountStatus.ready);
    expect(cubit.state.account?.balance, rub(5000));
    expect(cubit.state.operations.map((it) => it.id), ['coffee', 'pay']);
    expect(cubit.state.days.map((it) => it.day.day), [31, 30]);
  });

  test('draws the balance of the month, up to what it holds now', () async {
    final cubit = await open();

    final history = cubit.state.history;
    expect(history, hasLength(32));
    expect(history.last, 5000);
    expect(history[history.length - 2], 5250);
    expect(history[history.length - 3], 4250);
    expect(history.first, 4250);
  });

  test('says what the period changed', () async {
    final cubit = await open();

    expect(cubit.state.change, rub(750));
  });

  test('looks further back with another period', () async {
    final cubit = await open();

    cubit.periodChanged(ChartPeriod.year);

    expect(cubit.state.history, hasLength(366));
    expect(cubit.state.change, rub(1050));
  });

  test('looks back a week', () async {
    final cubit = await open();

    cubit.periodChanged(ChartPeriod.week);

    expect(cubit.state.history, hasLength(8));
  });

  test('follows a new operation', () async {
    final cubit = await open();

    repository
      ..balances = [AccountBalance(card, rub(4000))]
      ..operations = [
        testOperation('rent', amount: rub(-1000), account: card),
        ...repository.operations,
      ];
    await settle();

    expect(cubit.state.account?.balance, rub(4000));
    expect(cubit.state.operations.first.id, 'rent');
  });

  test('says when there is no such account', () async {
    final cubit = await open('nothing');

    expect(cubit.state.status, AccountStatus.gone);
  });

  test('stays gone when the other sources speak', () async {
    final cubit = await open('nothing');

    repository.touch();
    await settle();

    expect(cubit.state.status, AccountStatus.gone);
  });

  test('says when it cannot read, and reads again', () async {
    repository.readFailure = Exception('disk');
    final cubit = await open();
    expect(cubit.state.status, AccountStatus.failed);

    repository.readFailure = null;
    await cubit.retry();
    await settle();

    expect(cubit.state.status, AccountStatus.ready);
  });

  test('deletes an operation', () async {
    final cubit = await open();

    await cubit.delete('coffee');
    await settle();

    expect(cubit.state.operations.map((it) => it.id), ['pay']);
    expect(cubit.state.deleteFailed, isFalse);
  });

  test('says when a delete failed', () async {
    final cubit = await open();
    repository.failure = Exception('disk');

    await cubit.delete('coffee');

    expect(cubit.state.deleteFailed, isTrue);
  });

  test('moves on with the calendar', () async {
    final cubit = await open();
    now = DateTime(2026, 11, 1, 8);

    await cubit.calendarChecked();
    await settle();

    expect(cubit.state.today, CivilDate(2026, 11, 1));
    expect(cubit.state.history, hasLength(2));
    expect(cubit.state.status, AccountStatus.ready);
  });

  test('stays where it is on the same day', () async {
    final cubit = await open();
    now = DateTime(2026, 10, 31, 23);

    await cubit.calendarChecked();

    expect(cubit.state.status, AccountStatus.ready);
  });
}
