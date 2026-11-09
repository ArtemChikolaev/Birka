import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:test/test.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

AccountBalance account(
  String id,
  int rubles, {
  AccountType type = AccountType.debit,
}) => AccountBalance(
  Account(
    id: id,
    name: id,
    type: type,
    openingBalance: rub(rubles),
    includeInTotals: true,
    archived: false,
    sortOrder: 0,
  ),
  rub(rubles),
);

Schedule schedule(
  String id,
  int rubles,
  CivilDate next, {
  TransactionKind kind = TransactionKind.expense,
  String accountId = 'card',
  String? toAccountId,
  ScheduleEvery every = ScheduleEvery.month,
  ScheduleOnDay onDay = ScheduleOnDay.ask,
}) => Schedule(
  id: id,
  kind: kind,
  name: id,
  accountId: accountId,
  toAccountId: toAccountId,
  amount: rub(rubles),
  every: every,
  day: next.day,
  next: next,
  onDay: onDay,
  reminder: ScheduleReminder.onDay,
);

Transaction spending(
  int rubles, {
  String accountId = 'card',
  TransactionSource source = TransactionSource.manual,
}) => Transaction(
  id: 'spent-$rubles',
  kind: TransactionKind.expense,
  occurredOn: CivilDate(2026, 11, 18),
  note: '',
  status: TransactionStatus.cleared,
  source: source,
  entries: [Entry(accountId: accountId, amount: -rub(rubles))],
  allocations: [Allocation(categoryId: null, amount: rub(rubles))],
);

void main() {
  // The story of the boards: Wednesday, November 18, 2026, the salary on the
  // 5th, the card and the cash counted, 10 000 ₽ aside.
  final today = CivilDate(2026, 11, 18);
  final schedules = [
    schedule('rent', 45000, CivilDate(2026, 11, 25)),
    schedule('internet', 650, CivilDate(2026, 11, 28)),
    schedule(
      'netflix',
      799,
      CivilDate(2026, 12, 1),
      onDay: ScheduleOnDay.post,
    ),
    schedule('gym', 3500, CivilDate(2026, 12, 3)),
    schedule(
      'salary',
      120000,
      CivilDate(2026, 12, 5),
      kind: TransactionKind.income,
    ),
    schedule(
      'insurance',
      24000,
      CivilDate(2027, 3, 12),
      every: ScheduleEvery.year,
    ),
  ];

  SpendingPlan? plan({
    int spent = 620,
    SpendUntil until = SpendUntil.payday,
    List<Schedule>? payments,
    List<Transaction>? todays,
    int aside = 10000,
    int monthStart = 1,
  }) => SpendingPlan.of(
    today: today,
    until: until,
    currency: Currency.rub,
    schedules: payments ?? schedules,
    // What the accounts hold now, after what was spent today.
    counted: [
      account('card', 86400 - spent),
      account('cash', 3200, type: AccountType.cash),
    ],
    todays: todays ?? [spending(spent)],
    aside: rub(aside),
    monthStart: monthStart,
  );

  group('until the salary', () {
    test('splits what is left after the payments between the days', () {
      final it = plan()!;

      expect(it.payday, CivilDate(2026, 12, 5));
      expect(it.end, CivilDate(2026, 12, 4));
      expect(it.days, 17);
      expect(it.morning, rub(89600));
      expect(it.payments.map((it) => it.schedule.id), [
        'rent',
        'internet',
        'netflix',
        'gym',
      ]);
      expect(it.paid, rub(49949));
      expect(it.free, rub(29651));
      expect(it.perDay, rub(1744));
      expect(it.spentToday, rub(620));
      expect(it.leftToday, rub(1124));
      expect(it.over, isFalse);
    });

    test('says what tomorrow allows once today took more than its share', () {
      final it = plan(spent: 2100)!;

      expect(it.perDay, rub(1744));
      expect(it.leftToday, rub(-356));
      expect(it.over, isTrue);
      expect(it.tomorrow, rub(1721));
    });

    test('has none without a regular income to a counted account', () {
      final noSalary = [
        for (final it in schedules)
          if (it.kind != TransactionKind.income) it,
      ];

      expect(plan(payments: noSalary), isNull);
      expect(
        plan(
          payments: [
            ...noSalary,
            schedule(
              'salary',
              120000,
              CivilDate(2026, 12, 5),
              kind: TransactionKind.income,
              accountId: 'savings',
            ),
          ],
        ),
        isNull,
      );
    });

    test('takes the salary of today as the one of the next month', () {
      final it = plan(
        payments: [
          schedule(
            'salary',
            120000,
            CivilDate(2026, 11, 18),
            kind: TransactionKind.income,
          ),
        ],
      )!;

      expect(it.payday, CivilDate(2026, 12, 18));
      expect(it.days, 30);
    });
  });

  test('counts until the end of the month when asked', () {
    final it = plan(until: SpendUntil.monthEnd)!;

    expect(it.end, CivilDate(2026, 11, 30));
    expect(it.days, 13);
    expect(it.paid, rub(45650));
    expect(it.perDay, rub(2611));
  });

  test('ends a month that starts on another day the day before', () {
    // A month from the day of the salary counts as far as the salary does.
    final fromPayday = plan(until: SpendUntil.monthEnd, monthStart: 5)!;
    expect(fromPayday.end, CivilDate(2026, 12, 4));
    expect(fromPayday.days, 17);
    expect(fromPayday.paid, rub(49949));
    expect(fromPayday.perDay, rub(1744));

    // The month from October 25 is not over before November 24.
    final from25th = plan(until: SpendUntil.monthEnd, monthStart: 25)!;
    expect(from25th.end, CivilDate(2026, 11, 24));
    expect(from25th.days, 7);
    expect(from25th.paid, rub(0));
  });

  test('counts a payment that waits for the person', () {
    final it = plan(
      payments: [
        ...schedules.where((it) => it.id != 'rent'),
        schedule('rent', 45000, CivilDate(2026, 11, 15)),
      ],
    )!;

    expect(it.payments.first.on, CivilDate(2026, 11, 15));
    expect(it.paid, rub(49949));
  });

  test('takes a transfer that leaves the counted accounts, not one between '
      'them', () {
    final it = plan(
      payments: [
        ...schedules,
        schedule(
          'save',
          5000,
          CivilDate(2026, 11, 20),
          kind: TransactionKind.transfer,
          toAccountId: 'savings',
        ),
        schedule(
          'cash',
          2000,
          CivilDate(2026, 11, 21),
          kind: TransactionKind.transfer,
          toAccountId: 'cash',
        ),
      ],
    )!;

    expect(it.paid, rub(49949 + 5000));
  });

  test('leaves the posts of regular payments and other days out of today', () {
    final it = plan(
      todays: [
        spending(620),
        spending(45000, source: TransactionSource.recurring),
        spending(300, accountId: 'savings'),
      ],
    )!;

    expect(it.spentToday, rub(620));
  });

  test('takes the operation of a statement that brought a payment as the '
      'payment, not as spending', () {
    final rent = schedules.first;
    final found = rent.movedTo(
      rent.after(rent.next),
      last: ScheduleLast(
        done: ScheduleDone.found,
        from: rent.next,
        on: rent.next,
        at: DateTime(2026, 11, 18, 9),
        transactionId: 'spent-45000',
      ),
    );

    final it = SpendingPlan.of(
      today: today,
      until: SpendUntil.payday,
      currency: Currency.rub,
      schedules: [found, ...schedules.skip(1)],
      counted: [
        account('card', 86400 - 620 - 45000),
        account('cash', 3200, type: AccountType.cash),
      ],
      todays: [
        spending(620),
        spending(45000, source: TransactionSource.import),
      ],
      aside: rub(10000),
    )!;

    // The same money of the day as before the rent left.
    expect(it.spentToday, rub(620));
    expect(it.paid, rub(4949));
    expect(it.perDay, rub(1744));
    expect(it.leftToday, rub(1124));
  });

  group('with an advance', () {
    // The salary of 120 000 ₽ in halves: the advance on the 20th, the rest
    // on the 5th, so the 5th brought only half and the card holds less.
    final salary = Schedule(
      id: 'salary',
      kind: TransactionKind.income,
      name: 'salary',
      accountId: 'card',
      amount: rub(60000),
      every: ScheduleEvery.month,
      day: 5,
      advanceDay: 20,
      next: CivilDate(2026, 11, 20),
      onDay: ScheduleOnDay.ask,
      reminder: ScheduleReminder.onDay,
    );
    final payments = [
      for (final it in schedules)
        if (it.id != 'salary') it,
      salary,
    ];

    SpendingPlan? halves({
      SpendUntil until = SpendUntil.payday,
      List<AccountBalance>? counted,
      CivilDate? on,
    }) => SpendingPlan.of(
      today: on ?? today,
      until: until,
      currency: Currency.rub,
      schedules: payments,
      counted:
          counted ??
          [
            account('card', 26400 - 620),
            account('cash', 3200, type: AccountType.cash),
          ],
      todays: [spending(620)],
      aside: rub(10000),
    );

    test('counts until the salary and takes the advance in', () {
      final it = halves()!;

      expect(it.payday, CivilDate(2026, 12, 5));
      expect(it.days, 17);
      expect(it.morning, rub(29600));
      expect(it.advances.map((a) => a.on), [CivilDate(2026, 11, 20)]);
      expect(it.advanced, rub(60000));
      expect(it.paid, rub(49949));
      expect(it.free, rub(29651));
      expect(it.near?.money, rub(19600));
      expect(it.near?.days, 2);
      expect(it.perDay, rub(1744));
      expect(it.leftToday, rub(1124));
      expect(it.short, isNull);
    });

    test('takes the advance in until the end of the month too', () {
      final it = halves(until: SpendUntil.monthEnd)!;

      expect(it.advanced, rub(60000));
      expect(it.paid, rub(45650));
      expect(it.perDay, rub(2611));
    });

    test('gives a day no more than the accounts allow before the advance', () {
      // 3 200 ₽ on the card cannot keep 10 000 ₽ aside until the advance.
      final empty = halves(counted: [account('card', 3200 - 620)])!;

      expect(empty.free, rub(3251));
      expect(empty.near?.money, rub(-6800));
      expect(empty.perDay, rub(0));
      expect(empty.short, rub(6800));

      final thin = halves(
        counted: [
          account('card', 7800 - 620),
          account('cash', 3200, type: AccountType.cash),
        ],
      )!;
      // 11 000 ₽ less 10 000 ₽ aside for the 18th and the 19th, though the
      // whole 17 days would allow 650 ₽ a day.
      expect(thin.near?.money, rub(1000));
      expect(thin.free.minorUnits ~/ thin.days ~/ 100, 650);
      expect(thin.perDay, rub(500));
      expect(thin.short, isNull);
    });

    test('takes an advance of its own in with its own amount', () {
      // 40 000 ₽ on the 20th, and the rest of the 120 000 ₽ on the 5th.
      final own = Schedule(
        id: 'salary',
        kind: TransactionKind.income,
        name: 'salary',
        accountId: 'card',
        amount: rub(80000),
        advanceAmount: rub(40000),
        every: ScheduleEvery.month,
        day: 5,
        advanceDay: 20,
        next: CivilDate(2026, 11, 20),
        onDay: ScheduleOnDay.ask,
        reminder: ScheduleReminder.onDay,
      );
      final it = SpendingPlan.of(
        today: today,
        until: SpendUntil.payday,
        currency: Currency.rub,
        schedules: [
          for (final it in payments)
            if (it.id != 'salary') it,
          own,
        ],
        counted: [
          account('card', 26400 - 620),
          account('cash', 3200, type: AccountType.cash),
        ],
        todays: [spending(620)],
        aside: rub(10000),
      )!;

      expect(it.advanced, rub(40000));
      expect(it.free, rub(29651 - 20000));
    });

    test('waits for the advance of today without a limit before it', () {
      final it = halves(on: CivilDate(2026, 11, 20))!;

      expect(it.advances.map((a) => a.on), [CivilDate(2026, 11, 20)]);
      expect(it.near, isNull);
      expect(it.payday, CivilDate(2026, 12, 5));
    });
  });

  test('gives no money to the days when the payments take it all', () {
    final it = plan(aside: 50000)!;

    expect(it.free.isNegative, isTrue);
    expect(it.perDay, rub(0));
    expect(it.leftToday, rub(-620));
    expect(it.tomorrow, rub(0));
  });
}
