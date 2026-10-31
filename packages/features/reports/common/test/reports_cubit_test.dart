import 'package:reports_common/reports_common.dart';
import 'package:test/test.dart';

import 'fake_reports_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final october = CivilDate(2026, 10, 1);
  final september = CivilDate(2026, 9, 1);

  late FakeReportsRepository repository;
  late DateTime now;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<ReportsCubit> open() async {
    final cubit = ReportsCubit(repository, now: () => now);
    addTearDown(cubit.close);
    await settle();
    return cubit;
  }

  setUp(() {
    now = DateTime(2026, 10, 31, 9, 30);
    repository = FakeReportsRepository(main: Currency.rub);
    repository.totals[(CategoryKind.expense, october)] = [
      testTotal('Food', rub(1160)),
    ];
    repository.totals[(CategoryKind.expense, september)] = [
      testTotal('Food', rub(1000)),
    ];
    repository.totals[(CategoryKind.income, october)] = [
      testTotal('Salary', rub(9000)),
    ];
    repository.monthTotals[CategoryKind.expense] = [
      MonthTotal(september, rub(1000)),
      MonthTotal(october, rub(1160)),
    ];
  });

  test('opens on the expenses of the current month', () async {
    final reports = await open();

    expect(reports.state.status, ReportsStatus.ready);
    expect(reports.state.month, october);
    expect(reports.state.kind, CategoryKind.expense);
    expect(reports.state.report.total, rub(1160));
    expect(reports.state.report.change, 16);
    expect(reports.state.report.average, rub(1080));
  });

  test('reads the whole month and the one before', () async {
    await open();

    expect(repository.asked, [
      (CategoryKind.expense, october, CivilDate(2026, 10, 31)),
      (CategoryKind.expense, september, CivilDate(2026, 9, 30)),
    ]);
    expect(repository.askedMonths.single, (
      CivilDate(2026, 5, 1),
      CivilDate(2026, 10, 31),
    ));
  });

  group('a month under way', () {
    test('compares with the same days of the month before', () async {
      now = DateTime(2026, 10, 10);
      await open();

      expect(
        repository.asked.last,
        (CategoryKind.expense, september, CivilDate(2026, 9, 10)),
      );
    });

    test('stops at the end of a shorter month before', () async {
      now = DateTime(2026, 3, 30);
      await open();

      expect(
        repository.asked.last,
        (CategoryKind.expense, CivilDate(2026, 2, 1), CivilDate(2026, 2, 28)),
      );
    });

    test('a finished month compares with the whole one before', () async {
      now = DateTime(2026, 10, 10);
      final reports = await open();

      await reports.monthChanged(september);

      expect(
        repository.asked.last,
        (CategoryKind.expense, CivilDate(2026, 8, 1), CivilDate(2026, 8, 31)),
      );
    });
  });

  test('stays loading until everything has spoken', () async {
    final cubit = ReportsCubit(repository, now: () => now);
    addTearDown(cubit.close);
    final seen = <ReportsStatus>[];
    final subscription = cubit.stream.listen((state) => seen.add(state.status));
    addTearDown(subscription.cancel);
    await settle();

    expect(seen, [
      ReportsStatus.loading,
      ReportsStatus.loading,
      ReportsStatus.loading,
      ReportsStatus.ready,
    ]);
  });

  test('income is a click away', () async {
    final reports = await open();

    await reports.kindChanged(CategoryKind.income);
    await settle();

    expect(reports.state.kind, CategoryKind.income);
    expect(reports.state.report.total, rub(9000));
  });

  test('the same kind is not read again', () async {
    final reports = await open();

    await reports.kindChanged(CategoryKind.expense);

    expect(repository.asked, hasLength(2));
  });

  test('another month follows that month', () async {
    final reports = await open();

    await reports.monthChanged(september);
    await settle();

    expect(reports.state.month, september);
    expect(reports.state.report.total, rub(1000));
    expect(reports.state.report.change, isNull);
  });

  test('the same month is not read again', () async {
    final reports = await open();

    await reports.monthChanged(october);

    expect(repository.asked, hasLength(2));
  });

  test('clears the old month while the new one is on its way', () async {
    final reports = await open();

    final moving = reports.monthChanged(september);
    expect(reports.state.status, ReportsStatus.loading);
    expect(reports.state.rows, isEmpty);

    await moving;
  });

  test('follows the ledger', () async {
    final reports = await open();

    repository.totals[(CategoryKind.expense, october)] = [
      testTotal('Food', rub(2000)),
    ];
    repository.changed();
    await settle();

    expect(reports.state.report.total, rub(2000));
  });

  test('offers the current month and those with operations', () async {
    repository.monthList = [september, CivilDate(2025, 12, 1)];
    final reports = await open();

    expect(await reports.months(), [
      october,
      september,
      CivilDate(2025, 12, 1),
    ]);
  });

  test('still offers the months it knows when it cannot read them', () async {
    final reports = await open();
    await reports.monthChanged(september);
    await settle();

    repository.readFailure = Exception('disk');

    expect(await reports.months(), [october, september]);
  });

  test('reports a failure and reads again', () async {
    repository.readFailure = Exception('disk');
    final reports = await open();
    expect(reports.state.status, ReportsStatus.failed);

    repository.readFailure = null;
    await reports.retry();
    await settle();

    expect(reports.state.status, ReportsStatus.ready);
    expect(reports.state.report.total, rub(1160));
  });

  test('a failure stays when the others speak after it', () async {
    final reports = await open();

    repository.breakMain(Exception('disk'));
    await settle();
    expect(reports.state.status, ReportsStatus.failed);

    repository.changedRows();
    await settle();
    expect(reports.state.status, ReportsStatus.failed);

    repository.changed();
    await settle();
    expect(reports.state.status, ReportsStatus.ready);
  });

  group('after a night', () {
    test('the same day changes nothing', () async {
      final reports = await open();
      final before = reports.state;

      await reports.calendarChecked();

      expect(reports.state, same(before));
    });

    test('a new month moves the report', () async {
      final reports = await open();
      now = DateTime(2026, 11, 1, 8);

      await reports.calendarChecked();
      await settle();

      expect(reports.state.today, CivilDate(2026, 11, 1));
      expect(reports.state.month, CivilDate(2026, 11, 1));
    });

    test('a report of an older month stays there', () async {
      final reports = await open();
      await reports.monthChanged(september);
      await settle();
      now = DateTime(2026, 11, 1, 8);

      await reports.calendarChecked();
      await settle();

      expect(reports.state.today, CivilDate(2026, 11, 1));
      expect(reports.state.month, september);
    });
  });
}
