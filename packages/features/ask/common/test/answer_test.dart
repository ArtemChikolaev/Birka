import 'package:ask_common/ask_common.dart';
import 'package:ask_common/testing.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

void main() {
  AskAnswer count(AskQuery query) => answerOf(
    query,
    transactions: askOperations(),
    categories: askCategories(),
    rates: askRates(),
    currency: Currency.rub,
  );

  final october = AskPeriod.month(CivilDate(2026, 10, 1));

  test('counts a category with its subcategories over a month', () {
    final answer = count(
      AskQuery(period: october, categoryIds: const {'cafe'}),
    );

    expect(answer.total, units(5220, Currency.rub));
    expect(answer.count, 4);
    expect(answer.average, units(1305, Currency.rub));
    expect(answer.before, units(2400, Currency.rub));
    expect(
      [for (final operation in answer.biggest) operation.transaction.id],
      ['surf', 'khinkali', 'bakery'],
    );
    expect(answer.shares, isEmpty);
    // The weeks of October 2026 go from Monday; the 1st is a Thursday.
    expect(
      [for (final bar in answer.bars) '${bar.first.day}–${bar.last.day}'],
      ['1–4', '5–11', '12–18', '19–25', '26–31'],
    );
    expect(
      [for (final bar in answer.bars) bar.total.minorUnits ~/ 100],
      [1240, 0, 1950, 1780, 250],
    );
    expect(
      [for (final bar in answer.bars) bar.top],
      [
        false,
        false,
        true,
        false,
        false,
      ],
    );
  });

  test('counts a trip in every currency at the rate of each day', () {
    final answer = count(const AskQuery(tagId: 'tbilisi'));

    // 23 800 ₽, 420 $ at 81,40 and 376 ₾ at 30,05 add up exactly and round
    // once: 69 286,80 ₽ is whole, since it took a rate.
    expect(answer.total, units(69287, Currency.rub));
    expect(answer.count, 5);
    expect(answer.before, isNull);
    expect(
      [for (final share in answer.shares) share.category?.id],
      ['travel', 'cafe', 'transport'],
    );
    expect(
      [for (final share in answer.shares) share.percent],
      [84, 13, 3],
    );
  });

  test('keeps what is above a bound at the rate of its day', () {
    final answer = count(
      AskQuery(
        period: AskPeriod.month(CivilDate(2026, 11, 1)).upTo(askToday),
        above: units(5000, Currency.rub),
      ),
    );

    expect(
      [for (final operation in answer.operations) operation.transaction.id],
      ['week', 'tile', 'barbarestan'],
    );
    expect(answer.total, units(30091, Currency.rub));
    expect(answer.biggest.first.transaction.id, 'tile');
  });

  test('counts the income of a month by where it came from', () {
    final answer = count(AskQuery(side: AskSide.income, period: october));

    expect(answer.total, units(222000, Currency.rub));
    expect(answer.count, 2);
    expect(
      [for (final share in answer.shares) share.category?.id],
      ['salary', 'sold'],
    );
  });

  test('finds operations by the words of their notes', () {
    final answer = count(
      AskQuery(
        period: AskPeriod.month(CivilDate(2026, 11, 1)).upTo(askToday),
        words: const ['такси'],
      ),
    );

    expect(
      [for (final operation in answer.operations) operation.transaction.id],
      ['taxi'],
    );
    expect(answer.total, units(2104, Currency.rub));
  });

  test('says when nothing fits', () {
    final answer = count(
      AskQuery(period: october, categoryIds: const {'subs'}),
    );

    expect(answer.total, const Money.zero(Currency.rub));
    expect(answer.count, 0);
    expect(answer.average, isNull);
    expect(answer.biggest, isEmpty);
    expect(answer.bars, isEmpty);
  });

  test('leaves out what has no rate and says so', () {
    final answer = answerOf(
      const AskQuery(tagId: 'tbilisi'),
      transactions: askOperations(),
      categories: askCategories(),
      rates: const RateBook.empty(),
      currency: Currency.rub,
    );

    expect(answer.partial, isTrue);
    expect(answer.total, units(23800, Currency.rub));
  });
}
