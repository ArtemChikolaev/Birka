@TestOn('vm')
library;

import 'package:bloc/bloc.dart';
import 'package:database/database.dart';
import 'package:device_settings/device_settings.dart';
import 'package:drift/native.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:test/test.dart';

import 'fakes.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

/// The state of [cubit] once [test] holds for it.
Future<SchedulesView> viewOf(
  Cubit<SchedulesState> cubit, [
  bool Function(SchedulesView view)? test,
]) async {
  bool holds(SchedulesState state) =>
      state is SchedulesLoaded && (test?.call(state.view) ?? true);
  final state = holds(cubit.state)
      ? cubit.state
      : await cubit.stream.firstWhere(holds);
  return (state as SchedulesLoaded).view;
}

void main() {
  // Wednesday, November 18, 2026, as on the boards.
  final today = CivilDate(2026, 11, 18);
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late MemorySettingsStore store;
  late LedgerSchedulesRepository repository;
  late Account card;
  late Account cash;
  late Account savings;
  late Account wise;
  late Category home;
  late Category pay;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(
      database,
      now: () => DateTime.utc(2026, 11, 18, 9),
    );
    store = MemorySettingsStore()..values['payday-aside'] = '1000000';
    repository = LedgerSchedulesRepository(
      ledger,
      BaseCurrency(null),
      MonthStart(1),
      store,
      now: () => DateTime(2026, 11, 18, 12),
    );
    card = await ledger.addAccount(
      name: 'Зарплатная карта',
      type: AccountType.debit,
      openingBalance: rub(86400),
    );
    cash = await ledger.addAccount(
      name: 'Наличные',
      type: AccountType.cash,
      openingBalance: rub(3200),
    );
    savings = await ledger.addAccount(
      name: 'Накопительный',
      type: AccountType.savings,
      openingBalance: rub(250000),
    );
    wise = await ledger.addAccount(
      name: 'Wise',
      type: AccountType.debit,
      openingBalance: Money(120000, Currency.usd),
    );
    home = await ledger.addCategory(kind: CategoryKind.expense, name: 'Дом');
    pay = await ledger.addCategory(kind: CategoryKind.income, name: 'Зарплата');
    Future<void> add(
      String name,
      int rubles,
      CivilDate next, {
      TransactionKind kind = TransactionKind.expense,
      String? categoryId,
      ScheduleEvery every = ScheduleEvery.month,
      ScheduleOnDay onDay = ScheduleOnDay.ask,
    }) => ledger.addSchedule(
      kind: kind,
      name: name,
      accountId: card.id,
      categoryId: categoryId,
      amount: rub(rubles),
      every: every,
      next: next,
      onDay: onDay,
    );
    await add('Аренда', 45000, CivilDate(2026, 11, 25), categoryId: home.id);
    await add('Интернет', 650, CivilDate(2026, 11, 28), categoryId: home.id);
    await add(
      'Netflix',
      799,
      CivilDate(2026, 12, 1),
      onDay: ScheduleOnDay.post,
    );
    await add('Спортзал', 3500, CivilDate(2026, 12, 3));
    await add(
      'Зарплата',
      120000,
      CivilDate(2026, 12, 5),
      kind: TransactionKind.income,
      categoryId: pay.id,
    );
    await add(
      'Страховка авто',
      24000,
      CivilDate(2027, 3, 12),
      every: ScheduleEvery.year,
    );
    await ledger.record(
      TransactionDraft.expense(
        accountId: card.id,
        allocations: [Allocation(categoryId: home.id, amount: rub(620))],
        occurredOn: today,
      ),
    );
  });

  tearDown(() async {
    await database.close();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  test(
    'shows the next 30 days, every payment and the money of the day',
    () async {
      final cubit = SchedulesCubit(repository);
      addTearDown(cubit.close);

      final view = await viewOf(cubit);

      expect(view.today, today);
      expect(view.waiting, isEmpty);
      expect(view.ahead.map((it) => (it.schedule.name, it.on)), [
        ('Аренда', CivilDate(2026, 11, 25)),
        ('Интернет', CivilDate(2026, 11, 28)),
        ('Netflix', CivilDate(2026, 12, 1)),
        ('Спортзал', CivilDate(2026, 12, 3)),
        ('Зарплата', CivilDate(2026, 12, 5)),
      ]);
      expect(view.all.map((it) => it.name), [
        'Зарплата',
        'Аренда',
        'Интернет',
        'Netflix',
        'Спортзал',
        'Страховка авто',
      ]);
      expect(view.base, Currency.rub);
      expect(
        view.countable.map(
          (it) => (it.row.account.name, it.counted, it.locked),
        ),
        [
          ('Зарплатная карта', true, false),
          ('Наличные', true, false),
          ('Накопительный', false, false),
          ('Wise', false, true),
        ],
      );
      expect(view.salary?.name, 'Зарплата');
      expect(view.categories[home.id]?.name, 'Дом');
      final plan = view.plan!;
      expect(plan.morning, rub(89600));
      expect(plan.perDay, rub(1744));
      expect(plan.leftToday, rub(1124));
    },
  );

  test('a payment whose day came waits, and posting it moves it on', () async {
    final rent = await ledger.addSchedule(
      kind: TransactionKind.expense,
      name: 'ЖКХ',
      accountId: card.id,
      amount: rub(5200),
      every: ScheduleEvery.month,
      next: today,
    );
    final cubit = SchedulesCubit(repository);
    addTearDown(cubit.close);

    final before = await viewOf(cubit);
    expect(before.waiting.map((it) => it.name), ['ЖКХ']);
    expect(before.upcoming.first.schedule.name, 'ЖКХ');
    expect(before.ahead.map((it) => it.schedule.name), isNot(contains('ЖКХ')));

    await cubit.post(rent, amount: rub(4870));

    // The payment moves on and its transaction comes, in either order.
    final after = await viewOf(
      cubit,
      (view) =>
          view.waiting.isEmpty && view.todays.any((it) => it.note == 'ЖКХ'),
    );
    expect(
      after.schedules.singleWhere((it) => it.id == rent.id).next,
      CivilDate(2026, 12, 18),
    );
    final posted = after.todays.singleWhere((it) => it.note == 'ЖКХ');
    expect(posted.source, TransactionSource.recurring);
    expect(posted.entries.single.amount, -rub(4870));
    // A post of a regular payment is no spending of the day.
    expect(after.plan!.spentToday, rub(620));
  });

  test('skipping moves a payment on without a transaction', () async {
    final rent = await ledger.addSchedule(
      kind: TransactionKind.expense,
      name: 'ЖКХ',
      accountId: card.id,
      amount: rub(5200),
      every: ScheduleEvery.month,
      next: today,
    );
    final cubit = SchedulesCubit(repository);
    addTearDown(cubit.close);
    await viewOf(cubit);

    await cubit.skip(rent);

    final after = await viewOf(cubit, (view) => view.waiting.isEmpty);
    expect(after.todays.where((it) => it.note == 'ЖКХ'), isEmpty);
    expect(
      after.schedules.singleWhere((it) => it.id == rent.id).next,
      CivilDate(2026, 12, 18),
    );
  });

  test('counts to the end of a month that starts on the picked day', () async {
    final monthStart = MonthStart(1);
    final cubit = SchedulesCubit(
      LedgerSchedulesRepository(
        ledger,
        BaseCurrency(null),
        monthStart,
        store,
        now: () => DateTime(2026, 11, 18, 12),
      ),
    );
    addTearDown(cubit.close);
    await viewOf(cubit);
    await cubit.countUntil(SpendUntil.monthEnd);
    final calendar = await viewOf(
      cubit,
      (view) => view.settings.until == SpendUntil.monthEnd,
    );
    expect(calendar.plan!.end, CivilDate(2026, 11, 30));

    monthStart.choose(5);
    final moved = await viewOf(cubit, (view) => view.monthStart == 5);

    expect(moved.plan!.end, CivilDate(2026, 12, 4));
    expect(moved.plan!.perDay, rub(1744));
  });

  test('counts what the settings say, and the device keeps them', () async {
    final cubit = SchedulesCubit(repository);
    addTearDown(cubit.close);
    await viewOf(cubit);

    await cubit.count(savings.id, counted: true);
    final counted = await viewOf(
      cubit,
      (view) => view.counted.any((it) => it.account.id == savings.id),
    );
    expect(counted.plan!.morning, rub(339600));

    await cubit.count(cash.id, counted: false);
    await cubit.countUntil(SpendUntil.monthEnd);
    await cubit.keepAside(rub(5000));
    final changed = await viewOf(
      cubit,
      (view) => view.settings.asideMinor == 500000,
    );

    expect(changed.plan!.until, SpendUntil.monthEnd);
    expect(changed.plan!.aside, rub(5000));
    expect(
      changed.counted.map((it) => it.account.id),
      unorderedEquals([card.id, savings.id]),
    );
    final kept = PaydaySettings.read(store);
    expect(kept, changed.settings);
    expect(kept.accounts, {card.id, savings.id});
    expect(wise.currency, Currency.usd);
  });

  test('catches up with a new day after a night in the background', () async {
    var now = DateTime(2026, 11, 18, 23);
    final night = LedgerSchedulesRepository(
      ledger,
      BaseCurrency(null),
      MonthStart(1),
      store,
      now: () => now,
    );
    await ledger.addSchedule(
      kind: TransactionKind.expense,
      name: 'ЖКХ',
      accountId: card.id,
      amount: rub(5200),
      every: ScheduleEvery.month,
      next: CivilDate(2026, 11, 19),
    );
    final cubit = SchedulesCubit(night);
    addTearDown(cubit.close);
    final before = await viewOf(cubit);
    expect(before.waiting, isEmpty);
    expect(before.plan!.spentToday, rub(620));

    now = DateTime(2026, 11, 19, 8);
    await cubit.calendarChecked();

    final after = await viewOf(
      cubit,
      (view) => view.today == CivilDate(2026, 11, 19),
    );
    expect(after.waiting.map((it) => it.name), ['ЖКХ']);
    expect(after.todays, isEmpty);
    expect(after.plan!.spentToday, rub(0));
    expect(after.plan!.days, before.plan!.days - 1);
  });

  test('tells which payments a statement brought today', () async {
    final rent = await ledger.addSchedule(
      kind: TransactionKind.expense,
      name: 'ЖКХ',
      accountId: card.id,
      amount: rub(5200),
      every: ScheduleEvery.month,
      next: today,
    );
    final importId = await ledger.addImport(
      fileName: 'alfa.xlsx',
      format: 'alfa',
      firstDay: CivilDate(2026, 11, 1),
      lastDay: today,
    );
    final transactionId = await ledger.record(
      TransactionDraft.expense(
        accountId: card.id,
        allocations: [Allocation(categoryId: home.id, amount: rub(5200))],
        occurredOn: today,
        note: 'ZHKU MOSKVA',
        source: TransactionSource.import,
      ),
      importId: importId,
    );
    final cubit = SchedulesCubit(repository);
    addTearDown(cubit.close);
    expect((await viewOf(cubit)).waiting.map((it) => it.name), ['ЖКХ']);

    await ledger.findSchedule(
      rent.id,
      through: today,
      transactionId: transactionId,
      importId: importId,
    );

    final view = await viewOf(cubit, (view) => view.found.isNotEmpty);
    expect(view.waiting, isEmpty);
    final [found] = view.found;
    expect(found.schedule.name, 'ЖКХ');
    expect(found.import?.format, 'alfa');
    expect(view.doneToday(found.schedule), isTrue);
    expect(
      view.schedules.where(view.doneToday).map((it) => it.name),
      ['ЖКХ'],
    );
  });

  test('has no plan until a salary comes to a counted account', () async {
    await repository.saveSettings(PaydaySettings(accounts: {cash.id}));
    final cubit = SchedulesCubit(repository);
    addTearDown(cubit.close);

    final view = await viewOf(cubit);

    expect(view.plan, isNull);
    expect(view.salary, isNull);
  });
}
