import 'package:decimal/decimal.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:tags_common/tags_common.dart';
import 'package:tags_common/testing.dart';
import 'package:test/test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  List<Transaction> wearing(String id) => [
    for (final operation in boardOperations())
      if (operation.tagIds.contains(id)) operation,
  ];

  TagReport reportOfTrip({CivilDate? today}) => reportOf(
    tag: tbilisi,
    operations: wearing('tbilisi'),
    categories: boardCategories(),
    rates: boardRates(),
    base: Currency.rub,
    today: today ?? boardToday,
  );

  group('the report of a trip', () {
    test('counts its expenses in rubles at the rate of each day', () {
      final report = reportOfTrip();

      // 38 + 96 lari at 30,05, 420 dollars at 81,40 and 23 800 rubles; a
      // total that took a rate is whole.
      expect(report.total, units(62015, Currency.rub));
      expect(report.missingRates, isFalse);
    });

    test('puts the currencies in the order of what they took', () {
      final report = reportOfTrip();

      expect(
        [for (final part in report.currencies) part.amount],
        [units(420, Currency.usd), units(23800, Currency.rub), units(134, gel)],
      );
      expect(report.currencies.first.inBase, units(34188, Currency.rub));
      expect(report.currencies.first.only?.id, 'flat');
      expect(report.currencies.last.there, 2);
      expect(report.currencies.last.only, isNull);
    });

    test('measures the categories against the biggest and the whole', () {
      final report = reportOfTrip();

      expect(
        [for (final part in report.categories) part.category?.id],
        [
          'travel',
          'cafe',
        ],
      );
      expect([for (final part in report.categories) part.percent], [94, 6]);
      expect(report.categories.first.fraction, 1);
      expect(report.categories.last.total, units(4027, Currency.rub));
    });

    test('tells the days on the spot from those before', () {
      final report = reportOfTrip();

      expect((report.there, report.before, report.after), (2, 2, 0));
      expect(report.elapsed, 10);
      // 4 027 rubles of lunches over ten days, and the same in lari.
      expect(report.perDay, Money(40270, Currency.rub));
      expect(report.perDayLocal, Money(1340, gel));
      expect(
        reportLine(report, today: boardToday),
        '3–12 ноября · сегодня последний день',
      );
    });

    test('values expenses by period at their historical rates', () {
      final periods = reportOfTrip().periods;
      expect(
        [
          for (final part in periods)
            (part.period, part.count, part.total, part.converted),
        ],
        [
          (TripPeriod.before, 2, units(57988, Currency.rub), true),
          (TripPeriod.during, 2, units(4027, Currency.rub), true),
          (TripPeriod.after, 0, units(0, Currency.rub), false),
        ],
      );
    });

    test('uses each expense date when rates change within a period', () {
      final first = tbilisi.days!.first;
      final last = tbilisi.days!.last;
      final report = reportOf(
        tag: tbilisi,
        operations: [
          expense('last', units(1, Currency.usd), last),
          expense('first', units(1, Currency.usd), first),
        ],
        categories: const [],
        rates: RateBook([
          DayRates(first, {'USD': Decimal.fromInt(80)}),
          DayRates(last, {'USD': Decimal.fromInt(90)}),
        ]),
        base: Currency.rub,
        today: last,
      );
      expect(report.periods[1].total, units(170, Currency.rub));
    });

    test('includes both trip dates and counts a split expense once', () {
      final first = CivilDate(2026, 12, 31);
      final last = CivilDate(2027, 1, 1);
      final trip = Tag(
        id: 'new-year',
        name: 'New Year',
        days: TagDays(first, last),
      );
      Money rub(int amount) => Money(amount, Currency.rub);
      final transfer = Transaction(
        id: 'transfer',
        kind: TransactionKind.transfer,
        occurredOn: last,
        note: '',
        status: TransactionStatus.cleared,
        source: TransactionSource.manual,
        entries: [
          Entry(accountId: 'a', amount: rub(-100)),
          Entry(accountId: 'b', amount: rub(100)),
        ],
        allocations: const [],
      );
      TagReport report(List<Transaction> operations) => reportOf(
        tag: trip,
        operations: operations,
        categories: boardCategories(),
        rates: boardRates(),
        base: Currency.rub,
        today: last,
      );
      final result = report([
        expense('after', rub(202), CivilDate(2027, 1, 2)),
        transfer,
        expense('last', rub(303), last),
        Transaction(
          id: 'split',
          kind: TransactionKind.expense,
          occurredOn: first,
          note: '',
          status: TransactionStatus.cleared,
          source: TransactionSource.manual,
          entries: [Entry(accountId: 'a', amount: rub(-599))],
          allocations: [
            Allocation(categoryId: 'cafe', amount: rub(399)),
            Allocation(categoryId: 'travel', amount: rub(200)),
          ],
        ),
        expense('before', rub(101), CivilDate(2026, 12, 30)),
      ]);
      expect(
        [for (final part in result.periods) (part.count, part.total)],
        [(1, rub(101)), (2, rub(902)), (1, rub(202))],
      );
      expect(result.there, 3);
      expect(report([transfer]).periods, isEmpty);
      expect(report([]).periods, isEmpty);
    });

    test('has no day on the spot before the trip starts', () {
      final report = reportOfTrip(today: CivilDate(2026, 11, 1));

      expect(report.elapsed, 0);
      expect(report.perDay, isNull);
      expect(
        reportLine(report, today: CivilDate(2026, 11, 1)),
        '3–12 ноября · через 2 дня',
      );
    });

    test('keeps the expenses without a rate out of the total and says so', () {
      final report = reportOf(
        tag: tbilisi,
        operations: [
          ...wearing('tbilisi'),
          expense(
            'coin',
            units(10, Currency.custom('USDC', decimalDigits: 2)),
            CivilDate(2026, 11, 5),
            tags: {'tbilisi': TagMark.days},
          ),
        ],
        categories: boardCategories(),
        rates: boardRates(),
        base: Currency.rub,
        today: boardToday,
      );

      expect(report.missingRates, isTrue);
      final periods = report.periods;
      expect(periods.first.total, units(57988, Currency.rub));
      expect(periods[1].count, 3);
      expect(periods[1].total, isNull);
      expect(tripSpendingLabel(periods[1]), 'Нет курса');
      expect(periods.last.total, units(0, Currency.rub));
      expect(report.total, units(62015, Currency.rub));
    });
  });

  test('the report of a метка without days spans its operations', () {
    final report = reportOf(
      tag: renovation,
      operations: [
        expense(
          'delivery',
          units(2400, Currency.rub),
          CivilDate(2026, 11, 2),
          categoryId: 'home',
          tags: {'renovation': TagMark.hand},
        ),
        expense(
          'tile',
          units(18400, Currency.rub),
          CivilDate(2026, 8, 14),
          categoryId: 'home',
          tags: {'renovation': TagMark.hand},
        ),
      ],
      categories: boardCategories(),
      rates: boardRates(),
      base: Currency.rub,
      today: boardToday,
    );

    expect(report.total, units(20800, Currency.rub));
    expect(report.periods, isEmpty);
    expect(report.span, 81);
    // 30 days of the 81.
    expect(report.perMonth, Money(770370, Currency.rub));
    expect(report.perDay, isNull);
    expect(reportLine(report, today: boardToday), '14 августа — 2 ноября');
  });

  test('the summaries count the operations and the rubles of each метка', () {
    final summaries = summarize(
      boardTags(),
      [
        for (final operation in boardOperations())
          if (operation.tagIds.isNotEmpty) operation,
      ],
      rates: boardRates(),
      base: Currency.rub,
    );

    expect(
      [for (final it in summaries) (it.tag.id, it.count, it.total.minorUnits)],
      [
        ('tbilisi', 4, 6201500),
        ('istanbul', 0, 0),
        ('renovation', 1, 1840000),
      ],
    );
  });

  group('the shelves', () {
    test(
      'put the trip of today first, then the other trips, then the rest',
      () {
        expect(shelfOf(tbilisi, boardToday), TagShelf.now);
        expect(shelfOf(istanbul, boardToday), TagShelf.trips);
        expect(shelfOf(renovation, boardToday), TagShelf.plain);
      },
    );

    test('say how far a trip has come', () {
      TagSummary of(Tag tag, [int count = 0]) => TagSummary(
        tag: tag,
        count: count,
        total: const Money.zero(Currency.rub),
      );

      expect(shelfLine(of(tbilisi), today: boardToday), 'Последний день');
      expect(
        shelfLine(of(tbilisi), today: CivilDate(2026, 11, 5)),
        'День 3 из 10',
      );
      expect(shelfLine(of(istanbul), today: boardToday), '2–9 мая');
      expect(shelfLine(of(renovation, 27), today: boardToday), '27 операций');
      expect(
        wideShelfLine(of(tbilisi, 46), today: boardToday),
        '3–12 ноября · последний день · 46 операций',
      );
    });
  });

  test('the days of a trip read as one range', () {
    expect(daysLabel(tbilisi.days!, thisYear: 2026), '3–12 ноября');
    expect(
      daysLabel(
        TagDays(CivilDate(2026, 10, 28), CivilDate(2026, 11, 3)),
        thisYear: 2026,
      ),
      '28 октября — 3 ноября',
    );
    expect(
      daysLabel(
        TagDays(CivilDate(2025, 12, 28), CivilDate(2026, 1, 3)),
        thisYear: 2026,
      ),
      '28 декабря 2025 — 3 января',
    );
  });
}
