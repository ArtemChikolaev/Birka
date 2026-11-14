@TestOn('vm')
library;

import 'dart:async';

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

/// [text] with the spaces of formatted amounts.
String nb(String text) => text.replaceAll(' ', String.fromCharCode(0xA0));

Schedule schedule(
  String name,
  int rubles,
  CivilDate next, {
  ScheduleReminder reminder = ScheduleReminder.onDay,
  TransactionKind kind = TransactionKind.expense,
  ScheduleOnDay onDay = ScheduleOnDay.ask,
  int? day,
  int? advanceDay,
}) => Schedule(
  id: name,
  kind: kind,
  name: name,
  accountId: 'card',
  amount: rub(rubles),
  every: ScheduleEvery.month,
  day: day ?? next.day,
  next: next,
  onDay: onDay,
  reminder: reminder,
  advanceDay: advanceDay,
);

/// Notifications that answer as told and keep what they were asked to show.
final class FakeChannel implements ReminderChannel {
  ReminderAccess answer = ReminderAccess.granted;
  ReminderAccess current = ReminderAccess.unknown;
  final shown = <List<ReminderNote>>[];

  @override
  Future<ReminderAccess> access() async => current;

  @override
  Future<ReminderAccess> requestAccess() async => current = answer;

  @override
  Future<void> show(List<ReminderNote> notes) async => shown.add(notes);

  @override
  Stream<ReminderTap> get opened => const Stream.empty();
}

/// A calendar that answers as told and keeps what it was asked to write.
final class FakeCalendar implements ReminderCalendar {
  ReminderAccess answer = ReminderAccess.granted;
  ReminderAccess current = ReminderAccess.unknown;
  final written = <List<CalendarReminder>>[];
  int removed = 0;
  int settings = 0;
  bool failRemove = false;

  @override
  Future<ReminderAccess> access() async => current;

  @override
  Future<ReminderAccess> requestAccess() async => current = answer;

  @override
  Future<void> write(List<CalendarReminder> events) async =>
      written.add(events);

  @override
  Future<void> remove() async {
    if (failRemove) throw Exception('no access');
    removed++;
  }

  @override
  Future<void> openSettings() async => settings++;
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  // Wednesday, November 18, 2026, 10:00, as on the boards.
  final now = DateTime(2026, 11, 18, 10);

  group('planned reminders', () {
    test('come on the day or the day before, the earliest first', () {
      final planned = planReminders(
        [
          schedule('Аренда', 45000, CivilDate(2026, 11, 25)),
          schedule(
            'Интернет',
            650,
            CivilDate(2026, 11, 28),
            reminder: ScheduleReminder.dayBefore,
          ),
          schedule(
            'Спортзал',
            3500,
            CivilDate(2026, 12, 3),
            reminder: ScheduleReminder.none,
          ),
        ],
        now: now,
        minutes: 9 * 60,
        days: 40,
      );

      expect(
        [for (final it in planned) (it.schedule.name, it.day)],
        [
          ('Аренда', CivilDate(2026, 11, 25)),
          ('Интернет', CivilDate(2026, 11, 27)),
          ('Аренда', CivilDate(2026, 12, 25)),
          ('Интернет', CivilDate(2026, 12, 27)),
        ],
      );
      expect(planned[1].early, isTrue);
      expect(planned[1].on, CivilDate(2026, 11, 28));
    });

    test('leave out today once its hour has passed', () {
      final rent = schedule('Аренда', 45000, CivilDate(2026, 11, 18));

      expect(
        planReminders([rent], now: now, minutes: 9 * 60, days: 20),
        isEmpty,
      );
      expect(
        planReminders(
          [rent],
          now: DateTime(2026, 11, 18, 8),
          minutes: 9 * 60,
          days: 20,
        ).single.day,
        CivilDate(2026, 11, 18),
      );
    });

    test('keep to the last day of a short month and to both halves', () {
      final phone = schedule('Связь', 500, CivilDate(2026, 11, 30), day: 31);
      final salary = schedule(
        'Зарплата',
        60000,
        CivilDate(2026, 11, 20),
        kind: TransactionKind.income,
        day: 5,
        advanceDay: 20,
      );

      expect(
        [
          for (final it in planReminders(
            [phone],
            now: now,
            minutes: 540,
            days: 102,
          ))
            it.day,
        ],
        [
          CivilDate(2026, 11, 30),
          CivilDate(2026, 12, 31),
          CivilDate(2027, 1, 31),
          CivilDate(2027, 2, 28),
        ],
      );
      expect(
        [
          for (final it in planReminders(
            [salary],
            now: now,
            minutes: 540,
            days: 20,
          ))
            (it.day, occurrenceName(it.schedule, it.on)),
        ],
        [
          (CivilDate(2026, 11, 20), 'Аванс'),
          (CivilDate(2026, 12, 5), 'Зарплата'),
        ],
      );
    });

    test('stop at the limit that the phone keeps', () {
      final rent = schedule('Аренда', 45000, CivilDate(2026, 11, 25));

      expect(
        planReminders([rent], now: now, minutes: 540, limit: 2),
        hasLength(2),
      );
    });
  });

  group('reminders that came', () {
    test('are the ones of the times still to do whose moment passed', () {
      final rent = schedule('Аренда', 45000, CivilDate(2026, 11, 18));
      final gym = schedule(
        'Спортзал',
        3500,
        CivilDate(2026, 11, 19),
        reminder: ScheduleReminder.dayBefore,
      );
      final later = schedule('Интернет', 650, CivilDate(2026, 11, 28));
      final quiet = schedule(
        'Подписка',
        799,
        CivilDate(2026, 11, 18),
        reminder: ScheduleReminder.none,
      );

      final came = remindersCame(
        [rent, gym, later, quiet],
        now: now,
        minutes: 9 * 60,
      );

      expect(
        [for (final it in came) (it.schedule.name, it.on, it.at)],
        [
          ('Аренда', CivilDate(2026, 11, 18), DateTime(2026, 11, 18, 9)),
          ('Спортзал', CivilDate(2026, 11, 19), DateTime(2026, 11, 18, 9)),
        ],
      );
      expect(
        remindersCame([rent, gym], now: now, minutes: 10 * 60 + 1),
        isEmpty,
      );
    });

    test('leave out the day that the notices no longer keep', () {
      // August 20 was 90 days before November 18, and August 21 was 89: a
      // notice of the 20th is forgotten, and none comes back as new.
      final edge = schedule('Аренда', 45000, CivilDate(2026, 8, 20));
      final inside = schedule('Спортзал', 3500, CivilDate(2026, 8, 21));

      final came = remindersCame([edge, inside], now: now, minutes: 9 * 60);

      expect(
        [for (final it in came) (it.schedule.name, it.on)],
        [
          ('Спортзал', CivilDate(2026, 8, 21)),
          ('Аренда', CivilDate(2026, 9, 20)),
          ('Спортзал', CivilDate(2026, 9, 21)),
          ('Аренда', CivilDate(2026, 10, 20)),
          ('Спортзал', CivilDate(2026, 10, 21)),
        ],
      );
    });

    test('come at their time on the clock on every day of a year', () {
      // A day when the clocks change keeps 9:00 at 9:00 where they change.
      for (
        var day = CivilDate(2026, 1, 1);
        day.year == 2026;
        day = day.addDays(1)
      ) {
        final at = PlannedReminder(
          schedule: schedule('Аренда', 45000, day),
          on: day,
          day: day,
          minutes: 9 * 60,
        ).at;
        expect(
          (at.year, at.month, at.day, at.hour, at.minute),
          (day.year, day.month, day.day, 9, 0),
          reason: '$day',
        );
      }
    });

    test('keep the times that wait since long ago, for 90 days', () {
      final rent = schedule('Аренда', 45000, CivilDate(2026, 7, 18));

      final came = remindersCame([rent], now: now, minutes: 9 * 60);

      // August 18 was 92 days ago.
      expect(came.map((it) => it.on), [
        CivilDate(2026, 9, 18),
        CivilDate(2026, 10, 18),
        CivilDate(2026, 11, 18),
      ]);
    });
  });

  group('the days of debts', () {
    DebtDay day(String name, CivilDate due) => DebtDay(
      debtId: name,
      name: name,
      side: DebtSide.lent,
      due: due,
      owed: rub(1000),
    );
    final today = day('Сегодня', CivilDate(2026, 11, 18));
    final tomorrow = day('Завтра', CivilDate(2026, 11, 19));
    final late = day('Февраль', CivilDate(2027, 2, 20));
    final past = day('Сентябрь', CivilDate(2026, 9, 1));
    final old = day('Июль', CivilDate(2026, 7, 1));

    test('ahead come after the hour of today, the earliest first', () {
      expect(
        debtDaysAhead([late, tomorrow, today, past], now: now, minutes: 540),
        [tomorrow],
      );
      expect(
        debtDaysAhead([tomorrow, today], now: now, minutes: 11 * 60),
        [today, tomorrow],
      );
      expect(
        debtDaysAhead([late], now: now, minutes: 540, days: 100),
        [late],
      );
    });

    test('came are the ones whose moment passed, for 90 days', () {
      expect(
        debtDaysCame(
          [tomorrow, today, past, old],
          now: now,
          minutes: 540,
        ),
        [past, today],
      );
      expect(debtDaysCame([today], now: now, minutes: 11 * 60), isEmpty);
    });
  });

  group('what a reminder says', () {
    test('the name, the amount and what a tap does', () {
      final rent = schedule('Аренда', 45000, CivilDate(2026, 11, 25));
      final salary = schedule(
        'Зарплата',
        120000,
        CivilDate(2026, 12, 5),
        kind: TransactionKind.income,
        onDay: ScheduleOnDay.post,
      );
      PlannedReminder at(Schedule schedule, CivilDate on, CivilDate day) =>
          PlannedReminder(schedule: schedule, on: on, day: day, minutes: 540);
      final today = at(rent, CivilDate(2026, 11, 25), CivilDate(2026, 11, 25));

      expect(
        reminderNote(today, sums: true).title,
        'Аренда · ${nb('45 000 ₽')}',
      );
      expect(
        reminderNote(today, sums: true).body,
        'Сегодня. Нажмите, чтобы провести или пропустить.',
      );
      expect(reminderNote(today, sums: false).title, 'Аренда');
      expect(
        reminderNote(today, sums: true).tap,
        const PaymentReminderTap('Аренда'),
      );
      final early = reminderNote(
        at(rent, CivilDate(2026, 11, 25), CivilDate(2026, 11, 24)),
        sums: true,
      );
      expect(early.body, 'Завтра, 25 ноября. Нажмите, чтобы открыть платёж.');
      expect(early.tap, const PaymentReminderTap('Аренда', early: true));
      final pay = reminderNote(
        at(salary, CivilDate(2026, 12, 5), CivilDate(2026, 12, 5)),
        sums: true,
      );
      expect(pay.title, 'Зарплата · ${nb('+120 000 ₽')}');
      expect(pay.body, 'Сегодня, проведётся само.');
    });

    test('a tap comes back from what the phone keeps', () {
      for (final tap in const [
        PaymentReminderTap('0b7c1f2e-rent'),
        PaymentReminderTap('0b7c1f2e-rent', early: true),
        DebtReminderTap('0b7c1f2e-masha'),
      ]) {
        expect(ReminderTap.parse(tap.payload), tap);
      }
      expect(const PaymentReminderTap('rent').payload, 'rent');
      expect(const DebtReminderTap('masha').payload, 'debt:masha');
    });

    test('a debt names the day, the person and who gives the money back', () {
      final masha = DebtDay(
        debtId: 'masha',
        name: 'Маша',
        side: DebtSide.lent,
        due: CivilDate(2026, 12, 1),
        owed: rub(3000),
      );
      final note = debtReminderNote(masha, minutes: 540, sums: true);
      expect(note.day, CivilDate(2026, 12, 1));
      expect(note.minutes, 540);
      expect(note.title, 'Срок сегодня · Маша, ${nb('3 000 ₽')}');
      expect(
        note.body,
        'Сегодня вам должны вернуть долг. Нажмите, чтобы открыть его.',
      );
      expect(note.tap, const DebtReminderTap('masha'));
      expect(
        debtReminderNote(masha, minutes: 540, sums: false).title,
        'Срок сегодня · Маша',
      );
      final sasha = DebtDay(
        debtId: 'sasha',
        name: 'Саша',
        side: DebtSide.borrowed,
        due: CivilDate(2026, 11, 20),
        owed: rub(4000),
      );
      expect(
        debtReminderNote(sasha, minutes: 540, sums: true).body,
        'Сегодня срок отдать долг. Нажмите, чтобы открыть его.',
      );
    });

    test('the notifications count the payments and the days of debts', () {
      expect(
        remindNotifyLine(payments: 6, debts: 0, time: '9:00'),
        '6 платежей · в 9:00',
      );
      expect(
        remindNotifyLine(payments: 0, debts: 1, time: '9:00'),
        '1 долг · в 9:00',
      );
      expect(
        remindNotifyLine(payments: 3, debts: 2, time: '20:00'),
        '3 платежа и 2 долга · в 20:00',
      );
    });

    test('the line of the form names the first reminder to come', () {
      const on = ReminderSettings(notify: true);
      Schedule rent(
        CivilDate next, {
        ScheduleReminder reminder = ScheduleReminder.onDay,
      }) => schedule('Аренда', 45000, next, reminder: reminder);
      String line(
        Schedule schedule, {
        ReminderSettings? settings = on,
        DateTime? at,
      }) => reminderLine(
        schedule: schedule,
        settings: settings,
        now: at ?? now,
      );
      final next = CivilDate(2026, 11, 25);

      expect(line(rent(next)), '25 ноября в 9:00 · напомнит Birka');
      expect(
        line(
          rent(next, reminder: ScheduleReminder.dayBefore),
          settings: on.copyWith(minutes: 20 * 60),
        ),
        '24 ноября в 20:00 · напомнит Birka',
      );
      expect(
        line(rent(next, reminder: ScheduleReminder.none)),
        'Без напоминания',
      );
      expect(
        line(rent(next), settings: const ReminderSettings()),
        'Напоминания выключены в «Ещё»',
      );
      expect(line(rent(next), settings: null), 'Напоминания выключены в «Ещё»');

      // A reminder that has passed gives way to the one of the next time: the
      // day before today, and today once its hour has gone.
      final today = CivilDate(2026, 11, 18);
      expect(
        line(rent(today, reminder: ScheduleReminder.dayBefore)),
        '17 декабря в 9:00 · напомнит Birka',
      );
      expect(line(rent(today)), '18 декабря в 9:00 · напомнит Birka');
      expect(
        line(rent(today), at: DateTime(2026, 11, 18, 8)),
        '18 ноября в 9:00 · напомнит Birka',
      );

      // A time more than a year away names its own day.
      expect(
        line(rent(CivilDate(2028, 1, 10))),
        '10 января 2028 в 9:00 · напомнит Birka',
      );
    });

    test('the line says who reminds', () {
      final rent = schedule('Аренда', 45000, CivilDate(2026, 11, 25));
      String line(ReminderSettings settings) =>
          reminderLine(schedule: rent, settings: settings, now: now);

      expect(
        line(const ReminderSettings(notify: true, calendar: true)),
        '25 ноября в 9:00 · напомнят Birka и календарь',
      );
      expect(
        line(const ReminderSettings(calendar: true)),
        '25 ноября в 9:00 · напомнит календарь «Birka»',
      );
    });

    test('a time goes by the clock', () {
      expect(clockLabel(9 * 60), '9:00');
      expect(clockLabel(23 * 60 + 30), '23:30');
      expect(reminderTimes.first, 6 * 60);
      expect(reminderTimes.last, 23 * 60);
    });
  });

  group('the events of the calendar', () {
    test('one for each payment that reminds, from its next time', () {
      final events = calendarReminders(
        [
          schedule('Аренда', 45000, CivilDate(2026, 11, 25)),
          schedule(
            'Интернет',
            650,
            CivilDate(2026, 11, 28),
            reminder: ScheduleReminder.dayBefore,
          ),
          schedule(
            'Спортзал',
            3500,
            CivilDate(2026, 12, 3),
            reminder: ScheduleReminder.none,
          ),
          schedule('Связь', 500, CivilDate(2026, 11, 30), day: 31),
        ],
        minutes: 9 * 60,
        sums: true,
      );

      expect(events, [
        CalendarReminder(
          title: 'Аренда · ${nb('45 000 ₽')}',
          first: CivilDate(2026, 11, 25),
          minutes: 9 * 60,
          every: ScheduleEvery.month,
          day: 25,
          early: false,
        ),
        CalendarReminder(
          title: 'Интернет · ${nb('650 ₽')}',
          first: CivilDate(2026, 11, 28),
          minutes: 9 * 60,
          every: ScheduleEvery.month,
          day: 28,
          early: true,
        ),
        CalendarReminder(
          title: 'Связь · ${nb('500 ₽')}',
          first: CivilDate(2026, 11, 30),
          minutes: 9 * 60,
          every: ScheduleEvery.month,
          day: 31,
          early: false,
        ),
      ]);
    });

    test('two for a salary in halves, each on its own day', () {
      final salary = schedule(
        'Зарплата',
        60000,
        CivilDate(2026, 11, 20),
        kind: TransactionKind.income,
        day: 5,
        advanceDay: 20,
      );

      expect(
        [
          for (final it in calendarReminders(
            [salary],
            minutes: 540,
            sums: false,
          ))
            (it.title, it.first, it.day),
        ],
        [
          ('Аванс', CivilDate(2026, 11, 20), 20),
          ('Зарплата', CivilDate(2026, 12, 5), 5),
        ],
      );
    });
  });

  test('the settings start off at 9:00 with the amounts and stay', () async {
    final store = MemorySettingsStore();
    expect(ReminderSettings.read(store), const ReminderSettings());

    await const ReminderSettings(
      notify: true,
      calendar: true,
      minutes: 20 * 60,
      sums: false,
    ).write(store);
    expect(
      ReminderSettings.read(store),
      const ReminderSettings(
        notify: true,
        calendar: true,
        minutes: 20 * 60,
        sums: false,
      ),
    );

    store.values['remind-time'] = '2000';
    expect(ReminderSettings.read(store).minutes, 9 * 60);
  });

  group('with the ledger', () {
    late BirkaDatabase database;
    late LedgerRepository ledger;
    late MemorySettingsStore store;
    late LedgerSchedulesRepository repository;
    late FakeChannel channel;
    late FakeCalendar calendar;
    late Account card;

    setUp(() async {
      database = BirkaDatabase(NativeDatabase.memory());
      ledger = LedgerRepository(
        database,
        now: () => DateTime.utc(2026, 11, 18, 9),
      );
      store = MemorySettingsStore();
      repository = LedgerSchedulesRepository(
        ledger,
        BaseCurrency(null),
        MonthStart(1),
        store,
        now: () => now,
      );
      channel = FakeChannel();
      calendar = FakeCalendar();
      card = await ledger.addAccount(
        name: 'Карта',
        type: AccountType.debit,
        openingBalance: rub(1000),
      );
      await ledger.addSchedule(
        kind: TransactionKind.expense,
        name: 'Аренда',
        accountId: card.id,
        amount: rub(45000),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 11, 25),
      );
    });
    tearDown(() => database.close());

    test('the phone gets the plan once the reminders are on', () async {
      final scheduler = ReminderScheduler(
        repository,
        channel,
        calendar,
        now: () => now,
      )..start();
      addTearDown(scheduler.stop);
      await pumpEventQueue();
      expect(channel.shown, [isEmpty]);

      await repository.saveReminders(const ReminderSettings(notify: true));
      await pumpEventQueue();
      expect(channel.shown.last.first.title, 'Аренда · ${nb('45 000 ₽')}');
      expect(channel.shown.last.first.day, CivilDate(2026, 11, 25));
      expect(channel.shown.last.first.minutes, 9 * 60);

      // The same plan leaves the phone alone.
      final shown = channel.shown.length;
      await scheduler.refresh();
      expect(channel.shown, hasLength(shown));

      await ledger.addSchedule(
        kind: TransactionKind.expense,
        name: 'Интернет',
        accountId: card.id,
        amount: rub(650),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 11, 28),
        reminder: ScheduleReminder.dayBefore,
      );
      await pumpEventQueue();
      expect(
        [
          for (final note in channel.shown.last)
            if (note.day == CivilDate(2026, 11, 27)) note.title,
        ],
        ['Интернет · ${nb('650 ₽')}'],
      );

      await repository.saveReminders(const ReminderSettings());
      await pumpEventQueue();
      expect(channel.shown.last, isEmpty);
    });

    test('the cubit turns them on once the phone allows them', () async {
      final cubit = RemindersCubit(
        repository,
        channel,
        calendar,
        now: () => now,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();
      expect(cubit.state.notify, isFalse);
      expect(cubit.state.reminding, 1);
      expect(cubit.nearest?.day, CivilDate(2026, 11, 25));

      channel.answer = ReminderAccess.denied;
      expect(await cubit.enable(), isFalse);
      expect(cubit.state.denied, isTrue);
      expect(ReminderSettings.read(store).notify, isFalse);

      channel.answer = ReminderAccess.granted;
      expect(await cubit.enable(), isTrue);
      await pumpEventQueue();
      expect(cubit.state.notify, isTrue);
      expect(cubit.state.denied, isFalse);

      await cubit.timeChanged(20 * 60);
      await cubit.sumsChanged(sums: false);
      await cubit.disable();
      expect(
        ReminderSettings.read(store),
        const ReminderSettings(minutes: 20 * 60, sums: false),
      );
    });

    test('the calendar gets its events once it is on, and only then', () async {
      final scheduler = ReminderScheduler(
        repository,
        channel,
        calendar,
        now: () => now,
      )..start();
      addTearDown(scheduler.stop);
      await pumpEventQueue();
      expect(calendar.written, isEmpty);

      await repository.saveReminders(const ReminderSettings(calendar: true));
      await pumpEventQueue();
      expect(
        calendar.written.single.single.title,
        'Аренда · ${nb('45 000 ₽')}',
      );
      expect(channel.shown.last, isEmpty);

      // The same events leave the calendar alone.
      await scheduler.refresh();
      expect(calendar.written, hasLength(1));

      await repository.saveReminders(
        const ReminderSettings(calendar: true, sums: false),
      );
      await pumpEventQueue();
      expect(calendar.written.last.single.title, 'Аренда');
    });

    test('the cubit turns the calendar on and removes it', () async {
      final cubit = RemindersCubit(
        repository,
        channel,
        calendar,
        now: () => now,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();
      expect(cubit.state.calendar, isFalse);
      expect(cubit.state.events, 1);

      calendar.answer = ReminderAccess.denied;
      expect(await cubit.enableCalendar(), isFalse);
      expect(cubit.state.calendarDenied, isTrue);
      expect(ReminderSettings.read(store).calendar, isFalse);

      calendar.answer = ReminderAccess.granted;
      expect(await cubit.enableCalendar(), isTrue);
      await pumpEventQueue();
      expect(cubit.state.calendar, isTrue);

      expect(await cubit.disableCalendar(), isTrue);
      await pumpEventQueue();
      expect(calendar.removed, 1);
      expect(cubit.state.calendar, isFalse);

      // Without access the calendar stays, and the setting goes off anyway.
      await cubit.enableCalendar();
      calendar
        ..failRemove = true
        ..current = ReminderAccess.denied;
      expect(await cubit.disableCalendar(), isFalse);
      await pumpEventQueue();
      expect(cubit.state.calendar, isFalse);
      expect(cubit.state.calendarDenied, isTrue);

      await cubit.openSettings();
      expect(calendar.settings, 1);
    });

    test('the notices take the reminders that came and wait for the next '
        'one', () async {
      await ledger.addSchedule(
        kind: TransactionKind.expense,
        name: 'Спортзал',
        accountId: card.id,
        amount: rub(3500),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 11, 18),
      );
      await ledger.addSchedule(
        kind: TransactionKind.expense,
        name: 'Интернет',
        accountId: card.id,
        amount: rub(650),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 11, 19),
      );
      final waits = <Duration>[];
      final notices = ReminderNotices(
        repository,
        now: () => now,
        timer: (after, callback) {
          waits.add(after);
          return Timer(const Duration(days: 1), callback);
        },
      );
      addTearDown(notices.stop);

      notices.start();
      await pumpEventQueue();
      await notices.catchUp();

      final noted = (await ledger.watchNotices().first).cast<PaymentNotice>();
      expect(
        [for (final it in noted) (it.name, it.time, it.at)],
        [
          (
            'Спортзал',
            CivilDate(2026, 11, 18),
            DateTime(2026, 11, 18, 9).toUtc(),
          ),
        ],
      );
      // The internet reminds tomorrow at 9:00, a day less an hour on.
      expect(waits.last, const Duration(hours: 23, seconds: 1));
    });

    Future<Account> lend(
      String name,
      int rubles,
      CivilDate due, {
      bool reminds = true,
      DebtSide side = DebtSide.lent,
    }) async {
      final debt = await ledger.addAccount(
        name: name,
        type: AccountType.debt,
        openingBalance: rub(0),
        debt: DebtTerms(side: side, dueOn: due, reminds: reminds),
      );
      final lent = side == DebtSide.lent;
      await ledger.record(
        TransactionDraft.transfer(
          fromAccountId: lent ? card.id : debt.id,
          sent: rub(rubles),
          toAccountId: lent ? debt.id : card.id,
          received: rub(rubles),
          occurredOn: CivilDate(2026, 11, 1),
        ),
      );
      return debt;
    }

    test('the phone reminds of the day of an open debt beside the '
        'payments', () async {
      final masha = await lend('Маша', 3000, CivilDate(2026, 11, 20));
      await lend('Дима', 500, CivilDate(2026, 11, 21), reminds: false);
      await lend(
        'Саша',
        4000,
        CivilDate(2026, 11, 25),
        side: DebtSide.borrowed,
      );
      final scheduler = ReminderScheduler(
        repository,
        channel,
        calendar,
        now: () => now,
      )..start();
      addTearDown(scheduler.stop);
      await repository.saveReminders(const ReminderSettings(notify: true));
      await pumpEventQueue();

      // The rent comes every month; November is enough here.
      expect(
        [
          for (final note in channel.shown.last)
            if (note.day.month == 11) (note.day, note.title),
        ],
        [
          (CivilDate(2026, 11, 20), 'Срок сегодня · Маша, ${nb('3 000 ₽')}'),
          (CivilDate(2026, 11, 25), 'Аренда · ${nb('45 000 ₽')}'),
          (CivilDate(2026, 11, 25), 'Срок сегодня · Саша, ${nb('4 000 ₽')}'),
        ],
      );
      expect(channel.shown.last.first.tap, DebtReminderTap(masha.id));

      await ledger.record(
        TransactionDraft.transfer(
          fromAccountId: masha.id,
          sent: rub(3000),
          toAccountId: card.id,
          received: rub(3000),
          occurredOn: CivilDate(2026, 11, 18),
        ),
      );
      await pumpEventQueue();
      expect(
        [for (final note in channel.shown.last) note.title],
        isNot(contains(startsWith('Срок сегодня · Маша'))),
      );
    });

    test('the cubit counts the debts whose day is still to come', () async {
      await lend('Маша', 3000, CivilDate(2026, 11, 20));
      await lend('Дима', 500, CivilDate(2026, 11, 21), reminds: false);
      await lend('Ира', 1500, CivilDate(2026, 11, 2));
      final cubit = RemindersCubit(
        repository,
        channel,
        calendar,
        now: () => now,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();

      expect(cubit.state.debts, 1);
      expect(cubit.state.reminding, 1);
    });

    test('the notices take the day of a debt that came', () async {
      final masha = await lend('Маша', 3000, CivilDate(2026, 11, 18));
      await lend('Дима', 500, CivilDate(2026, 11, 19));
      final waits = <Duration>[];
      final notices = ReminderNotices(
        repository,
        now: () => now,
        timer: (after, callback) {
          waits.add(after);
          return Timer(const Duration(days: 1), callback);
        },
      );
      addTearDown(notices.stop);

      notices.start();
      await pumpEventQueue();
      await notices.catchUp();

      final noted = (await ledger.watchNotices().first).cast<DebtNotice>();
      expect(
        [for (final it in noted) (it.debtId, it.due, it.owed, it.at)],
        [
          (
            masha.id,
            CivilDate(2026, 11, 18),
            rub(3000),
            DateTime(2026, 11, 18, 9).toUtc(),
          ),
        ],
      );
      // The day of Дима comes tomorrow at 9:00, a day less an hour on.
      expect(waits.last, const Duration(hours: 23, seconds: 1));
    });

    test('the form follows the settings of the reminders', () async {
      final form = ScheduleFormCubit(repository);
      addTearDown(form.close);
      await pumpEventQueue();
      expect(form.state.reminders, const ReminderSettings());

      await repository.saveReminders(const ReminderSettings(notify: true));
      await pumpEventQueue();
      expect(form.state.reminders?.notify, isTrue);
    });
  });
}
