@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late DateTime now;
  late Account card;
  late Category home;

  setUp(() async {
    now = DateTime.utc(2026, 11, 25, 6);
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database, now: () => now);
    card = await ledger.addAccount(
      name: 'Card',
      type: AccountType.debit,
      openingBalance: rub(8640000),
    );
    home = await ledger.addCategory(kind: CategoryKind.expense, name: 'Home');
  });

  tearDown(() => database.close());

  Future<Schedule> addRent({
    ScheduleOnDay onDay = ScheduleOnDay.ask,
    CivilDate? next,
  }) => ledger.addSchedule(
    kind: TransactionKind.expense,
    name: 'Rent',
    accountId: card.id,
    categoryId: home.id,
    amount: rub(4500000),
    every: ScheduleEvery.month,
    next: next ?? CivilDate(2026, 11, 25),
    onDay: onDay,
  );

  Future<List<Notice>> notices() => ledger.watchNotices().first;

  Future<PaymentNotice> only() async =>
      (await notices()).single as PaymentNotice;

  /// The reminder of [time] of [schedule], which came at 9:00 UTC that day.
  ({String scheduleId, CivilDate time, DateTime at}) reminder(
    Schedule schedule,
    CivilDate time,
  ) => (
    scheduleId: schedule.id,
    time: time,
    at: DateTime.utc(time.year, time.month, time.day, 9),
  );

  group('a reminder', () {
    test('becomes a notice of its time once, at its moment', () async {
      final rent = await addRent();
      final time = CivilDate(2026, 11, 25);

      await ledger.noteReminders([reminder(rent, time)]);
      await ledger.noteReminders([reminder(rent, time)]);

      final notice = await only();
      expect(notice.scheduleId, rent.id);
      expect(notice.time, time);
      expect(notice.at, DateTime.utc(2026, 11, 25, 9));
      expect(notice.name, 'Rent');
      expect(notice.kind, TransactionKind.expense);
      expect(notice.amount, rub(4500000));
      expect(notice.postsItself, isFalse);
      expect(notice.outcome, isNull);
      expect(notice.isNew, isTrue);
    });

    test(
      'of a time done since, or of a payment that is gone, gives none',
      () async {
        final rent = await addRent();
        await ledger.skipSchedule(rent.id);
        final gone = await addRent(next: CivilDate(2026, 12, 1));
        await ledger.deleteSchedule(gone.id);

        await ledger.noteReminders([
          reminder(rent, CivilDate(2026, 11, 25)),
          reminder(gone, CivilDate(2026, 12, 1)),
        ]);

        expect(await notices(), isEmpty);
      },
    );
  });

  group('what becomes of a time', () {
    test('that the person posts tells its notice, which is no news to '
        'them', () async {
      final rent = await addRent();
      await ledger.noteReminders([reminder(rent, CivilDate(2026, 11, 25))]);
      now = DateTime.utc(2026, 11, 25, 9, 14);

      await ledger.postSchedule(rent.id);

      final notice = await only();
      expect(notice.outcome, NoticeOutcome.posted);
      expect(notice.outcomeAt, DateTime.utc(2026, 11, 25, 9, 14));
      expect(notice.next, CivilDate(2026, 12, 25));
      expect(notice.readAt, DateTime.utc(2026, 11, 25, 9, 14));
    });

    test('that the person skips tells its notice the next time', () async {
      final rent = await addRent();
      await ledger.noteReminders([reminder(rent, CivilDate(2026, 11, 25))]);

      await ledger.skipSchedule(rent.id);

      final notice = await only();
      expect(notice.outcome, NoticeOutcome.skipped);
      expect(notice.next, CivilDate(2026, 12, 25));
      expect(notice.isNew, isFalse);
    });

    test('that the person does without a reminder gives no notice', () async {
      final rent = await addRent();

      await ledger.postSchedule(rent.id);

      expect(await notices(), isEmpty);
    });

    test('that Birka posts itself gives a notice of each time', () async {
      final tv = await addRent(
        onDay: ScheduleOnDay.post,
        next: CivilDate(2026, 10, 1),
      );

      await ledger.postDueSchedules(CivilDate(2026, 11, 25));

      final all = (await notices()).cast<PaymentNotice>();
      expect(
        all.map((it) => it.time),
        [
          CivilDate(2026, 11, 1),
          CivilDate(2026, 10, 1),
        ]..sort((a, b) => b.compareTo(a)),
      );
      expect(all.map((it) => it.scheduleId).toSet(), {tv.id});
      expect(all.map((it) => it.outcome).toSet(), {NoticeOutcome.postedItself});
      expect(all.map((it) => it.postsItself).toSet(), {true});
      expect(all.map((it) => it.isNew).toSet(), {true});
      expect(all.first.next, CivilDate(2026, 12, 1));
    });

    test(
      'that a statement brings goes back when the import goes out',
      () async {
        final rent = await addRent(next: CivilDate(2026, 10, 25));
        await ledger.noteReminders([reminder(rent, CivilDate(2026, 10, 25))]);
        final importId = await ledger.addImport(
          fileName: 'alfa.csv',
          format: 'alfa',
          firstDay: CivilDate(2026, 10, 1),
          lastDay: CivilDate(2026, 10, 31),
        );
        final transactionId = await ledger.record(
          TransactionDraft.expense(
            accountId: card.id,
            allocations: [
              Allocation(categoryId: home.id, amount: rub(4500000)),
            ],
            occurredOn: CivilDate(2026, 10, 25),
            source: TransactionSource.import,
          ),
          importId: importId,
        );
        await ledger.findSchedule(
          rent.id,
          through: CivilDate(2026, 10, 25),
          transactionId: transactionId,
          importId: importId,
        );
        final found = (await notices()).whereType<PaymentNotice>().single;
        expect(found.outcome, NoticeOutcome.found);
        expect(found.isNew, isTrue);

        await ledger.undoImport(importId);

        final all = await notices();
        expect(all.whereType<PaymentNotice>().single.outcome, isNull);
        expect(all.whereType<ImportNotice>().single.undone, isTrue);
      },
    );
  });

  test(
    'an import tells how many of its transactions wait for a category',
    () async {
      now = DateTime.utc(2026, 11, 24, 18, 40);
      final importId = await ledger.addImport(
        fileName: 'alfa-2026-11.xlsx',
        format: 'alfa',
        firstDay: CivilDate(2026, 11, 1),
        lastDay: CivilDate(2026, 11, 23),
      );
      Future<String> operation({String? categoryId}) => ledger.record(
        TransactionDraft.expense(
          accountId: card.id,
          allocations: [Allocation(categoryId: categoryId, amount: rub(30000))],
          occurredOn: CivilDate(2026, 11, 20),
          source: TransactionSource.import,
        ),
        importId: importId,
      );
      await operation(categoryId: home.id);
      final waiting = await operation();
      await operation();

      expect(
        await notices(),
        [
          ImportNotice(
            id: (await notices()).single.id,
            at: DateTime.utc(2026, 11, 24, 18, 40),
            importId: importId,
            fileName: 'alfa-2026-11.xlsx',
            format: 'alfa',
            firstDay: CivilDate(2026, 11, 1),
            lastDay: CivilDate(2026, 11, 23),
            transactions: 3,
            waiting: 2,
          ),
        ],
      );

      await ledger.amend(
        waiting,
        TransactionDraft.expense(
          accountId: card.id,
          allocations: [Allocation(categoryId: home.id, amount: rub(30000))],
          occurredOn: CivilDate(2026, 11, 20),
          source: TransactionSource.import,
        ),
      );

      final notice = (await notices()).single as ImportNotice;
      expect((notice.transactions, notice.waiting), (3, 1));
    },
  );

  test('reading marks the notices that are new', () async {
    final rent = await addRent();
    final tv = await addRent(next: CivilDate(2026, 11, 26));
    await ledger.noteReminders([
      reminder(rent, CivilDate(2026, 11, 25)),
      reminder(tv, CivilDate(2026, 11, 26)),
    ]);
    final ids = (await notices()).map((it) => it.id).toList();
    expect(await ledger.watchNewNotices().first, 2);

    await ledger.readNotices([ids.last]);
    expect(await ledger.watchNewNotices().first, 1);
    await ledger.readNotices([]);
    expect(await ledger.watchNewNotices().first, 1);
    now = DateTime.utc(2026, 11, 25, 12);
    await ledger.readNotices();

    expect(await ledger.watchNewNotices().first, 0);
    expect(
      (await notices()).map((it) => it.readAt).toSet(),
      {DateTime.utc(2026, 11, 25, 6), DateTime.utc(2026, 11, 25, 12)},
    );
  });

  test('forgets the notices that came before a moment', () async {
    final rent = await addRent(next: CivilDate(2026, 8, 25));
    await ledger.noteReminders([
      reminder(rent, CivilDate(2026, 8, 25)),
      reminder(rent, CivilDate(2026, 9, 25)),
    ]);

    expect(
      await ledger.forgetNotices(before: DateTime.utc(2026, 9)),
      1,
    );

    expect((await only()).time, CivilDate(2026, 9, 25));
  });

  test('a payment whose next time moves, or that goes, drops the notices '
      'that wait', () async {
    final rent = await addRent(next: CivilDate(2026, 10, 25));
    await ledger.noteReminders([reminder(rent, CivilDate(2026, 10, 25))]);
    await ledger.postSchedule(rent.id);
    await ledger.noteReminders([reminder(rent, CivilDate(2026, 11, 25))]);
    expect(await notices(), hasLength(2));

    final moved = (await ledger.schedule(rent.id))!;
    await ledger.updateSchedule(moved.movedTo(CivilDate(2026, 11, 26)));
    expect(
      (await notices()).cast<PaymentNotice>().map((it) => it.outcome),
      [NoticeOutcome.posted],
    );

    await ledger.noteReminders([reminder(rent, CivilDate(2026, 11, 26))]);
    await ledger.deleteSchedule(rent.id);
    expect((await only()).outcome, NoticeOutcome.posted);
  });

  test('a wipe takes the notices with the ledger', () async {
    final rent = await addRent();
    await ledger.noteReminders([reminder(rent, CivilDate(2026, 11, 25))]);

    await ledger.wipe();

    expect(await notices(), isEmpty);
  });
}
