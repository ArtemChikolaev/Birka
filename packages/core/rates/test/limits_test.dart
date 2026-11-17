import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

void main() {
  Money rub(int rubles) => Money(rubles * 100, Currency.rub);
  Money eur(int euros) => Money(euros * 100, Currency.eur);

  // The story of the boards: Wednesday 18 November, a euro at 91,50 ₽.
  final month = CivilDate(2026, 11, 1);
  final today = CivilDate(2026, 11, 18);
  final rates = RateBook([
    DayRates(CivilDate(2026, 8, 1), {
      'EUR': Decimal.parse('91.5'),
      'USD': Decimal.fromInt(80),
      'JPY': Decimal.parse('0.5'),
    }),
  ]);

  Category category(String id, {CategoryLimit? limit, bool archived = false}) =>
      Category(
        id: id,
        kind: CategoryKind.expense,
        name: id,
        archived: archived,
        sortOrder: 0,
        limit: limit,
      );

  final leisure = category('Досуг', limit: CategoryLimit(rub(8000)));
  final cafe = category('Кафе', limit: CategoryLimit(rub(12000)));
  final travel = category('Поездки', limit: CategoryLimit(eur(400)));
  final groceries = category('Продукты', limit: CategoryLimit(rub(30000)));
  final transport = category('Транспорт', limit: CategoryLimit(rub(5000)));

  CategoryDayTotal row(
    Category category,
    int day,
    Money total, {
    int month = 11,
  }) => CategoryDayTotal(category, CivilDate(2026, month, day), total);

  final november = [
    row(leisure, 7, rub(4300)),
    row(leisure, 16, rub(5000)),
    row(cafe, 3, rub(4150)),
    row(cafe, 12, rub(6000)),
    row(travel, 9, eur(214)),
    row(travel, 9, rub(4300)),
    row(groceries, 2, rub(18640)),
    row(transport, 4, rub(2870)),
    // October and the day after today stay out of November.
    row(cafe, 31, rub(9000), month: 10),
    row(cafe, 19, rub(9000)),
  ];

  group('the progress of a limit', () {
    LimitProgress of(Category category) =>
        limitProgress(category, november, rates, month: month, today: today);

    test('counts the month up to today', () {
      final progress = of(cafe);
      expect(progress.spent, rub(10150));
      expect(progress.left, rub(1850));
      expect(progress.state, LimitState.near);
      expect(progress.approximate, isFalse);
    });

    test('says when the limit runs out at the pace of the month', () {
      // 10 150 ₽ in 18 days is 564 ₽ a day: 1 850 ₽ last 3 more days.
      expect(of(cafe).lastsUntil, CivilDate(2026, 11, 21));
    });

    test('is over once the month took more', () {
      final progress = of(leisure);
      expect(progress.spent, rub(9300));
      expect(progress.left, rub(-1300));
      expect(progress.state, LimitState.over);
      expect(progress.lastsUntil, isNull);
    });

    test('counts other currencies at the rate of their days', () {
      // 4 300 ₽ at 91,50 ₽ are 46,99 €: with 214 € it is about 261 €.
      final progress = of(travel);
      expect(progress.spent, eur(261));
      expect(progress.approximate, isTrue);
      expect(progress.state, LimitState.ok);
    });

    test('leaves out a currency that never had a rate', () {
      final lari = Money(5000, Currency.iso('GEL'));
      final progress = limitProgress(
        cafe,
        [...november, row(cafe, 10, lari)],
        rates,
        month: month,
        today: today,
      );
      expect(progress.spent, rub(10150));
      expect(progress.unrated, isTrue);
    });

    test('a month without spending lasts and has nothing to say', () {
      final progress = limitProgress(
        cafe,
        const [],
        rates,
        month: month,
        today: today,
      );
      expect(progress.spent, const Money.zero(Currency.rub));
      expect(progress.state, LimitState.ok);
      expect(progress.lastsUntil, isNull);
    });
  });

  test('a share of a limit stands near its end from 80 % and over past it', () {
    expect(limitShare(rub(9600), rub(12000)), 0.8);
    expect(limitStateOf(limitShare(rub(9599), rub(12000))), LimitState.ok);
    expect(limitStateOf(limitShare(rub(9600), rub(12000))), LimitState.near);
    expect(limitStateOf(limitShare(rub(12000), rub(12000))), LimitState.near);
    expect(limitStateOf(limitShare(rub(12001), rub(12000))), LimitState.over);
  });

  test('the limits go over first, then nearest to their end', () {
    final progress = limitsProgress(
      [
        groceries,
        transport,
        cafe,
        travel,
        leisure,
        category('Дом'),
        category('Старое', limit: CategoryLimit(rub(100)), archived: true),
      ],
      november,
      rates,
      month: month,
      today: today,
    );
    expect(
      [for (final p in progress) p.category.id],
      ['Досуг', 'Кафе', 'Поездки', 'Продукты', 'Транспорт'],
    );
  });

  group('limits suggested from three months', () {
    final home = category('Дом');
    final health = category('Здоровье');
    final subscriptions = category('Подписки');
    final food = category('Продукты');
    final trips = category('Поездки');
    final summer = [
      row(food, 10, rub(29000), month: 8),
      row(food, 10, rub(30120), month: 9),
      row(food, 10, rub(29800), month: 10),
      row(home, 3, rub(2100), month: 8),
      row(home, 3, rub(11400), month: 9),
      row(home, 3, rub(5130), month: 10),
      row(health, 14, rub(7020), month: 9),
      row(subscriptions, 1, rub(1997), month: 8),
      row(subscriptions, 1, rub(1997), month: 9),
      row(subscriptions, 1, rub(1997), month: 10),
      row(trips, 20, rub(15370), month: 8),
      row(trips, 20, rub(15370), month: 9),
      row(trips, 20, rub(15370), month: 10),
      // November is not a full month yet.
      row(food, 2, rub(90000)),
    ];

    test('round the average up to 500 ₽ and say why', () {
      final suggestions = suggestLimits(
        [home, health, subscriptions, food],
        summer,
        rates,
        currency: Currency.rub,
        month: month,
        regular: {subscriptions.id},
      );
      expect(
        [
          for (final s in suggestions)
            (s.category.id, s.average, s.offer, s.reason),
        ],
        [
          ('Продукты', rub(29640), rub(30000), SuggestionReason.steady),
          ('Дом', rub(6210), rub(6500), SuggestionReason.jumps),
          ('Здоровье', rub(2340), rub(2500), SuggestionReason.rare),
          ('Подписки', rub(1997), rub(2000), SuggestionReason.regular),
        ],
      );
      expect(
        [for (final s in suggestions) s.picked],
        [true, false, false, false],
      );
      expect(suggestions[1].least, rub(2100));
      expect(suggestions[1].most, rub(11400));
      expect(suggestions[2].monthsWithSpending, 1);
    });

    test('a limit in euros rounds up to 5 €', () {
      final suggestion = suggestLimit(
        trips,
        summer,
        rates,
        currency: Currency.eur,
        month: month,
      );
      expect(suggestion!.average, eur(168));
      expect(suggestion.offer, eur(170));
    });

    test('nothing is offered for a category that spent nothing', () {
      expect(
        suggestLimit(
          category('Подарки'),
          summer,
          rates,
          currency: Currency.rub,
          month: month,
        ),
        isNull,
      );
    });

    test('a category with a limit is not offered one', () {
      final limited = category('Продукты', limit: CategoryLimit(rub(30000)));
      expect(
        suggestLimits(
          [limited],
          summer,
          rates,
          currency: Currency.rub,
          month: month,
        ),
        isEmpty,
      );
    });
  });

  test('the step of a limit is 500 ₽ or about that in a round number', () {
    expect(limitStep(rates, Currency.rub), rub(500));
    expect(limitStep(rates, Currency.eur), eur(5));
    expect(limitStep(rates, Currency.usd), Money(500, Currency.usd));
    expect(
      limitStep(rates, Currency.iso('JPY')),
      Money(1000, Currency.iso('JPY')),
    );
  });

  test('what an expense leaves of the limit, counted over the month', () {
    final cafe = category('Кафе', limit: CategoryLimit(rub(12000)));
    final rows = [row(cafe, 3, rub(4150)), row(cafe, 12, rub(6000))];
    final within = limitWith(
      cafe,
      rows,
      rates,
      month: month,
      amount: rub(1250),
      day: today,
    );
    expect(within.left, rub(600));
    expect(within.state, LimitState.near);
    final over = limitWith(
      cafe,
      rows,
      rates,
      month: month,
      amount: rub(2300),
      day: today,
    );
    expect(over.left, rub(-450));
    expect(over.state, LimitState.over);
  });

  test('the spending of a span counts each day at its rate', () {
    final trips = category('Поездки');
    expect(
      spendingOf(
        trips,
        [row(trips, 9, eur(214)), row(trips, 9, rub(4300))],
        rates,
        Currency.eur,
        from: month,
        until: month.addMonths(1),
      ),
      eur(261),
    );
  });

  test('an average is in whole units of its currency', () {
    final cafe = category('Кафе');
    // 350 ₽ in October alone make 116,67 ₽ a month; the average says 117 ₽.
    final suggestion = suggestLimit(
      cafe,
      [CategoryDayTotal(cafe, CivilDate(2026, 10, 3), rub(350))],
      rates,
      currency: Currency.rub,
      month: month,
    );
    expect(suggestion!.average, rub(117));
    expect(suggestion.offer, rub(500));
  });
}
