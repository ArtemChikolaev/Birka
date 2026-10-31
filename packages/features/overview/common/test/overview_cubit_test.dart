import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:overview_common/overview_common.dart';
import 'package:test/test.dart';

import 'fake_overview_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);

  late FakeOverviewRepository repository;
  late DateTime now;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<OverviewCubit> open() async {
    final cubit = OverviewCubit(repository, now: () => now);
    addTearDown(cubit.close);
    await settle();
    return cubit;
  }

  setUp(() {
    now = DateTime(2026, 10, 31, 9, 30);
    repository = FakeOverviewRepository(
      accounts: [
        testBalance('card', rub(100000)),
        testBalance('euro', eur(5000)),
      ],
      changes: [
        DayChange(CivilDate(2026, 9, 20), rub(1000)),
        DayChange(CivilDate(2026, 10, 10), rub(4000)),
        DayChange(CivilDate(2026, 10, 30), rub(-500)),
        DayChange(CivilDate(2026, 10, 30), eur(100)),
      ],
      spending: [testTotal('Food', rub(500))],
    );
  });

  test('is ready with the capital of each currency', () async {
    final overview = await open();

    expect(overview.state.status, OverviewStatus.ready);
    expect(overview.state.main, rub(100000));
    expect(overview.state.others, [eur(5000)]);
    expect(overview.state.today, CivilDate(2026, 10, 31));
  });

  test('reads a year of history and the month so far', () async {
    await open();

    expect(repository.changesFrom, CivilDate(2025, 10, 31));
    expect(repository.spendingFrom.single, CivilDate(2026, 10, 1));
    expect(repository.spendingTo, CivilDate(2026, 10, 31));
  });

  test('stays loading until everything has spoken', () async {
    final cubit = OverviewCubit(repository, now: () => now);
    addTearDown(cubit.close);
    final seen = <OverviewStatus>[];
    final subscription = cubit.stream.listen(
      (state) => seen.add(state.status),
    );
    addTearDown(subscription.cancel);
    await settle();

    expect(seen, [
      OverviewStatus.loading,
      OverviewStatus.loading,
      OverviewStatus.ready,
    ]);
  });

  test('the change follows the period', () async {
    final overview = await open();

    expect(overview.state.period, OverviewPeriod.month);
    expect(overview.state.change, rub(3500));
    expect(overview.state.history, hasLength(32));
    expect(overview.state.history.last, 100000);

    overview.periodChanged(OverviewPeriod.week);
    expect(overview.state.change, rub(-500));
    expect(overview.state.history, hasLength(8));

    overview.periodChanged(OverviewPeriod.year);
    expect(overview.state.change, rub(4500));
    expect(overview.state.history, hasLength(366));
  });

  test('follows the currency of the first account', () async {
    repository.accounts = [
      testBalance('euro', eur(5000)),
      testBalance('card', rub(100000)),
    ];
    final overview = await open();

    expect(overview.state.main, eur(5000));
    expect(overview.state.change, eur(100));
  });

  test('prefers the spending in the main currency', () async {
    repository.spending = [
      testTotal('Food', eur(9000)),
      testTotal('Cafe', rub(1)),
    ];
    final overview = await open();

    expect(overview.state.spending.total, rub(1));
    expect(overview.state.spending.others, [eur(9000)]);
  });

  test('without accounts there is nothing to chart', () async {
    repository.accounts = const [];
    final overview = await open();

    expect(overview.state.status, OverviewStatus.ready);
    expect(overview.state.main, isNull);
    expect(overview.state.history, isEmpty);
    expect(overview.state.change, isNull);
  });

  test('follows the ledger', () async {
    final overview = await open();

    repository
      ..accounts = [testBalance('card', rub(7))]
      ..changed();
    await settle();

    expect(overview.state.main, rub(7));
    expect(overview.state.others, isEmpty);
  });

  test('reports a failure and reads again', () async {
    repository.readFailure = Exception('disk');
    final overview = await open();
    expect(overview.state.status, OverviewStatus.failed);

    repository.readFailure = null;
    await overview.retry();
    await settle();

    expect(overview.state.status, OverviewStatus.ready);
    expect(overview.state.main, rub(100000));
  });

  test('a failure stays when the others speak after it', () async {
    final overview = await open();

    repository.breakAccounts(Exception('disk'));
    await settle();
    expect(overview.state.status, OverviewStatus.failed);

    repository.changedOthers();
    await settle();
    expect(overview.state.status, OverviewStatus.failed);

    repository.changed();
    await settle();
    expect(overview.state.status, OverviewStatus.ready);
  });

  test('stays ready through a later change of the period', () async {
    final overview = await open();

    overview.periodChanged(OverviewPeriod.year);

    expect(overview.state.status, OverviewStatus.ready);
  });

  group('after a night', () {
    test('the same day changes nothing', () async {
      final overview = await open();
      final before = overview.state;

      await overview.calendarChecked();

      expect(overview.state, same(before));
    });

    test('a new day moves the history and the month', () async {
      final overview = await open();
      now = DateTime(2026, 11, 1, 8);

      await overview.calendarChecked();
      await settle();

      expect(overview.state.today, CivilDate(2026, 11, 1));
      expect(repository.spendingFrom.last, CivilDate(2026, 11, 1));
      expect(repository.spendingTo, CivilDate(2026, 11, 1));
      expect(repository.changesFrom, CivilDate(2025, 11, 1));
      expect(overview.state.status, OverviewStatus.ready);
    });
  });
}
