@TestOn('vm')
library;

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

/// The state of [cubit] once it stands at [status].
Future<ScheduleFormState> at(
  ScheduleFormCubit cubit,
  ScheduleFormStatus status,
) async => cubit.state.status == status
    ? cubit.state
    : cubit.stream.firstWhere((state) => state.status == status);

void main() {
  final today = CivilDate(2026, 11, 18);
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late LedgerSchedulesRepository repository;
  late Account card;
  late Account cash;
  late Account euro;
  late Category home;
  late Category pay;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    repository = LedgerSchedulesRepository(
      ledger,
      BaseCurrency(null),
      MonthStart(1),
      MemorySettingsStore(),
      now: () => DateTime(2026, 11, 18, 12),
    );
    euro = await ledger.addAccount(
      name: 'Евро',
      type: AccountType.debit,
      openingBalance: Money(0, Currency.eur),
    );
    await ledger.updateAccount(euro.id, sortOrder: 5);
    card = await ledger.addAccount(
      name: 'Карта',
      type: AccountType.debit,
      openingBalance: rub(1000),
      sortOrder: 0,
    );
    cash = await ledger.addAccount(
      name: 'Наличные',
      type: AccountType.cash,
      openingBalance: rub(100),
      sortOrder: 1,
    );
    home = await ledger.addCategory(kind: CategoryKind.expense, name: 'Дом');
    pay = await ledger.addCategory(kind: CategoryKind.income, name: 'Зарплата');
  });

  tearDown(() async {
    await database.close();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  test('a new payment starts today on the first account in rubles', () async {
    final cubit = ScheduleFormCubit(repository);
    addTearDown(cubit.close);

    final form = await at(cubit, ScheduleFormStatus.editing);

    expect(form.editing, isFalse);
    expect(form.kind, TransactionKind.expense);
    expect(form.next, today);
    expect(form.day, 18);
    expect(form.account?.id, card.id);
    expect(form.accounts.map((it) => it.name), ['Карта', 'Наличные', 'Евро']);
    expect(form.valid, isFalse);
  });

  group('a payment made from an operation', () {
    Future<String> operation({
      required CivilDate on,
      String note = 'Яндекс Плюс',
      TransactionSource source = TransactionSource.import,
    }) => ledger.record(
      TransactionDraft.expense(
        accountId: card.id,
        allocations: [Allocation(categoryId: home.id, amount: rub(449))],
        occurredOn: on,
        note: note,
        source: source,
      ),
    );

    test('starts as the operation, every month from its next day', () async {
      final made = await operation(on: CivilDate(2026, 11, 12));
      final cubit = ScheduleFormCubit(repository, from: made);
      addTearDown(cubit.close);

      final form = await at(cubit, ScheduleFormStatus.editing);

      expect(form.madeFrom?.id, made);
      expect(form.kind, TransactionKind.expense);
      expect(form.name, 'Яндекс Плюс');
      expect(form.amount, rub(449));
      expect(form.account?.id, card.id);
      expect(form.category?.id, home.id);
      expect(form.every, ScheduleEvery.month);
      expect(form.day, 12);
      expect(form.next, CivilDate(2026, 12, 12));
      // The bank charges what a statement brought.
      expect(form.onDay, ScheduleOnDay.post);
      expect(form.valid, isTrue);

      await cubit.save();

      final saved = (await ledger.watchSchedules().first).single;
      expect(saved.next, CivilDate(2026, 12, 12));
      expect(saved.last?.transactionId, made);
      expect(saved.last?.on, CivilDate(2026, 11, 12));
    });

    test('of the 31st stays the 31st through a shorter month', () async {
      final made = await operation(on: CivilDate(2026, 10, 31));
      final cubit = ScheduleFormCubit(repository, from: made);
      addTearDown(cubit.close);
      await at(cubit, ScheduleFormStatus.editing);

      await cubit.save();

      final saved = (await ledger.watchSchedules().first).single;
      expect(saved.next, CivilDate(2026, 11, 30));
      expect(saved.day, 31);
    });

    test('of today comes next month, and one the person wrote asks', () async {
      final made = await operation(
        on: today,
        note: '',
        source: TransactionSource.manual,
      );
      final cubit = ScheduleFormCubit(repository, from: made);
      addTearDown(cubit.close);

      final form = await at(cubit, ScheduleFormStatus.editing);

      // With no note it takes the name of its category.
      expect(form.name, 'Дом');
      expect(form.next, CivilDate(2026, 12, 18));
      expect(form.onDay, ScheduleOnDay.ask);
    });

    test(
      'the latest of what came every month says so and keeps its day',
      () async {
        // Яндекс Плюс on the 12th since August, the latest on 12 November.
        for (final month in [8, 9, 10]) {
          await operation(on: CivilDate(2026, month, 12));
        }
        final made = await operation(on: CivilDate(2026, 11, 12));
        final cubit = ScheduleFormCubit(repository, from: made);
        addTearDown(cubit.close);

        final form = await at(cubit, ScheduleFormStatus.editing);

        expect(form.found?.times, hasLength(4));
        expect(form.found?.latest.id, made);
        expect(form.day, 12);
        expect(form.next, CivilDate(2026, 12, 12));
        expect(form.onDay, ScheduleOnDay.post);
      },
    );

    test(
      'of a bill whose amount changes asks on the day of the bill',
      () async {
        Future<String> bill(CivilDate on, int rubles) => ledger.record(
          TransactionDraft.expense(
            accountId: card.id,
            allocations: [Allocation(categoryId: home.id, amount: rub(rubles))],
            occurredOn: on,
            note: 'ЖКУ Москва',
            source: TransactionSource.import,
          ),
        );
        await bill(CivilDate(2026, 9, 10), 6410);
        await bill(CivilDate(2026, 10, 10), 6845);
        final made = await bill(CivilDate(2026, 11, 9), 7120);
        final cubit = ScheduleFormCubit(repository, from: made);
        addTearDown(cubit.close);

        final form = await at(cubit, ScheduleFormStatus.editing);

        expect(form.found?.varies, isTrue);
        // The bill comes on the 10th, though the latest came a day early.
        expect(form.day, 10);
        expect(form.next, CivilDate(2026, 12, 10));
        // Its last amount, which its day asks to confirm.
        expect(form.amount, rub(7120));
        expect(form.onDay, ScheduleOnDay.ask);
      },
    );

    test('starts empty when the operation is gone', () async {
      final cubit = ScheduleFormCubit(repository, from: 'none');
      addTearDown(cubit.close);

      final form = await at(cubit, ScheduleFormStatus.editing);

      expect(form.madeFrom, isNull);
      expect(form.name, isEmpty);
      expect(form.next, today);
    });

    test('comes on its day from today on, after the operation', () {
      expect(
        nextAfterOperation(CivilDate(2026, 10, 25), today: today),
        CivilDate(2026, 11, 25),
      );
      expect(
        nextAfterOperation(CivilDate(2026, 10, 31), today: today),
        CivilDate(2026, 11, 30),
      );
      expect(
        nextAfterOperation(CivilDate(2026, 11, 25), today: today),
        CivilDate(2026, 12, 25),
      );
      expect(
        nextAfterOperation(CivilDate(2026, 11, 2), today: today),
        CivilDate(2026, 12, 2),
      );
    });
  });

  test('saves a new expense with its day of the month', () async {
    final cubit = ScheduleFormCubit(repository);
    addTearDown(cubit.close);
    await at(cubit, ScheduleFormStatus.editing);

    cubit
      ..nameChanged('  Аренда ')
      ..amountChanged(4500000)
      ..categoryChanged(home.id)
      ..nextChanged(CivilDate(2026, 11, 25))
      ..onDayChanged(ScheduleOnDay.post);
    expect(cubit.state.valid, isTrue);
    await cubit.save();

    expect(cubit.state.status, ScheduleFormStatus.saved);
    final saved = (await ledger.watchSchedules().first).single;
    expect(saved.name, 'Аренда');
    expect(saved.amount, rub(45000));
    expect(saved.categoryId, home.id);
    expect(saved.day, 25);
    expect(saved.next, CivilDate(2026, 11, 25));
    expect(saved.onDay, ScheduleOnDay.post);
  });

  test('a day of the month comes from today on, and a day the month lacks '
      'falls on its last day and stays the day', () async {
    final cubit = ScheduleFormCubit(repository);
    addTearDown(cubit.close);
    await at(cubit, ScheduleFormStatus.editing);

    cubit.dayChanged(5);
    expect(cubit.state.day, 5);
    expect(cubit.state.next, CivilDate(2026, 12, 5));
    cubit.dayChanged(18);
    expect(cubit.state.next, today);
    cubit
      ..nameChanged('Аренда')
      ..amountChanged(4500000)
      ..categoryChanged(home.id)
      ..dayChanged(31);
    expect(cubit.state.day, 31);
    expect(cubit.state.next, CivilDate(2026, 11, 30));
    await cubit.save();

    final saved = (await ledger.watchSchedules().first).single;
    expect(saved.day, 31);
    expect(saved.next, CivilDate(2026, 11, 30));
  });

  test('the rest of a salary in halves keeps a day the month lacks, and '
      'not the day of the advance', () async {
    final cubit = ScheduleFormCubit(repository, salary: true);
    addTearDown(cubit.close);
    await at(cubit, ScheduleFormStatus.editing);

    cubit
      ..halvesChanged(halves: true)
      ..dayChanged(31);
    expect(cubit.state.advanceDay, 3);
    expect(cubit.state.day, 31);
    expect(cubit.state.next, CivilDate(2026, 11, 30));
    cubit.dayChanged(3);
    expect(cubit.state.day, 31);
  });

  test('a salary starts as an income named so', () async {
    final cubit = ScheduleFormCubit(repository, salary: true);
    addTearDown(cubit.close);

    final form = await at(cubit, ScheduleFormStatus.editing);

    expect(form.kind, TransactionKind.income);
    expect(form.name, 'Зарплата');
    expect(form.categories.map((it) => it.id), [pay.id]);
  });

  test('a salary in halves saves half of the month for each time, the '
      'advance first', () async {
    final cubit = ScheduleFormCubit(repository, salary: true);
    addTearDown(cubit.close);
    await at(cubit, ScheduleFormStatus.editing);

    cubit
      ..amountChanged(12000000)
      ..categoryChanged(pay.id)
      ..halvesChanged(halves: true);
    // Today is the 18th, so the advance takes the 3rd at first.
    expect(cubit.state.halves, isTrue);
    expect(cubit.state.advanceDay, 3);
    cubit
      ..nextChanged(CivilDate(2026, 12, 5))
      ..advanceDayChanged(20)
      ..advanceDayChanged(5);
    expect(cubit.state.day, 5);
    expect(cubit.state.advanceDay, 20);
    expect(cubit.state.next, CivilDate(2026, 11, 20));
    expect(cubit.state.nextIsAdvance, isTrue);
    expect(cubit.state.part, rub(60000));
    await cubit.save();

    final saved = (await ledger.watchSchedules().first).single;
    expect(saved.amount, rub(60000));
    expect(saved.every, ScheduleEvery.month);
    expect(saved.day, 5);
    expect(saved.advanceDay, 20);
    expect(saved.next, CivilDate(2026, 11, 20));
  });

  test('a salary in halves opens with its month, and its waiting advance '
      'stays through a change', () async {
    final salary = await ledger.addSchedule(
      kind: TransactionKind.income,
      name: 'Зарплата',
      accountId: card.id,
      categoryId: pay.id,
      amount: rub(60000),
      every: ScheduleEvery.month,
      next: CivilDate(2026, 11, 17),
      day: 5,
      advanceDay: 17,
    );
    final cubit = ScheduleFormCubit(repository, id: salary.id);
    addTearDown(cubit.close);

    final form = await at(cubit, ScheduleFormStatus.editing);
    expect(form.amountMinor, 12000000);
    expect(form.halves, isTrue);
    cubit.nameChanged('Зарплата в «Ромашке»');
    await cubit.save();

    final saved = (await ledger.schedule(salary.id))!;
    expect(saved.name, 'Зарплата в «Ромашке»');
    expect(saved.amount, rub(60000));
    expect(saved.advanceDay, 17);
    expect(saved.next, CivilDate(2026, 11, 17));
  });

  test('a sum of a month that does not split into equal halves is not '
      'saved', () async {
    final cubit = ScheduleFormCubit(repository, salary: true);
    addTearDown(cubit.close);
    await at(cubit, ScheduleFormStatus.editing);

    cubit
      ..amountChanged(12000001)
      ..halvesChanged(halves: true);

    expect(cubit.state.uneven, isTrue);
    expect(cubit.state.part, isNull);
    expect(cubit.state.valid, isFalse);
    await cubit.save();
    expect(await ledger.watchSchedules().first, isEmpty);

    cubit.amountChanged(12000002);
    expect(cubit.state.uneven, isFalse);
    expect(cubit.state.part, Money(6000001, Currency.rub));
    // One sum keeps every kopeck.
    cubit
      ..amountChanged(12000001)
      ..halvesChanged(halves: false);
    expect(cubit.state.part, Money(12000001, Currency.rub));
    expect(cubit.state.valid, isTrue);
  });

  test('a salary gives its advance a sum of its own, and the rest comes '
      'with the salary', () async {
    final cubit = ScheduleFormCubit(repository, salary: true);
    addTearDown(cubit.close);
    await at(cubit, ScheduleFormStatus.editing);

    cubit
      ..amountChanged(12000000)
      ..categoryChanged(pay.id)
      ..halvesChanged(halves: true)
      ..nextChanged(CivilDate(2026, 12, 5))
      ..advanceDayChanged(20);
    expect(cubit.state.ownAdvance, isFalse);
    expect(cubit.state.half, rub(60000));
    expect(cubit.state.advanceAmount, rub(60000));

    cubit.advanceAmountChanged(4000000);
    expect(cubit.state.ownAdvance, isTrue);
    expect(cubit.state.advanceAmount, rub(40000));
    expect(cubit.state.part, rub(80000));
    expect(cubit.state.valid, isTrue);
    // An advance that leaves nothing for the rest changes nothing.
    cubit.advanceAmountChanged(12000000);
    expect(cubit.state.advanceAmount, rub(40000));
    await cubit.save();

    final saved = (await ledger.watchSchedules().first).single;
    expect(saved.amount, rub(80000));
    expect(saved.advanceAmount, rub(40000));
    expect(saved.monthAmount, rub(120000));
  });

  test('an advance of its own goes back to half by the half itself, by a '
      'month it no longer fits, and with one sum', () async {
    final cubit = ScheduleFormCubit(repository, salary: true);
    addTearDown(cubit.close);
    await at(cubit, ScheduleFormStatus.editing);

    cubit
      ..amountChanged(12000000)
      ..halvesChanged(halves: true)
      ..advanceAmountChanged(4000000)
      ..advanceAmountChanged(6000000);
    expect(cubit.state.ownAdvance, isFalse);

    cubit
      ..advanceAmountChanged(4000000)
      ..amountChanged(3000000);
    expect(cubit.state.ownAdvance, isFalse);
    expect(cubit.state.part, rub(15000));

    cubit
      ..advanceAmountChanged(1000000)
      ..halvesChanged(halves: false);
    expect(cubit.state.advanceMinor, isNull);
    expect(cubit.state.part, rub(30000));
  });

  test('a salary with an advance of its own opens with its month and keeps '
      'the advance through a change', () async {
    final salary = await ledger.addSchedule(
      kind: TransactionKind.income,
      name: 'Зарплата',
      accountId: card.id,
      categoryId: pay.id,
      amount: rub(80000),
      advanceAmount: rub(40000),
      every: ScheduleEvery.month,
      next: CivilDate(2026, 11, 20),
      day: 5,
      advanceDay: 20,
    );
    final cubit = ScheduleFormCubit(repository, id: salary.id);
    addTearDown(cubit.close);

    final form = await at(cubit, ScheduleFormStatus.editing);
    expect(form.amountMinor, 12000000);
    expect(form.advanceAmount, rub(40000));
    expect(form.part, rub(80000));
    cubit.nameChanged('Зарплата в «Ромашке»');
    await cubit.save();

    final saved = (await ledger.schedule(salary.id))!;
    expect(saved.amount, rub(80000));
    expect(saved.advanceAmount, rub(40000));
  });

  test('only an income comes in halves', () async {
    final cubit = ScheduleFormCubit(repository, salary: true);
    addTearDown(cubit.close);
    await at(cubit, ScheduleFormStatus.editing);

    cubit
      ..halvesChanged(halves: true)
      ..kindChanged(TransactionKind.expense);

    expect(cubit.state.advanceDay, isNull);
    expect(cubit.state.halves, isFalse);
    cubit
      ..kindChanged(TransactionKind.income)
      ..halvesChanged(halves: true)
      ..halvesChanged(halves: false);
    expect(cubit.state.advanceDay, isNull);
  });

  test('a transfer reaches another account of its currency, with no '
      'category', () async {
    final cubit = ScheduleFormCubit(repository);
    addTearDown(cubit.close);
    await at(cubit, ScheduleFormStatus.editing);

    cubit
      ..categoryChanged(home.id)
      ..kindChanged(TransactionKind.transfer);

    expect(cubit.state.toAccount?.id, cash.id);
    expect(cubit.state.targets.map((it) => it.id), [cash.id]);
    expect(cubit.state.categoryId, isNull);

    cubit
      ..nameChanged('В копилку')
      ..amountChanged(100000);
    await cubit.save();
    final saved = (await ledger.watchSchedules().first).single;
    expect(saved.kind, TransactionKind.transfer);
    expect(saved.toAccountId, cash.id);
  });

  test('a change keeps the id and the day of the month', () async {
    final gym = await ledger.addSchedule(
      kind: TransactionKind.expense,
      name: 'Спортзал',
      accountId: card.id,
      amount: rub(3500),
      every: ScheduleEvery.month,
      next: CivilDate(2026, 11, 30),
      day: 31,
    );
    final cubit = ScheduleFormCubit(repository, id: gym.id);
    addTearDown(cubit.close);

    final form = await at(cubit, ScheduleFormStatus.editing);
    expect(form.editing, isTrue);
    expect(form.name, 'Спортзал');
    expect(form.amount, rub(3500));
    expect(form.day, 31);

    cubit.amountChanged(380000);
    await cubit.save();

    final saved = (await ledger.watchSchedules().first).single;
    expect(saved.id, gym.id);
    expect(saved.amount, rub(3800));
    expect(saved.day, 31);
  });

  test('deletes the payment it changes', () async {
    final gym = await ledger.addSchedule(
      kind: TransactionKind.expense,
      name: 'Спортзал',
      accountId: card.id,
      amount: rub(3500),
      every: ScheduleEvery.month,
      next: CivilDate(2026, 12, 3),
    );
    final cubit = ScheduleFormCubit(repository, id: gym.id);
    addTearDown(cubit.close);
    await at(cubit, ScheduleFormStatus.editing);

    await cubit.delete();

    expect(cubit.state.status, ScheduleFormStatus.deleted);
    expect(await ledger.watchSchedules().first, isEmpty);
  });

  test('says when the payment to change is gone', () async {
    final cubit = ScheduleFormCubit(repository, id: 'gone');
    addTearDown(cubit.close);

    expect(
      (await at(cubit, ScheduleFormStatus.missing)).status,
      ScheduleFormStatus.missing,
    );
  });
}
