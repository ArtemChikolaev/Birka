@TestOn('vm')
library;

import 'dart:async';

import 'package:database/database.dart';
import 'package:device_settings/device_settings.dart';
import 'package:drift/native.dart';
import 'package:home_screen/home_screen.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:test/test.dart';

import 'fakes.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

/// A home screen that keeps what it was shown.
final class _Screen implements HomeScreen {
  final shown = <WidgetSnapshot>[];

  @override
  Future<void> show(WidgetSnapshot snapshot) async => shown.add(snapshot);

  @override
  Future<bool> canPin() async => false;

  @override
  Future<bool> pin() async => false;

  @override
  Stream<HomeAction> get actions => const Stream.empty();

  @override
  Stream<void> get pinned => const Stream.empty();
}

void main() {
  // Wednesday, November 18, 2026, the day of the boards: 1 744 ₽ a day,
  // 620 ₽ spent by noon, the salary on December 5.
  var clock = DateTime(2026, 11, 18, 12);
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late LedgerSchedulesRepository repository;
  late _Screen screen;
  late HomeWidgets widgets;
  late WidgetSums sums;
  late TodayWidgetFeed feed;
  late Account card;
  late Category cafe;
  late Schedule salary;

  /// The figures once [test] holds for them.
  Future<WidgetSnapshot> shown([
    bool Function(WidgetSnapshot snapshot)? test,
  ]) => widgets
      .watch()
      .firstWhere((it) => it.days.isNotEmpty && (test?.call(it) ?? true))
      .timeout(const Duration(seconds: 5));

  Future<void> spend(int rubles) => ledger.record(
    TransactionDraft.expense(
      accountId: card.id,
      allocations: [Allocation(categoryId: cafe.id, amount: rub(rubles))],
      occurredOn: CivilDate.of(clock),
    ),
  );

  setUp(() async {
    clock = DateTime(2026, 11, 18, 12);
    LocaleSettings.setLocaleSync(AppLocale.ru);
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database, now: () => clock.toUtc());
    repository = LedgerSchedulesRepository(
      ledger,
      BaseCurrency(null),
      MonthStart(1),
      MemorySettingsStore()..values['payday-aside'] = '1000000',
      now: () => clock,
    );
    card = await ledger.addAccount(
      name: 'Зарплатная карта',
      type: AccountType.debit,
      openingBalance: rub(86400),
    );
    await ledger.addAccount(
      name: 'Наличные',
      type: AccountType.cash,
      openingBalance: rub(3200),
    );
    cafe = await ledger.addCategory(kind: CategoryKind.expense, name: 'Кафе');
    final pay = await ledger.addCategory(
      kind: CategoryKind.income,
      name: 'Зарплата',
    );
    for (final (name, rubles, next) in [
      ('Аренда', 45000, CivilDate(2026, 11, 25)),
      ('Интернет', 650, CivilDate(2026, 11, 28)),
      ('Netflix', 799, CivilDate(2026, 12, 1)),
      ('Спортзал', 3500, CivilDate(2026, 12, 3)),
    ]) {
      await ledger.addSchedule(
        kind: TransactionKind.expense,
        name: name,
        accountId: card.id,
        amount: rub(rubles),
        every: ScheduleEvery.month,
        next: next,
      );
    }
    salary = await ledger.addSchedule(
      kind: TransactionKind.income,
      name: 'Зарплата',
      accountId: card.id,
      categoryId: pay.id,
      amount: rub(120000),
      every: ScheduleEvery.month,
      next: CivilDate(2026, 12, 5),
    );
    await spend(620);
    screen = _Screen();
    sums = WidgetSums(shown: true);
    widgets = HomeWidgets(screen, sums);
    feed = TodayWidgetFeed(repository, widgets)..start();
  });

  tearDown(() async {
    await feed.stop();
    await widgets.close();
    await database.close();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  test('today shows what is left of the day, tomorrow its new share', () async {
    final snapshot = await shown();

    expect(snapshot.sums, isTrue);
    final [today, tomorrow] = snapshot.days;
    expect(today.day, '2026-11-18');
    expect(today.kind, WidgetDayKind.plan);
    expect(today.label, 'Можно тратить сегодня');
    expect(today.labelShort, 'Можно сегодня');
    expect(today.figure, formatMoney(rub(1124)));
    expect(today.minor, 112400);
    expect(today.of, 'из ${formatMoney(rub(1744))} на день');
    expect(today.ofShort, 'из ${formatMoney(rub(1744))}');
    expect(today.spent, 'Потратили ${formatMoney(rub(620))}');
    expect(today.spentShort, 'потратили ${formatMoney(rub(620))}');
    expect(today.share, closeTo(620 / 1744, 0.0001));
    // Tomorrow splits what is left once today is out: 29 031 ₽ in 16 days.
    expect(tomorrow.day, '2026-11-19');
    expect(tomorrow.figure, formatMoney(rub(1814)));
    expect(tomorrow.of, 'из ${formatMoney(rub(1814))} на день');
    expect(tomorrow.spent, 'Потратили ${formatMoney(rub(0))}');
    expect(tomorrow.share, 0);
    expect(snapshot.words, {
      'expense': 'Расход',
      'income': 'Доход',
      'newOperation': 'Новая операция',
      'label': 'Можно тратить сегодня',
      'labelShort': 'Можно сегодня',
      'open': 'Откройте Birka, чтобы обновить',
    });
    expect(screen.shown, isNotEmpty);
  });

  test('a new expense reaches the widgets', () async {
    await shown();

    await spend(370);

    final after = await shown((it) => it.days.first.minor == 75400);
    expect(after.days.first.figure, formatMoney(rub(754)));
    expect(after.days.first.spent, 'Потратили ${formatMoney(rub(990))}');
  });

  test('a day over its share says so and tells about tomorrow', () async {
    await shown();

    await spend(1480);

    final over = (await shown(
      (it) => it.days.first.kind == WidgetDayKind.over,
    )).days.first;
    expect(over.label, 'Сегодня больше дневного');
    expect(over.labelShort, 'Больше дневного');
    expect(over.figure, formatMoney(rub(-356)));
    expect(over.spent, 'Завтра можно ${formatMoney(rub(1721))} в день');
    expect(over.spentShort, 'завтра ${formatMoney(rub(1721))}');
    expect(over.share, 1);
  });

  test('hidden amounts never leave the app', () async {
    await shown();

    sums.show(shown: false);
    await pumpEventQueue();

    final hidden = screen.shown.last;
    expect(hidden.sums, isFalse);
    for (final day in hidden.days) {
      expect(day.minor, isNull);
      for (final words in [
        day.figure,
        day.of,
        day.ofShort,
        day.spent,
        day.spentShort,
      ]) {
        expect(words, isNot(matches(RegExp(r'\d'))));
      }
    }
    final today = hidden.days.first;
    expect(today.figure, maskAmounts(formatMoney(rub(1124))));
    expect(today.of, 'из ${maskAmounts(formatMoney(rub(1744)))} на день');
    expect(today.spent, 'Потратили ${maskAmounts(formatMoney(rub(620)))}');
  });

  test('without a salary the widgets show what today took', () async {
    await shown();

    await repository.delete(salary.id);

    final snapshot = await shown(
      (it) => it.days.first.kind == WidgetDayKind.spent,
    );
    final [today, tomorrow] = snapshot.days;
    expect(today.label, 'Потратили сегодня');
    expect(today.labelShort, 'Потратили');
    expect(today.figure, formatMoney(rub(620)));
    expect(today.of, 'Укажите день зарплаты — покажем, сколько можно');
    expect(today.ofShort, 'сегодня');
    expect(today.spent, isEmpty);
    expect(tomorrow.day, '2026-11-19');
    expect(tomorrow.figure, formatMoney(rub(0)));
  });

  test('the words follow the language of the app', () async {
    await shown();

    LocaleSettings.setLocaleSync(AppLocale.en);

    final english = await shown(
      (it) => it.days.first.label == 'You can spend today',
    );
    expect(english.days.first.figure, formatMoney(rub(1124)));
    expect(english.days.first.of, 'of ${formatMoney(rub(1744))} a day');
    expect(english.words['expense'], 'Expense');
  });

  test('after a night the figures start from the new day', () async {
    await shown();

    clock = DateTime(2026, 11, 19, 8);
    await feed.calendarChecked();

    final next = await shown((it) => it.days.first.day == '2026-11-19');
    expect(next.days.first.figure, formatMoney(rub(1814)));
    expect(next.days.first.spent, 'Потратили ${formatMoney(rub(0))}');
  });
}
