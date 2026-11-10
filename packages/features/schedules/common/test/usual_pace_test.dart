import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:test/test.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

/// [text] with the spaces of formatted amounts.
String nb(String text) => text.replaceAll(' ', String.fromCharCode(0xA0));

AccountBalance account(String id, int rubles) => AccountBalance(
  Account(
    id: id,
    name: id,
    type: AccountType.debit,
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
}) => Schedule(
  id: id,
  kind: kind,
  name: id,
  accountId: 'card',
  amount: rub(rubles),
  every: ScheduleEvery.month,
  day: next.day,
  next: next,
  onDay: ScheduleOnDay.ask,
  reminder: ScheduleReminder.onDay,
);

/// An operation of [kind] of [rubles] on [day], from [account].
Transaction op(
  String id,
  CivilDate day,
  int rubles, {
  TransactionKind kind = TransactionKind.expense,
  String account = 'card',
  String note = '',
  TransactionSource source = TransactionSource.manual,
  TransactionStatus status = TransactionStatus.cleared,
}) => Transaction(
  id: id,
  kind: kind,
  occurredOn: day,
  note: note,
  status: status,
  source: source,
  entries: [
    Entry(
      accountId: account,
      amount: kind == TransactionKind.income ? rub(rubles) : -rub(rubles),
    ),
    if (kind == TransactionKind.transfer)
      Entry(accountId: 'savings', amount: rub(rubles)),
  ],
  allocations: [
    if (kind != TransactionKind.transfer)
      Allocation(categoryId: null, amount: rub(rubles)),
  ],
);

void main() {
  // The story of the boards: Wednesday, November 18, 2026, the salary on the
  // 5th, the card and the cash counted, 10 000 ₽ aside.
  final today = CivilDate(2026, 11, 18);
  final schedules = [
    schedule('rent', 45000, CivilDate(2026, 11, 25)),
    schedule('internet', 650, CivilDate(2026, 11, 28)),
    schedule('netflix', 799, CivilDate(2026, 12, 1)),
    schedule('gym', 3500, CivilDate(2026, 12, 3)),
    schedule(
      'salary',
      120000,
      CivilDate(2026, 12, 5),
      kind: TransactionKind.income,
    ),
  ];
  const counted = {'card', 'cash'};

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Money? pace(List<Transaction> history) => usualPace(
    history,
    today: today,
    counted: counted,
    schedules: schedules,
    currency: Currency.rub,
  );

  /// One expense of [rubles] a day over [days] days before today.
  List<Transaction> daily(int rubles, int days) => [
    for (var i = 1; i <= days; i++)
      op(
        'day-$i',
        today.addDays(-i),
        rubles,
        account: i.isEven ? 'card' : 'cash',
      ),
  ];

  test('is what the counted accounts spent a day over three months', () {
    final history = [
      // 18 August to 17 November: 92 days.
      ...daily(2100, 92),
      // Before the three months: it only tells that the ledger is older.
      op('old', CivilDate(2026, 8, 10), 90000),
      // Not everyday spending.
      op('move', CivilDate(2026, 10, 3), 50000, kind: TransactionKind.transfer),
      op('pay', CivilDate(2026, 10, 25), 45000, note: 'Rent'),
      op(
        'posted',
        CivilDate(2026, 10, 28),
        650,
        source: TransactionSource.recurring,
      ),
      op(
        'soon',
        CivilDate(2026, 11, 2),
        999,
        status: TransactionStatus.planned,
      ),
      op(
        'salary',
        CivilDate(2026, 11, 5),
        120000,
        kind: TransactionKind.income,
      ),
      op('other', CivilDate(2026, 11, 6), 7000, account: 'savings'),
      // Today is not over yet.
      op('today', today, 5000),
    ];

    expect(pace(history), rub(2100));
  });

  test('counts a younger ledger from its first operation, and a very young '
      'one not at all', () {
    expect(pace(daily(1500, 40)), rub(1500));
    expect(pace(daily(1500, 20)), isNull);
    expect(pace(const []), isNull);
  });

  test('rounds as a person would say it', () {
    expect(roughly(Money(679167, Currency.rub)), rub(6800));
    expect(roughly(rub(-6049)), rub(-6000));
    expect(roughly(rub(6650)), rub(6700));
    expect(roughly(rub(449)), rub(450));
  });

  group('the forecast', () {
    SpendingPlan plan({
      SpendUntil until = SpendUntil.payday,
      int aside = 10000,
    }) => SpendingPlan.of(
      today: today,
      until: until,
      currency: Currency.rub,
      schedules: schedules,
      counted: [account('card', 85780), account('cash', 3200)],
      todays: [op('spent', today, 620)],
      aside: rub(aside),
    )!;

    test('says when the money runs out at a pace above the plan', () {
      final it = SpendingForecast(plan(), rub(2100));

      expect(it.short, isTrue);
      expect(it.left, rub(-6049));
      expect(it.runsOut, CivilDate(2026, 12, 2));
      expect(forecastTitle(it), 'Деньги кончатся 2 декабря');
      expect(
        forecastText(it),
        'Обычно вы тратите ≈ ${nb('2 100 ₽')} в день, а можно '
        '${nb('1 744 ₽')}. К 5 декабря не хватит ≈ ${nb('6 000 ₽')}.',
      );
      expect(forecastLine(it), 'Как обычно — деньги кончатся 2 декабря');
      expect(forecastEnd(it.plan), '5 дек · зарплата');
      expect(forecastPlan(it.plan), 'по плану: ${nb('1 744 ₽')} в день');
    });

    test('says what is left at a pace below the plan', () {
      final it = SpendingForecast(plan(), rub(1500));

      expect(it.short, isFalse);
      expect(it.runsOut, isNull);
      expect(forecastTitle(it), 'Хватит до зарплаты');
      expect(
        forecastText(it),
        'Обычно вы тратите ≈ ${nb('1 500 ₽')} в день: к 5 декабря '
        'останется ≈ ${nb('4 200 ₽')}.',
      );
      expect(forecastLine(it), 'Как обычно — хватит до зарплаты');
    });

    test('counts to the end of the month when asked', () {
      final it = SpendingForecast(
        plan(until: SpendUntil.monthEnd),
        rub(2100),
      );

      expect(it.plan.days, 13);
      expect(forecastTitle(it), 'Хватит до конца месяца');
      expect(
        forecastText(it),
        'Обычно вы тратите ≈ ${nb('2 100 ₽')} в день: к 30 ноября '
        'останется ≈ ${nb('6 700 ₽')}.',
      );
      expect(forecastEnd(it.plan), '30 ноя');
    });

    test('says when the payments take all the money already', () {
      final it = SpendingForecast(plan(aside: 50000), rub(2100));

      expect(it.none, isTrue);
      expect(forecastTitle(it), 'Денег не хватает уже сейчас');
      expect(forecastText(it), 'Платежи до зарплаты больше, чем на счетах.');
      expect(forecastLine(it), isNull);
      expect(forecastPlan(it.plan), 'по плану');
    });
  });
}
