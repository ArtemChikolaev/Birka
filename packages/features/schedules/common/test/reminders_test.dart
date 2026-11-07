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
      expect(reminderNote(today, sums: true).tap, const ReminderTap('Аренда'));
      final early = reminderNote(
        at(rent, CivilDate(2026, 11, 25), CivilDate(2026, 11, 24)),
        sums: true,
      );
      expect(early.body, 'Завтра, 25 ноября. Нажмите, чтобы открыть платёж.');
      expect(early.tap, const ReminderTap('Аренда', early: true));
      final pay = reminderNote(
        at(salary, CivilDate(2026, 12, 5), CivilDate(2026, 12, 5)),
        sums: true,
      );
      expect(pay.title, 'Зарплата · ${nb('+120 000 ₽')}');
      expect(pay.body, 'Сегодня, проведётся само.');
    });

    test('a tap comes back from what the phone keeps', () {
      for (final tap in const [
        ReminderTap('0b7c1f2e-rent'),
        ReminderTap('0b7c1f2e-rent', early: true),
      ]) {
        expect(ReminderTap.parse(tap.payload), tap);
      }
      expect(const ReminderTap('rent').payload, 'rent');
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

    test('a time goes by the clock', () {
      expect(clockLabel(9 * 60), '9:00');
      expect(clockLabel(23 * 60 + 30), '23:30');
      expect(reminderTimes.first, 6 * 60);
      expect(reminderTimes.last, 23 * 60);
    });
  });

  test('the settings start off at 9:00 with the amounts and stay', () async {
    final store = MemorySettingsStore();
    expect(ReminderSettings.read(store), const ReminderSettings());

    await const ReminderSettings(
      notify: true,
      minutes: 20 * 60,
      sums: false,
    ).write(store);
    expect(
      ReminderSettings.read(store),
      const ReminderSettings(notify: true, minutes: 20 * 60, sums: false),
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
      final scheduler = ReminderScheduler(repository, channel, now: () => now)
        ..start();
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
      final cubit = RemindersCubit(repository, channel, now: () => now);
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
