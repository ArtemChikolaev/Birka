import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart' show Currency;
import 'package:overview_common/overview_common.dart' hide Category;
import 'package:overview_flutter/overview_flutter.dart';

final class _FakeRepository implements OverviewRepository {
  _FakeRepository({
    this.accounts = const [],
    this.changes = const [],
    this.spending = const [],
  });

  List<AccountBalance> accounts;
  List<DayChange> changes;
  List<CategoryTotal> spending;
  Exception? readFailure;

  Stream<T> _read<T>(T value) => Stream.multi((controller) {
    if (readFailure case final failure?) {
      controller.addError(failure);
    } else {
      controller.add(value);
    }
  });

  @override
  Stream<List<AccountBalance>> watchAccounts() => _read(accounts);

  @override
  Stream<List<DayChange>> watchDayChanges({required CivilDate from}) =>
      _read(changes);

  @override
  Stream<List<CategoryTotal>> watchSpending({
    required CivilDate from,
    required CivilDate to,
  }) => _read(spending);
}

AccountBalance _account(String name, Money balance, {String? digits}) =>
    AccountBalance(
      Account(
        id: name,
        name: name,
        type: AccountType.debit,
        openingBalance: Money.zero(balance.currency),
        lastDigits: digits,
        includeInTotals: true,
        archived: false,
        sortOrder: 0,
      ),
      balance,
    );

CategoryTotal _total(String name, Money total) => CategoryTotal(
  Category(
    id: name,
    kind: CategoryKind.expense,
    name: name,
    archived: false,
    sortOrder: 0,
    color: '#4ade80',
  ),
  total,
);

void main() {
  const space = ' ';
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);

  late _FakeRepository repository;
  late DateTime now;
  late ValueNotifier<bool> hidden;
  var added = 0;
  var listed = 0;
  late List<String> opened;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      HiddenAmounts(
        notifier: hidden,
        child: MaterialApp(
          theme: BirkaTheme.dark(),
          home: Scaffold(
            body: BlocProvider(
              create: (_) => OverviewCubit(repository, now: () => now),
              child: OverviewPage(
                onAddAccount: () => added++,
                onAccounts: () => listed++,
                onOpenAccount: opened.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    now = DateTime(2026, 10, 31, 9, 30);
    hidden = ValueNotifier(false);
    added = 0;
    listed = 0;
    opened = [];
    repository = _FakeRepository(
      accounts: [
        _account('Зарплатная', rub(41230000), digits: '4568'),
        _account('Накопления', rub(64000000)),
        _account('Евро', eur(214000)),
      ],
      changes: [
        DayChange(CivilDate(2026, 10, 10), rub(4230000)),
        DayChange(CivilDate(2026, 10, 12), eur(100)),
      ],
      spending: [
        _total('Продукты', rub(2430000)),
        _total('Дом', rub(1728000)),
        _total('Кафе', rub(1285000)),
        _total('Такси', rub(100000)),
      ],
    );
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    hidden.dispose();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('shows the capital and what changed it', (tester) async {
    await pump(tester);

    expect(find.text('Октябрь'), findsOneWidget);
    expect(find.text('КАПИТАЛ · 2 ВАЛЮТЫ'), findsOneWidget);
    expect(find.text('1${space}052${space}300$space₽'), findsOneWidget);
    expect(find.text('2${space}140$space€'), findsOneWidget);
    expect(find.text('+42${space}300$space₽'), findsOneWidget);
    expect(find.text('за октябрь'), findsOneWidget);
    expect(find.byType(BirkaLineChart), findsOneWidget);
  });

  testWidgets('another period changes what the change covers', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Неделя'));
    await tester.pumpAndSettle();

    expect(find.text('+42${space}300$space₽'), findsNothing);

    await tester.tap(find.text('Год'));
    await tester.pumpAndSettle();

    expect(find.text('за год'), findsOneWidget);
  });

  testWidgets('a fall shows in its own color', (tester) async {
    repository.changes = [DayChange(CivilDate(2026, 10, 10), rub(-100000))];
    await pump(tester);

    final figure = tester.widget<AmountText>(
      find.widgetWithText(AmountText, '−1${space}000$space₽'),
    );
    expect(figure.tone, AmountTone.negative);
  });

  testWidgets('one currency says nothing of currencies', (tester) async {
    repository.accounts = [_account('Зарплатная', rub(100))];
    await pump(tester);

    expect(find.text('КАПИТАЛ'), findsOneWidget);
  });

  testWidgets('accounts outside the totals leave no capital to chart', (
    tester,
  ) async {
    repository.accounts = [
      AccountBalance(
        const Account(
          id: 'hidden',
          name: 'Скрытый',
          type: AccountType.cash,
          openingBalance: Money.zero(Currency.rub),
          includeInTotals: false,
          archived: false,
          sortOrder: 0,
        ),
        rub(100),
      ),
    ];
    await pump(tester);

    expect(find.byType(BirkaLineChart), findsNothing);
    expect(find.text('СКРЫТЫЙ'), findsOneWidget);
  });

  testWidgets('the accounts open from their cards', (tester) async {
    await pump(tester);

    expect(find.text('ЗАРПЛАТНАЯ'), findsOneWidget);
    expect(find.text('Рубли · •• 4568'), findsOneWidget);

    await tester.tap(find.text('ЗАРПЛАТНАЯ'));

    expect(opened, ['Зарплатная']);
  });

  testWidgets('the link leads to all the accounts', (tester) async {
    await pump(tester);

    await tester.tap(find.text('ВСЕ 3'));

    expect(listed, 1);
  });

  testWidgets('one account takes the whole row', (tester) async {
    repository.accounts = [_account('Зарплатная', rub(100))];
    await pump(tester);

    expect(tester.getSize(find.byType(AccountCard)).width, 350);
  });

  testWidgets('shows what the month cost', (tester) async {
    await pump(tester);

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('ТРАТЫ В ОКТЯБРЕ'), findsOneWidget);
    expect(find.text('−55${space}430$space₽'), findsOneWidget);
    expect(find.text('Продукты'), findsOneWidget);
    expect(find.text('24${space}300$space₽'), findsOneWidget);
    expect(find.text('Кафе'), findsOneWidget);
    expect(find.text('Такси'), findsNothing);
    expect(find.byType(BirkaRing), findsOneWidget);
  });

  testWidgets('other currencies stand under the categories', (tester) async {
    repository.spending = [
      _total('Продукты', rub(100)),
      _total('Продукты', eur(500)),
    ];
    await pump(tester);

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('5$space€'), findsOneWidget);
  });

  testWidgets('a month without spending says so', (tester) async {
    repository.spending = const [];
    await pump(tester);

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('В этом месяце трат пока нет.'), findsOneWidget);
    expect(find.byType(BirkaRing), findsNothing);
  });

  testWidgets('without accounts it leads to adding one', (tester) async {
    repository.accounts = const [];
    await pump(tester);

    expect(find.text('Пока нет счетов'), findsOneWidget);
    expect(find.byType(BirkaLineChart), findsNothing);

    await tester.tap(find.text('ДОБАВИТЬ СЧЁТ'));

    expect(added, 1);
  });

  testWidgets('the eye hides every amount and brings it back', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Скрыть суммы'));
    await tester.pumpAndSettle();

    expect(hidden.value, isTrue);
    expect(find.text('1${space}052${space}300$space₽'), findsNothing);
    expect(find.text('•••$space₽'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Показать суммы'));
    await tester.pumpAndSettle();

    expect(find.text('1${space}052${space}300$space₽'), findsOneWidget);
  });

  testWidgets('a failure offers another try', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester);

    expect(find.text('Не удалось прочитать обзор.'), findsOneWidget);

    repository.readFailure = null;
    await tester.tap(find.text('ПОВТОРИТЬ'));
    await tester.pumpAndSettle();

    expect(find.text('1${space}052${space}300$space₽'), findsOneWidget);
  });

  testWidgets('coming back in a new month follows the calendar', (
    tester,
  ) async {
    await pump(tester);

    now = DateTime(2026, 11, 1, 8);
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Ноябрь'), findsOneWidget);
  });

  testWidgets('the largest amounts fit a small phone', (tester) async {
    final most = Money(Money.maxMinorUnits, Currency.rub);
    repository
      ..accounts = [_account('a', most), _account('b', Money(5, Currency.usd))]
      ..spending = [
        _total('Очень длинное название категории расходов', most),
      ];
    await pump(tester);
    tester.view.physicalSize = const Size(640, 1136);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
