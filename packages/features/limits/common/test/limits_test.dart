import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_common/limits_common.dart';
import 'package:limits_common/testing.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

/// Waits for the streams of the repository to reach the cubit.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  // Labels use no-break spaces in sums; the tests read them as plain ones.
  String plain(String text) => text.replaceAll(' ', ' ');

  group('the limits of the month', () {
    late MemoryLimitsRepository repository;
    late LimitsCubit cubit;

    setUp(() async {
      repository = MemoryLimitsRepository();
      cubit = LimitsCubit(repository);
      await settle();
    });

    tearDown(() => cubit.close());

    test('come over first, then nearest to their end', () {
      final state = cubit.state;
      expect(state.status, LimitsStatus.ready);
      expect(
        [for (final limit in state.limits) limit.category.name],
        ['Досуг', 'Кафе', 'Поездки', 'Продукты', 'Транспорт'],
      );
      expect(state.over, 1);
      expect(state.within, 4);
      expect(state.daysLeft, 13);
    });

    test('say how each stands', () {
      final [leisure, cafe, travel, ...] = cubit.state.limits;
      expect(plain(limitFigures(cafe)), '10 150 ₽ из 12 000 ₽');
      expect(plain(limitNote(leisure)), 'больше лимита на 1 300 ₽');
      expect(plain(limitNoteShort(leisure)), 'больше на 1 300 ₽');
      expect(
        plain(limitOverviewNote(cafe)),
        'осталось 1 850 ₽ · хватит примерно до 21 ноября',
      );
      expect(limitPace(cafe), 'В таком темпе хватит до 21 ноября');
      expect(limitPace(travel), isNull);
      expect(plain(limitSpent(travel)), '≈ 261 €');
      expect(plain(limitOf(travel)), 'из 400 €');
      expect(plain(limitNote(travel)), 'осталось ≈ 139 €');
    });

    test('sum up the month', () {
      final state = cubit.state;
      expect(limitsTitle(state.today), 'Лимиты на ноябрь');
      expect(limitsSummary(state), 'превышен 1 · 13 дней');
      expect(limitsWithin(state), '4 из 5');
      expect(limitsOverNote(state), '1 превышен');
      expect(limitsRestart(state), 'с 1 декабря заново');
    });

    test('list the categories without a limit that spent', () {
      final free = cubit.state.free;
      expect(
        [for (final entry in free) entry.category.name],
        [
          'Дом',
          'Здоровье',
          'Подписки',
        ],
      );
      expect(plain(freeNote(free.first, boardToday)), '6 400 ₽ в ноябре');
      expect(
        plain(freeNote(free.last, boardToday)),
        '1 997 ₽ · регулярные платежи',
      );
    });

    test('follow a limit set meanwhile', () async {
      await repository.setLimit(home.id, CategoryLimit(rubles(6500)));
      await settle();
      expect(
        [for (final limit in cubit.state.limits) limit.category.name],
        contains('Дом'),
      );
      expect(
        [for (final entry in cubit.state.free) entry.category.name],
        isNot(contains('Дом')),
      );
    });

    test('a month that starts on the 25th counts from then', () async {
      repository
        ..monthStart = 25
        ..changed();
      await settle();
      await settle();
      expect(cubit.state.month, CivilDate(2026, 10, 25));
      expect(cubit.state.daysLeft, 7);
    });
  });

  group('the form of a limit', () {
    late MemoryLimitsRepository repository;

    Future<LimitFormCubit> open({String? categoryId}) async {
      final cubit = LimitFormCubit(repository, categoryId: categoryId);
      addTearDown(cubit.close);
      await settle();
      await settle();
      return cubit;
    }

    setUp(() => repository = MemoryLimitsRepository());

    test('a new one picks among the categories without a limit', () async {
      final cubit = await open();
      final state = cubit.state;
      expect(state.status, LimitFormStatus.editing);
      expect(
        [for (final c in state.categories) c.name],
        [
          'Дом',
          'Здоровье',
          'Подписки',
        ],
      );
      expect(state.category?.name, 'Дом');
      expect(state.editing, isFalse);
      expect(state.amount, isNull);
      expect(state.canSave, isFalse);
      expect(limitFormTitle(state), 'Новый лимит');
      expect(limitWarnLine(state), 'Скажем, когда уйдёт 80 % лимита.');
    });

    test('takes the offered average and saves it', () async {
      final cubit = await open();
      expect(cubit.state.suggestion?.average, rubles(6210));
      expect(plain(limitTake(cubit.state.suggestion!.offer)), 'Взять 6 500 ₽');
      cubit.takeOffer();
      expect(cubit.state.amount, rubles(6500));
      expect(cubit.state.took, isTrue);
      expect(
        plain(limitWarnLine(cubit.state)),
        'Скажем, когда уйдёт 80 % — 5 200 ₽.',
      );
      await cubit.save();
      expect(cubit.state.status, LimitFormStatus.saved);
      expect(repository.setLimits, [(home.id, CategoryLimit(rubles(6500)))]);
      expect(plain(limitDone(cubit.state)), 'Лимит на «Дом» — 6 500 ₽ в месяц');
    });

    test('another currency converts the sum instead of keeping it', () async {
      final cubit = await open();
      cubit
        ..takeOffer()
        ..currencyPicked(Currency.eur);
      // 6 500 ₽ at 91,50 ₽ are 71,04 €: the step of 5 € makes 70 €.
      expect(cubit.state.amount, euros(70));
      expect(cubit.state.suggestion?.offer, euros(70));
      expect(cubit.state.asOffered, isTrue);
      expect(
        plain(limitWarnLine(cubit.state)),
        'Скажем, когда уйдёт 80 % — 56 €.',
      );
    });

    test('a picked category starts without a sum', () async {
      final cubit = await open();
      cubit
        ..takeOffer()
        ..categoryPicked(health.id);
      expect(cubit.state.category?.name, 'Здоровье');
      expect(cubit.state.amount, isNull);
      expect(cubit.state.suggestion?.reason, SuggestionReason.rare);
    });

    test('a limit that is set shows what the month took and goes', () async {
      final cubit = await open(categoryId: cafe.id);
      final state = cubit.state;
      expect(state.editing, isTrue);
      expect(state.amount, rubles(12000));
      expect(limitFormTitle(state), 'Лимит на «Кафе»');
      expect(
        plain(limitSpentNow(state)!),
        'В ноябре — 10 150 ₽ из 12 000 ₽',
      );
      expect(state.asOffered, isTrue);
      await cubit.remove();
      expect(cubit.state.status, LimitFormStatus.removed);
      expect(repository.setLimits, [(cafe.id, null)]);
      expect(limitDone(cubit.state), 'Лимит на «Кафе» убрали');
    });

    test('a limit in euros puts its currency first', () async {
      final cubit = await open(categoryId: travel.id);
      expect(cubit.state.currency, Currency.eur);
      expect(cubit.state.currencies, [Currency.eur, Currency.rub]);
      expect(
        limitCaption(cubit.state),
        'Лимит считается с 1-го по последнее число месяца и начинается '
        'заново каждый месяц. Траты в других валютах идут в этот лимит по '
        'курсу ЦБ на день операции.',
      );
    });

    test('a refused save can be tried again', () async {
      final cubit = await open();
      cubit.takeOffer();
      repository.failure = Exception('disk');
      await cubit.save();
      expect(cubit.state.status, LimitFormStatus.failed);
      expect(cubit.state.canSave, isTrue);
    });
  });

  group('limits offered from averages', () {
    Future<LimitSuggestCubit> open(MemoryLimitsRepository repository) async {
      final cubit = LimitSuggestCubit(repository);
      addTearDown(cubit.close);
      await settle();
      await settle();
      return cubit;
    }

    MemoryLimitsRepository unlimited() => MemoryLimitsRepository(
      categories: [
        for (final category in boardCategories)
          if (category.id != travel.id) withLimit(category, null),
      ],
    );

    test('check the steady ones and say why the others are not', () async {
      final cubit = await open(unlimited());
      final state = cubit.state;
      expect(state.status, LimitSuggestStatus.ready);
      expect(
        [
          for (final s in state.suggestions)
            (s.category.name, s.offer, plain(suggestionNote(s))),
        ],
        [
          ('Продукты', rubles(30000), 'в среднем 29 640 ₽'),
          ('Кафе', rubles(12000), 'в среднем 11 620 ₽'),
          ('Досуг', rubles(8000), 'в среднем 7 610 ₽'),
          ('Транспорт', rubles(5000), 'в среднем 4 520 ₽'),
          ('Дом', rubles(6500), 'скачут: от 2 100 ₽ до 11 400 ₽'),
          ('Здоровье', rubles(2500), 'траты были в 1 месяце из 3'),
          ('Подписки', rubles(2000), 'это регулярные платежи'),
        ],
      );
      expect(state.picked, {groceries.id, cafe.id, leisure.id, transport.id});
      expect(
        plain(suggestionsText(state)),
        'Средние траты за август — октябрь, округлили вверх до 500 ₽. '
        'Отметили категории, где траты каждый месяц похожи.',
      );
      expect(suggestionsButton(state), 'Поставить 4 лимита');
      expect(suggestionsFrom(state.month), 'По тратам за август — октябрь');
    });

    test('set the checked ones', () async {
      final repository = unlimited();
      final cubit = await open(repository)
        ..toggle(home.id);
      expect(suggestionsButton(cubit.state), 'Поставить 5 лимитов');
      await cubit.save();
      expect(cubit.state.status, LimitSuggestStatus.saved);
      expect(repository.setLimits, [
        (groceries.id, CategoryLimit(rubles(30000))),
        (cafe.id, CategoryLimit(rubles(12000))),
        (leisure.id, CategoryLimit(rubles(8000))),
        (transport.id, CategoryLimit(rubles(5000))),
        (home.id, CategoryLimit(rubles(6500))),
      ]);
      expect(suggestionsDone(cubit.state), 'Поставили 5 лимитов на ноябрь');
    });

    test('unchecking all leaves nothing to set', () async {
      final cubit = await open(unlimited());
      [...cubit.state.picked].forEach(cubit.toggle);
      expect(cubit.state.canSave, isFalse);
      expect(suggestionsButton(cubit.state), 'Ничего не отмечено');
    });

    test('a ledger without a full month waits for one', () async {
      final repository = unlimited()
        ..spending = [
          for (final row in boardSpending)
            if (row.day.month == 11) row,
        ];
      final cubit = await open(repository);
      expect(cubit.state.status, LimitSuggestStatus.short);
      expect(
        suggestionsShort(cubit.state),
        'Средние появятся после первого полного месяца с тратами — '
        '1 декабря. Лимит можно поставить и сейчас, вручную.',
      );
    });

    test('there is nothing to offer once every category has a limit', () async {
      final repository = MemoryLimitsRepository(
        categories: [
          for (final category in boardCategories)
            withLimit(category, category.limit ?? CategoryLimit(rubles(1000))),
        ],
      );
      final cubit = await open(repository);
      expect(cubit.state.status, LimitSuggestStatus.nothing);
    });
  });
}
