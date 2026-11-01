import 'package:decimal/decimal.dart';
import 'package:reports_common/reports_common.dart';
import 'package:test/test.dart';

import 'fake_reports_repository.dart';

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money usd(int minorUnits) => Money(minorUnits, Currency.usd);
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
    repository.days[CategoryKind.expense] = [
      testDay('Food', september, rub(1000)),
      testDay('Food', october, rub(1160)),
    ];
    repository.days[CategoryKind.income] = [
      testDay('Salary', october, rub(9000)),
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

  test('reads the months of the report', () async {
    await open();

    expect(repository.asked.single, (
      CategoryKind.expense,
      CivilDate(2026, 5, 1),
      CivilDate(2026, 10, 31),
    ));
  });

  group('a month under way', () {
    test('compares with the same days of the month before', () async {
      now = DateTime(2026, 10, 10);
      repository.days[CategoryKind.expense] = [
        testDay('Food', CivilDate(2026, 9, 10), rub(1000)),
        testDay('Food', CivilDate(2026, 9, 11), rub(9000)),
        testDay('Food', october, rub(1160)),
      ];

      final reports = await open();

      expect(reports.state.report.change, 16);
    });

    test('stops at the end of a shorter month before', () async {
      now = DateTime(2026, 3, 30);
      repository.days[CategoryKind.expense] = [
        testDay('Food', CivilDate(2026, 2, 28), rub(1000)),
        testDay('Food', CivilDate(2026, 3, 2), rub(1160)),
      ];

      final reports = await open();

      expect(reports.state.report.change, 16);
    });

    test('a finished month compares with the whole one before', () async {
      now = DateTime(2026, 10, 10);
      repository.days[CategoryKind.expense] = [
        testDay('Food', CivilDate(2026, 8, 31), rub(1000)),
        testDay('Food', CivilDate(2026, 9, 2), rub(1160)),
      ];
      final reports = await open();

      await reports.monthChanged(september);
      await settle();

      expect(reports.state.report.change, 16);
    });
  });

  group('rates', () {
    final monday = CivilDate(2026, 10, 26);
    final friday = CivilDate(2026, 10, 30);
    final rates = RateBook([
      DayRates(monday, {'USD': Decimal.fromInt(70)}),
      DayRates(friday, {
        'USD': Decimal.fromInt(90),
        'EUR': Decimal.fromInt(100),
      }),
    ]);

    setUp(() {
      repository
        ..rates = rates
        ..days[CategoryKind.expense] = [
          testDay('Food', monday, usd(100)),
          testDay('Food', friday, usd(100)),
          testDay('Cafe', friday, rub(55)),
        ];
    });

    test('turn each amount into the currency of the report', () async {
      final reports = await open();
      final report = reports.state.report;

      expect(report.total, rub(16055));
      expect(report.others, isEmpty);
      expect(reports.state.converted, isTrue);
    });

    test('the month bar and the month agree', () async {
      final reports = await open();
      final report = reports.state.report;

      expect(report.months.last.total, report.total);
    });

    test('the currency picked for totals comes first', () async {
      repository.base = Currency.eur;

      final reports = await open();

      expect(reports.state.report.total?.currency, Currency.eur);
      expect(reports.state.report.others, isEmpty);
    });

    test('compare with the month before at the rates of its days', () async {
      repository.days[CategoryKind.expense] = [
        testDay('Food', september, usd(100)),
        testDay('Food', friday, usd(100)),
      ];

      final reports = await open();

      expect(reports.state.report.total, rub(9000));
      expect(reports.state.report.change, 29);
    });

    test('an amount without a rate stays apart', () async {
      repository.days[CategoryKind.expense] = [
        testDay('Food', friday, rub(100)),
        testDay('Cafe', friday, Money(500, Currency.iso('JPY'))),
      ];

      final reports = await open();

      expect(reports.state.report.total, rub(100));
      expect(reports.state.report.others, [Money(500, Currency.iso('JPY'))]);
      expect(reports.state.converted, isFalse);
    });

    test('a report in one currency needs no rate', () async {
      repository.days[CategoryKind.expense] = [
        testDay('Food', friday, rub(150)),
      ];

      final reports = await open();

      expect(reports.state.report.total, rub(150));
      expect(reports.state.converted, isFalse);
    });

    test('only the month on the screen says that it took a rate', () async {
      repository.days[CategoryKind.expense] = [
        testDay('Food', september, usd(100)),
        testDay('Food', friday, rub(100)),
      ];

      final reports = await open();
      expect(reports.state.converted, isFalse);

      await reports.monthChanged(september);
      await settle();
      expect(reports.state.converted, isTrue);
    });

    test('no rates yet leave each currency apart', () async {
      repository.rates = const RateBook.empty();

      final reports = await open();

      expect(reports.state.report.total, rub(55));
      expect(reports.state.report.others, [usd(200)]);
      expect(reports.state.converted, isFalse);
    });

    test('the page turns as new rates come', () async {
      repository.rates = const RateBook.empty();
      final reports = await open();

      repository
        ..rates = rates
        ..changed();
      await settle();

      expect(reports.state.report.total, rub(16055));
      expect(reports.state.report.others, isEmpty);
    });

    test('a day with old rates moves to its own once they come', () async {
      repository.rates = RateBook([
        DayRates(friday, {'USD': Decimal.fromInt(90)}),
      ]);
      final reports = await open();
      expect(reports.state.report.total, rub(18055));

      repository
        ..rates = rates
        ..changed();
      await settle();

      expect(reports.state.report.total, rub(16055));
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

    expect(repository.asked, hasLength(1));
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

    expect(repository.asked, hasLength(1));
  });

  test('clears the old month while the new one is on its way', () async {
    final reports = await open();

    final moving = reports.monthChanged(september);
    expect(reports.state.status, ReportsStatus.loading);
    expect(reports.state.days, isEmpty);

    await moving;
  });

  test('follows the ledger', () async {
    final reports = await open();

    repository.days[CategoryKind.expense] = [
      testDay('Food', october, rub(2000)),
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
