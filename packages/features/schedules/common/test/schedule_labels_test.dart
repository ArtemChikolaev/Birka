import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:test/test.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

/// [text] with the spaces of formatted amounts.
String nb(String text) => text.replaceAll(' ', String.fromCharCode(0xA0));

Schedule rent({
  ScheduleEvery every = ScheduleEvery.month,
  ScheduleOnDay onDay = ScheduleOnDay.ask,
  TransactionKind kind = TransactionKind.expense,
  CivilDate? next,
}) => Schedule(
  id: 'rent',
  kind: kind,
  name: 'Аренда',
  accountId: 'card',
  amount: rub(45000),
  every: every,
  day: (next ?? CivilDate(2026, 11, 25)).day,
  next: next ?? CivilDate(2026, 11, 25),
  onDay: onDay,
  reminder: ScheduleReminder.onDay,
);

void main() {
  final today = CivilDate(2026, 11, 18);

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('says how often a payment comes and what its day does', () {
    expect(scheduleLine(rent(), today), 'каждый месяц 25-го · спросить');
    expect(
      scheduleLine(rent(onDay: ScheduleOnDay.post), today),
      'каждый месяц 25-го · проводится сам',
    );
    expect(
      everyLabel(rent(every: ScheduleEvery.week), today),
      'каждую неделю, по средам',
    );
    expect(
      everyLabel(
        rent(every: ScheduleEvery.year, next: CivilDate(2027, 3, 12)),
        today,
      ),
      'раз в год, 12 марта',
    );
  });

  test('says what was done to a payment on the day it was', () {
    final moved = rent(next: CivilDate(2026, 12, 25));
    Schedule done(ScheduleDone how, DateTime at) => moved.movedTo(
      moved.next,
      last: ScheduleLast(
        done: how,
        from: CivilDate(2026, 11, 25),
        on: CivilDate(2026, 11, 25),
        at: at,
      ),
    );
    final day = CivilDate(2026, 11, 25);
    final morning = DateTime(2026, 11, 25, 9);

    expect(
      doneLine(done(ScheduleDone.posted, morning), day),
      'проведён сегодня · следующий 25 декабря',
    );
    expect(
      doneLine(done(ScheduleDone.skipped, morning), day),
      'пропущен · следующий 25 декабря',
    );
    expect(
      doneLine(done(ScheduleDone.found, morning), day),
      'нашли в выписке · следующий 25 декабря',
    );
    expect(doneLine(done(ScheduleDone.posted, morning), day.addDays(1)), null);
    expect(doneLine(moved, day), null);
  });

  test('says which statement brought a payment', () {
    final found = rent(next: CivilDate(2026, 12, 25)).movedTo(
      CivilDate(2026, 12, 25),
      last: ScheduleLast(
        done: ScheduleDone.found,
        from: CivilDate(2026, 11, 25),
        on: CivilDate(2026, 11, 25),
        at: DateTime(2026, 11, 27, 20),
        importId: 'alfa',
      ),
    );
    LedgerImport statement(String? format) => LedgerImport(
      id: 'alfa',
      fileName: 'alfa.xlsx',
      firstDay: CivilDate(2026, 11, 1),
      lastDay: CivilDate(2026, 11, 27),
      importedAt: DateTime(2026, 11, 27, 20),
      transactions: 40,
      accountIds: const {'card'},
      format: format,
    );

    expect(
      foundTitle(found, statement('alfa')),
      'Нашли «Аренда» в выписке Альфа-Банка',
    );
    expect(foundTitle(found, statement(null)), 'Нашли «Аренда» в выписке');
    expect(foundTitle(found, null), 'Нашли «Аренда» в выписке');
    expect(
      foundText(found, CivilDate(2026, 11, 27)),
      '25 ноября · ${nb('−45 000 ₽')} · '
      'отметили платёж проведённым, копии не будет',
    );
  });

  test('names the advance and the halves of a salary', () {
    final salary = Schedule(
      id: 'salary',
      kind: TransactionKind.income,
      name: 'Зарплата',
      accountId: 'card',
      amount: rub(60000),
      every: ScheduleEvery.month,
      day: 5,
      advanceDay: 20,
      next: CivilDate(2026, 11, 20),
      onDay: ScheduleOnDay.ask,
      reminder: ScheduleReminder.onDay,
    );
    ScheduleLast posted(CivilDate on) => ScheduleLast(
      done: ScheduleDone.posted,
      from: on,
      on: on,
      at: DateTime(on.year, on.month, on.day, 9),
    );

    expect(
      scheduleLine(salary, today),
      'аванс 20-го и зарплата 5-го · спросить',
    );
    expect(occurrenceName(salary, CivilDate(2026, 11, 20)), 'Аванс');
    expect(occurrenceName(salary, CivilDate(2026, 12, 5)), 'Зарплата');
    expect(scheduleAmount(salary), nb('+60 000 ₽'));
    expect(scheduleTotal(salary), nb('+120 000 ₽'));
    expect(
      postedLabel(salary, salary.amount),
      'Провели «Аванс» · ${nb('+60 000 ₽')}',
    );
    expect(
      skippedLabel(salary, today),
      'Пропустили «Аванс» · спросим 5 декабря',
    );
    expect(
      doneLine(
        salary.movedTo(
          CivilDate(2026, 12, 5),
          last: posted(CivilDate(2026, 11, 20)),
        ),
        CivilDate(2026, 11, 20),
      ),
      'аванс проведён сегодня · зарплата 5 декабря',
    );
    expect(
      doneLine(
        salary.movedTo(
          CivilDate(2026, 12, 20),
          last: posted(CivilDate(2026, 12, 5)),
        ),
        CivilDate(2026, 12, 5),
      ),
      'зарплата проведена сегодня · аванс 20 декабря',
    );
  });

  test('suggests starting the months on the day of the salary', () {
    final salary = rent(
      kind: TransactionKind.income,
      next: CivilDate(2026, 12, 5),
    );

    expect(
      monthStartHint(salary, today: today, monthStart: 1),
      'Зарплата приходит 5-го: месяц можно начинать с этого дня, тогда '
      'ноябрь — с 5 ноября по 4 декабря.',
    );
    // Before the 5th, the month of today began in October.
    expect(
      monthStartHint(salary, today: CivilDate(2026, 11, 3), monthStart: 1),
      'Зарплата приходит 5-го: месяц можно начинать с этого дня, тогда '
      'октябрь — с 5 октября по 4 ноября.',
    );
    expect(monthStartHint(salary, today: today, monthStart: 5), isNull);
    expect(monthStartHint(null, today: today, monthStart: 1), isNull);
    expect(
      monthStartHint(
        rent(kind: TransactionKind.income, next: CivilDate(2026, 11, 30)),
        today: today,
        monthStart: 1,
      ),
      isNull,
    );
    expect(
      monthStartHint(
        rent(
          kind: TransactionKind.income,
          every: ScheduleEvery.week,
          next: CivilDate(2026, 11, 20),
        ),
        today: today,
        monthStart: 1,
      ),
      isNull,
    );
  });

  test('names days and dates', () {
    expect(dayLabel(today, today), 'сегодня');
    expect(dayLabel(CivilDate(2026, 11, 19), today), 'завтра');
    expect(dayLabel(CivilDate(2026, 12, 5), today), '5 декабря');
    expect(fullDate(CivilDate(2027, 3, 12), today), '12 марта 2027');
    expect(shortDate(CivilDate(2026, 11, 25)), '25 ноя');
    expect(weekdayLabel(CivilDate(2026, 11, 25)), 'ср');
  });

  test('shows the amount with the sign of its kind', () {
    expect(scheduleAmount(rent()), nb('−45 000 ₽'));
    expect(
      scheduleAmount(rent(kind: TransactionKind.income)),
      nb('+45 000 ₽'),
    );
    expect(
      scheduleAmount(rent(kind: TransactionKind.transfer)),
      nb('45 000 ₽'),
    );
  });

  test('says what posting and skipping did', () {
    expect(
      postedLabel(rent(), rub(43800)),
      'Провели «Аренда» · ${nb('−43 800 ₽')}',
    );
    expect(
      skippedLabel(rent(), today),
      'Пропустили «Аренда» · спросим 25 декабря',
    );
    expect(
      skippedLabel(rent(onDay: ScheduleOnDay.post), today),
      'Пропустили «Аренда» · следующий раз 25 декабря',
    );
  });

  test('counts payments and days in the right form, none included', () {
    expect(t.schedules.paymentsUntilMonth(n: 0), '0 платежей до конца месяца');
    expect(t.schedules.paymentsUntilPayday(n: 1), '1 платёж до зарплаты');
    expect(t.schedules.paymentsUntilPayday(n: 4), '4 платежа до зарплаты');
    expect(t.schedules.days(n: 0), '0 дней');
    expect(t.schedules.leftFor(n: 21), 'Остаётся на 21 день');
  });

  group('the money of the days', () {
    SpendingPlan plan({
      int spent = 620,
      SpendUntil until = SpendUntil.payday,
    }) => SpendingPlan.of(
      today: today,
      until: until,
      currency: Currency.rub,
      schedules: [
        rent(),
        Schedule(
          id: 'salary',
          kind: TransactionKind.income,
          name: 'Зарплата',
          accountId: 'card',
          amount: rub(120000),
          every: ScheduleEvery.month,
          day: 5,
          next: CivilDate(2026, 12, 5),
          onDay: ScheduleOnDay.ask,
          reminder: ScheduleReminder.onDay,
        ),
      ],
      counted: [
        AccountBalance(
          Account(
            id: 'card',
            name: 'Карта',
            type: AccountType.debit,
            openingBalance: rub(0),
            includeInTotals: true,
            archived: false,
            sortOrder: 0,
          ),
          rub(75000 - spent),
        ),
      ],
      todays: [
        Transaction(
          id: 'coffee',
          kind: TransactionKind.expense,
          occurredOn: today,
          note: '',
          status: TransactionStatus.cleared,
          source: TransactionSource.manual,
          entries: [Entry(accountId: 'card', amount: -rub(spent))],
          allocations: [Allocation(categoryId: null, amount: rub(spent))],
        ),
      ],
      aside: rub(0),
    )!;

    test('names its period', () {
      expect(planPeriodLabel(plan()), 'до зарплаты 5 декабря · 17 дней');
      expect(
        planPeriodLabel(plan(until: SpendUntil.monthEnd)),
        'до 30 ноября · 13 дней',
      );
    });

    test('says what was spent, and what tomorrow allows after too much', () {
      expect(
        spentLabel(plan()),
        'Потратили ${nb('620 ₽')} · до зарплаты 17 дней',
      );
      expect(
        spentLabel(plan(until: SpendUntil.monthEnd)),
        'Потратили ${nb('620 ₽')} · до конца месяца 13 дней',
      );
      // 30 000 ₽ for 17 days is 1 764 ₽ a day; 2 000 ₽ is over it, and the
      // 28 000 ₽ left make 1 750 ₽ for each of the 16 days after today.
      expect(
        spentLabel(plan(spent: 2000)),
        'Потратили ${nb('2 000 ₽')} · завтра можно ${nb('1 750 ₽')} в день',
      );
    });
  });
}
