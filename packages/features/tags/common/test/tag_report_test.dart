import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
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
