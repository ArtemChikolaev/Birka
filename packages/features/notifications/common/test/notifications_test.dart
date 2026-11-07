@TestOn('vm')
library;

import 'dart:async';

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:notifications_common/notifications_common.dart';
import 'package:test/test.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

/// Wednesday, November 25, 2026, 10:00 on this device, as on the boards.
final now = DateTime(2026, 11, 25, 10);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('the feed', () {
    late BirkaDatabase database;
    late LedgerRepository ledger;
    late LedgerNotificationsRepository repository;
    late Account card;

    setUp(() async {
      database = BirkaDatabase(NativeDatabase.memory());
      ledger = LedgerRepository(database, now: now.toUtc);
      repository = LedgerNotificationsRepository(ledger, now: () => now);
      card = await ledger.addAccount(
        name: 'Карта',
        type: AccountType.debit,
        openingBalance: rub(100000),
      );
    });

    tearDown(() => database.close());

    Future<Schedule> add(String name, CivilDate next) => ledger.addSchedule(
      kind: TransactionKind.expense,
      name: name,
      accountId: card.id,
      amount: rub(1000),
      every: ScheduleEvery.month,
      next: next,
    );

    Future<void> remind(Schedule schedule, DateTime at) => ledger.noteReminders(
      [(scheduleId: schedule.id, time: schedule.next, at: at)],
    );

    test('puts the new on top and the read below by days', () async {
      final rent = await add('Аренда', CivilDate(2026, 11, 25));
      final gym = await add('Спортзал', CivilDate(2026, 11, 3));
      await remind(gym, DateTime(2026, 11, 3, 9));
      await ledger.skipSchedule(gym.id);
      await ledger.readNotices();
      await remind(rent, DateTime(2026, 11, 25, 9));
      await ledger.addImport(
        fileName: 'alfa.xlsx',
        format: 'alfa',
        firstDay: CivilDate(2026, 11, 1),
        lastDay: CivilDate(2026, 11, 23),
      );
      final cubit = NotificationsCubit(repository);
      addTearDown(cubit.close);
      final summary = NotificationsSummaryCubit(repository);
      addTearDown(summary.close);
      await pumpEventQueue();

      final state = cubit.state;
      expect(state.status, NotificationsStatus.ready);
      expect(state.fresh.map((it) => it.source), [
        NoticeSource.import,
        NoticeSource.payment,
      ]);
      expect(state.days.map((it) => it.day), [CivilDate(2026, 11, 3)]);
      expect(state.sources, [NoticeSource.payment, NoticeSource.import]);
      expect(state.newOf(null), 2);
      expect(state.newOf(NoticeSource.payment), 1);
      expect(summary.state, 2);

      cubit.pick(NoticeSource.payment);
      expect(cubit.state.fresh.map((it) => it.source), [NoticeSource.payment]);

      await cubit.readAll();
      await pumpEventQueue();
      expect(cubit.state.fresh, isEmpty);
      expect(cubit.state.days.map((it) => it.day), [
        CivilDate(2026, 11, 25),
        CivilDate(2026, 11, 3),
      ]);
      expect(summary.state, 0);
    });

    test('marks the notice it opens and says where it leads', () async {
      final rent = await add('Аренда', CivilDate(2026, 11, 25));
      await remind(rent, DateTime(2026, 11, 25, 9));
      final cubit = NotificationsCubit(repository);
      addTearDown(cubit.close);
      await pumpEventQueue();

      final place = await cubit.open(cubit.state.fresh.single);
      await pumpEventQueue();

      expect(place, (place: NoticePlace.schedules, id: null));
      expect(cubit.state.fresh, isEmpty);
      expect(cubit.state.sources, isEmpty);
    });

    test('forgets what is older than 90 days', () async {
      final old = await add('Аренда', CivilDate(2026, 8, 25));
      await remind(old, DateTime(2026, 8, 25, 9));

      await repository.forgetOld();

      expect(await ledger.watchNotices().first, isEmpty);
    });

    test('is empty until something comes', () async {
      final cubit = NotificationsCubit(repository);
      addTearDown(cubit.close);
      await pumpEventQueue();

      expect(cubit.state.isEmpty, isTrue);
      unawaited(cubit.readAll());
    });
  });
}
