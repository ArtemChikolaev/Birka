import 'package:ask_common/ask_common.dart';
import 'package:ask_common/testing.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<AskCubit> start(FakeAskRepository repository) async {
    final cubit = AskCubit(repository, help: helpQuestions);
    addTearDown(cubit.close);
    await settle();
    return cubit;
  }

  test('reads a question and counts it in the ledger', () async {
    final cubit = await start(FakeAskRepository());

    cubit.ask('кафе в октябре');
    await settle();

    final state = cubit.state;
    expect(state.reading, isA<AskData>());
    expect(state.answer?.total, units(5220, Currency.rub));
    expect(
      [for (final chip in state.chips) chip.label],
      [
        'Траты',
        'Кафе',
        'Октябрь 2026',
      ],
    );
    expect(state.periods, hasLength(5));
  });

  test('counts the question again over another period', () async {
    final cubit = await start(FakeAskRepository());
    cubit.ask('кафе в октябре');
    await settle();

    cubit.choosePeriod(AskPeriod.month(CivilDate(2026, 9, 1)));
    await settle();

    expect(cubit.state.answer?.total, units(2400, Currency.rub));
    expect(cubit.state.chips.last.label, 'Сентябрь 2026');
  });

  test('follows the ledger as it changes', () async {
    final repository = FakeAskRepository();
    final cubit = await start(repository);
    cubit.ask('кафе в октябре');
    await settle();

    repository
      ..operations = [
        ...repository.operations,
        askOperation('late', units(780, Currency.rub), CivilDate(2026, 10, 30)),
      ]
      ..changed();
    await settle();

    expect(cubit.state.answer?.total, units(6000, Currency.rub));
    expect(cubit.state.answer?.count, 5);
  });

  test('counts the answer again in a new currency of the totals', () async {
    final repository = FakeAskRepository();
    final cubit = await start(repository);
    cubit.ask('кафе в октябре');
    await settle();

    repository
      ..base = Currency.usd
      ..changed();
    await settle();

    expect(cubit.state.currency, Currency.usd);
    expect(cubit.state.answer?.currency, Currency.usd);
  });

  test('answers the capital and a rate from what it knows', () async {
    final cubit = await start(FakeAskRepository());

    cubit.ask('сколько у меня денег');
    await settle();
    expect(cubit.state.reading, isA<AskFactReading>());
    expect(cubit.state.capital?.main, units(437180, Currency.rub));

    cubit.ask('курс лари');
    await settle();
    expect(cubit.state.rate, Money(3005, Currency.rub));
  });

  test(
    'remembers questions once, the latest first, and forgets them',
    () async {
      final repository = FakeAskRepository(recent: const ['курс лари']);
      final cubit = await start(repository);
      expect(cubit.state.recent, ['курс лари']);

      cubit.ask('кафе в октябре');
      await settle();
      await cubit.remember();
      cubit.ask('Курс лари');
      await settle();
      await cubit.remember();

      expect(cubit.state.recent, ['Курс лари', 'кафе в октябре']);
      expect(repository.recent(), ['Курс лари', 'кафе в октябре']);

      cubit.ask('абракадабра');
      await settle();
      await cubit.remember();
      expect(cubit.state.recent, hasLength(2));

      await cubit.forget();
      expect(cubit.state.recent, isEmpty);
      expect(repository.recent(), isEmpty);
    },
  );

  test('stops counting once the question is not about money', () async {
    final repository = FakeAskRepository();
    final cubit = await start(repository);
    cubit.ask('кафе в октябре');
    await settle();

    cubit.ask('как скрыть суммы');
    await settle();

    expect(cubit.state.reading, isA<AskHelpReading>());
    expect(cubit.state.answer, isNull);
    expect(cubit.state.counting, isFalse);
  });
}
