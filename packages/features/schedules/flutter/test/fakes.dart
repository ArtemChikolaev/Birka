import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/schedules_common.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

/// [text] with the spaces of formatted amounts.
String nb(String text) => text.replaceAll(' ', String.fromCharCode(0xA0));

/// Wednesday, November 18, 2026, as on the boards.
final boardToday = CivilDate(2026, 11, 18);

Account account(
  String id,
  String name, {
  AccountType type = AccountType.debit,
  Currency currency = Currency.rub,
  int sortOrder = 0,
  String? lastDigits,
}) => Account(
  id: id,
  name: name,
  type: type,
  openingBalance: Money(0, currency),
  includeInTotals: true,
  archived: false,
  sortOrder: sortOrder,
  lastDigits: lastDigits,
);

Schedule schedule(
  String id,
  String name,
  int rubles,
  CivilDate next, {
  TransactionKind kind = TransactionKind.expense,
  String? categoryId,
  ScheduleEvery every = ScheduleEvery.month,
  ScheduleOnDay onDay = ScheduleOnDay.ask,
}) => Schedule(
  id: id,
  kind: kind,
  name: name,
  accountId: 'card',
  categoryId: categoryId,
  amount: rub(rubles),
  every: every,
  day: next.day,
  next: next,
  onDay: onDay,
  reminder: ScheduleReminder.onDay,
);

/// The payments of the boards.
List<Schedule> boardSchedules() => [
  schedule(
    'rent',
    'Аренда',
    45000,
    CivilDate(2026, 11, 25),
    categoryId: 'home',
  ),
  schedule(
    'net',
    'Интернет',
    650,
    CivilDate(2026, 11, 28),
    categoryId: 'home',
  ),
  schedule(
    'tv',
    'Netflix',
    799,
    CivilDate(2026, 12, 1),
    onDay: ScheduleOnDay.post,
  ),
  schedule('gym', 'Спортзал', 3500, CivilDate(2026, 12, 3)),
  schedule(
    'pay',
    'Зарплата',
    120000,
    CivilDate(2026, 12, 5),
    kind: TransactionKind.income,
  ),
  schedule(
    'car',
    'Страховка авто',
    24000,
    CivilDate(2027, 3, 12),
    every: ScheduleEvery.year,
  ),
];

/// [schedule] moved on from its next time, which was done as [done] at noon
/// of [at], as the ledger does.
Schedule doneAs(
  Schedule schedule,
  ScheduleDone done, {
  required CivilDate at,
  String? importId,
}) => schedule.movedTo(
  schedule.after(schedule.next),
  last: ScheduleLast(
    done: done,
    from: schedule.next,
    on: schedule.next,
    at: DateTime(at.year, at.month, at.day, 12),
    importId: importId,
  ),
);

/// The payments and accounts of the boards with the salary in halves: the
/// advance of 60 000 ₽ on the 20th and the rest on the 5th, so the card
/// holds what half a salary left.
FakeSchedulesRepository halvesRepository() {
  final repository = FakeSchedulesRepository()
    ..schedules = [
      for (final it in boardSchedules())
        if (it.id != 'pay') it,
      Schedule(
        id: 'pay',
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
      ),
    ];
  repository.accounts = [
    AccountBalance(
      account('card', 'Зарплатная карта', lastDigits: '4821'),
      rub(26400 - 620),
    ),
    ...repository.accounts.skip(1),
  ];
  return repository;
}

/// What was spent today on the card.
Transaction spent(int rubles) => Transaction(
  id: 'spent',
  kind: TransactionKind.expense,
  occurredOn: boardToday,
  note: '',
  status: TransactionStatus.cleared,
  source: TransactionSource.manual,
  entries: [Entry(accountId: 'card', amount: -rub(rubles))],
  allocations: [Allocation(categoryId: null, amount: rub(rubles))],
);

/// An expense on the card on [day], named [note], as a statement brings it.
Transaction paid(String id, CivilDate day, String note, int rubles) =>
    Transaction(
      id: id,
      kind: TransactionKind.expense,
      occurredOn: day,
      note: note,
      status: TransactionStatus.cleared,
      source: TransactionSource.import,
      entries: [Entry(accountId: 'card', amount: -rub(rubles))],
      allocations: [Allocation(categoryId: 'subs', amount: rub(rubles))],
    );

/// The operations of the boards that came every month: Яндекс Плюс on the
/// 12th since August, ЖКУ Москва about the 10th since September for 6 410 to
/// 7 120 ₽, and Облако Mail.ru on the 21st from August to October.
List<Transaction> boardFinds() => [
  for (final month in [8, 9, 10, 11])
    paid('plus-$month', CivilDate(2026, month, 12), 'Яндекс Плюс', 449),
  paid('zhku-9', CivilDate(2026, 9, 10), 'ЖКУ Москва', 6410),
  paid('zhku-10', CivilDate(2026, 10, 9), 'ЖКУ Москва', 6845),
  paid('zhku-11', CivilDate(2026, 11, 10), 'ЖКУ Москва', 7120),
  for (final month in [8, 9, 10])
    paid('cloud-$month', CivilDate(2026, month, 21), 'Облако Mail.ru', 149),
];

/// What the card spent each of the [days] days before the boards' today: the
/// usual pace of [rubles] a day.
List<Transaction> usualDays(int rubles, {int days = 92}) => [
  for (var i = 1; i <= days; i++)
    paid('usual-$i', boardToday.addDays(-i), '', rubles),
];

/// Keeps the regular payments in memory, and what was done to them.
final class FakeSchedulesRepository implements SchedulesRepository {
  /// Creates a repository of the boards, with [spentToday] spent on the card.
  FakeSchedulesRepository({int spentToday = 620, List<Schedule>? schedules})
    : schedules = schedules ?? boardSchedules(),
      accounts = [
        AccountBalance(
          account('card', 'Зарплатная карта', lastDigits: '4821'),
          rub(86400 - spentToday),
        ),
        AccountBalance(
          account('cash', 'Наличные', type: AccountType.cash, sortOrder: 1),
          rub(3200),
        ),
        AccountBalance(
          account(
            'savings',
            'Накопительный',
            type: AccountType.savings,
            sortOrder: 2,
          ),
          rub(250000),
        ),
        AccountBalance(
          account('wise', 'Wise', currency: Currency.usd, sortOrder: 3),
          Money(120000, Currency.usd),
        ),
      ],
      todays = [if (spentToday > 0) spent(spentToday)];

  List<Schedule> schedules;
  List<AccountBalance> accounts;
  List<Transaction> todays;

  /// Other operations of the ledger, such as one to make a payment of.
  List<Transaction> operations = const [];
  List<LedgerImport> imports = const [];
  PaydaySettings settings = const PaydaySettings(asideMinor: 1000000);
  final categories = [
    const Category(
      id: 'home',
      kind: CategoryKind.expense,
      name: 'Дом',
      color: '#22D3EE',
      archived: false,
      sortOrder: 0,
    ),
  ];

  final posted = <String>[];
  final skipped = <String>[];
  final added = <ScheduleDraft>[];
  final updated = <Schedule>[];
  final deleted = <String>[];
  final _changes = StreamController<void>.broadcast();

  /// Tells the watchers that something changed.
  void changed() => _changes.add(null);

  // A stream that a test can cancel at once, as the cubit does on close.
  Stream<T> _watch<T>(T Function() read) => Stream.multi((controller) {
    controller.add(read());
    final subscription = _changes.stream.listen((_) => controller.add(read()));
    // Nothing to wait for, so that `first` comes at once under fake time.
    controller.onCancel = () => unawaited(subscription.cancel());
  });

  /// The day the repository says it is.
  CivilDate day = boardToday;

  @override
  CivilDate today() => day;

  @override
  Stream<List<Schedule>> watchSchedules() => _watch(() => schedules);

  @override
  Stream<List<AccountBalance>> watchAccounts() => _watch(() => accounts);

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) => _watch(
    () => [
      for (final it in categories)
        if (it.kind == kind) it,
    ],
  );

  @override
  Stream<List<Transaction>> watchDay(CivilDate day) => _watch(
    () => [
      for (final it in todays)
        if (it.occurredOn == day) it,
    ],
  );

  @override
  Stream<Transaction?> watchTransaction(String id) => _watch(
    () => [...todays, ...operations].where((it) => it.id == id).firstOrNull,
  );

  /// What happened before today, for the operations that came every month.
  List<Transaction> history = const [];

  @override
  Stream<List<Transaction>> watchHistory(CivilDate from) => _watch(
    () => [
      for (final it in [...history, ...operations])
        if (it.occurredOn.compareTo(from) >= 0) it,
    ],
  );

  /// The finds that the person dismissed.
  Set<String> dismissed = const {};

  @override
  Stream<Set<String>> watchDismissedFinds() => _watch(() => dismissed);

  @override
  Future<void> dismissFind(String key, {bool dismissed = true}) async {
    this.dismissed = {
      for (final it in this.dismissed)
        if (it != key) it,
      if (dismissed) key,
    };
    changed();
  }

  @override
  Stream<Currency?> watchBaseCurrency() => Stream.value(null);

  /// The day the months start on.
  int monthStart = 1;

  @override
  Stream<int> watchMonthStart() => _watch(() => monthStart);

  @override
  Stream<List<LedgerImport>> watchImports() => _watch(() => imports);

  @override
  Stream<PaydaySettings> watchSettings() => _watch(() => settings);

  @override
  Future<void> saveSettings(PaydaySettings settings) async {
    this.settings = settings;
    changed();
  }

  /// How the device reminds.
  ReminderSettings reminders = const ReminderSettings();

  @override
  Stream<ReminderSettings> watchReminders() => _watch(() => reminders);

  @override
  Future<void> saveReminders(ReminderSettings settings) async {
    reminders = settings;
    changed();
  }

  @override
  Future<Schedule> add(ScheduleDraft draft) async {
    added.add(draft);
    final made = [
      ...todays,
      ...operations,
    ].where((it) => it.id == draft.madeFrom).firstOrNull;
    final schedule = Schedule(
      id: 'new',
      kind: draft.kind,
      name: draft.name,
      accountId: draft.accountId,
      toAccountId: draft.toAccountId,
      categoryId: draft.categoryId,
      amount: draft.amount,
      every: draft.every,
      day: draft.day ?? draft.next.day,
      advanceDay: draft.advanceDay,
      advanceAmount: draft.advanceAmount,
      next: draft.next,
      onDay: draft.onDay,
      reminder: draft.reminder,
      madeFrom: draft.madeFrom,
      last: made == null
          ? null
          : ScheduleLast(
              done: ScheduleDone.posted,
              from: made.occurredOn,
              on: made.occurredOn,
              at: DateTime(2026, 11, 18, 10),
              transactionId: made.id,
            ),
    );
    // One made from an operation joins the list, which its operation sees.
    if (made != null) {
      schedules = [...schedules, schedule];
      changed();
    }
    return schedule;
  }

  @override
  Future<void> update(Schedule schedule) async => updated.add(schedule);

  @override
  Future<void> delete(String id) async => deleted.add(id);

  @override
  Future<String> post(String id, {Money? amount, CivilDate? on}) async {
    posted.add(id);
    _done(id, ScheduleDone.posted);
    return 'transaction';
  }

  @override
  Future<void> skip(String id) async {
    skipped.add(id);
    _done(id, ScheduleDone.skipped);
  }

  void _done(String id, ScheduleDone done) {
    schedules = [
      for (final it in schedules) it.id == id ? doneAs(it, done, at: day) : it,
    ];
    changed();
  }

  @override
  Future<List<String>> postDue() async => const [];

  @override
  Future<void> noteReminders(List<PlannedReminder> reminders) async {}
}

/// [child] in the theme of Birka on a phone, with [cubit] above it.
Widget phone<C extends StateStreamableSource<Object?>>(
  C cubit,
  Widget child,
) => MaterialApp(
  theme: BirkaTheme.dark(),
  home: BlocProvider<C>.value(value: cubit, child: child),
);
