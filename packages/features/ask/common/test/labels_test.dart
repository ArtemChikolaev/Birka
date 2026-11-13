import 'package:ask_common/ask_common.dart';
import 'package:ask_common/testing.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

String nb(String text) => text.replaceAll(' ', String.fromCharCode(0xA0));

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  final today = askToday;
  String label(AskPeriod period) => periodLabel(period, today: today);
  final names = AskNames(
    categories: {for (final category in askCategories()) category.id: category},
    tags: {for (final tag in askTags()) tag.id: tag},
  );

  test('names the periods on their plaques', () {
    expect(label(AskPeriod.day(today)), 'Сегодня');
    expect(label(AskPeriod.day(today.addDays(-1))), 'Вчера');
    expect(label(AskPeriod.day(CivilDate(2026, 11, 8))), '8 ноября');
    expect(label(AskPeriod.week(today).upTo(today)), 'Эта неделя');
    expect(label(AskPeriod.week(today.addDays(-7))), 'Прошлая неделя');
    expect(label(AskPeriod.month(today).upTo(today)), 'Этот месяц');
    expect(label(AskPeriod.month(CivilDate(2026, 10, 1))), 'Октябрь 2026');
    expect(label(AskPeriod.months(CivilDate(2026, 10, 1), 3)), 'Авг – Окт');
    expect(label(AskPeriod.year(2025)), '2025');
    expect(label(AskPeriod.lastDays(today, 30)), 'Последние 30 дней');
    expect(
      label(AskPeriod.range(CivilDate(2026, 10, 1), CivilDate(2026, 10, 15))),
      '1–15 октября',
    );
  });

  test('says what a total is set against', () {
    String before(AskPeriod period) => beforeLabel(period, today: today);

    expect(before(AskPeriod.month(CivilDate(2026, 10, 1))), 'к сентябрю');
    expect(before(AskPeriod.month(today).upTo(today)), 'к 1–12 октября');
    expect(before(AskPeriod.year(2026).upTo(today)), 'к тем же дням 2025');
    expect(before(AskPeriod.year(2025)), 'к 2024');
  });

  test('titles an answer by what it counts and when', () {
    String title(AskQuery query) => answerTitle(query, names, today: today);

    expect(
      title(
        AskQuery(
          period: AskPeriod.month(CivilDate(2026, 10, 1)),
          categoryIds: const {'cafe'},
        ),
      ),
      'Кафе · Октябрь 2026',
    );
    expect(title(const AskQuery(tagId: 'tbilisi')), 'Тбилиси · 3–12 ноября');
    expect(
      title(
        AskQuery(
          period: AskPeriod.month(today).upTo(today),
          above: units(5000, Currency.rub),
        ),
      ),
      'Больше ${nb('5 000 ₽')} · Этот месяц',
    );
  });

  test('puts the trip on a plaque with its days, and no period', () {
    final chips = askChips(
      const AskQuery(tagId: 'tbilisi'),
      names,
      today: today,
    );

    expect(
      [for (final chip in chips) chip.label],
      [
        'Траты',
        'Тбилиси · 3–12 ноября',
      ],
    );
    expect(chips.last.kind, AskChipKind.tag);
  });

  test('tells the count and the mean under the total', () {
    final answer = answerOf(
      AskQuery(
        period: AskPeriod.month(CivilDate(2026, 10, 1)),
        categoryIds: const {'cafe'},
      ),
      transactions: askOperations(),
      categories: askCategories(),
      rates: askRates(),
      currency: Currency.rub,
    );

    expect(answerLine(answer), '4 операции · в среднем ${nb('1 305 ₽')}');
    expect(
      [for (final bar in answer.bars) barLabel(bar)],
      [
        '1–4',
        '5–11',
        '12–18',
        '19–25',
        '26–31',
      ],
    );
  });
}
