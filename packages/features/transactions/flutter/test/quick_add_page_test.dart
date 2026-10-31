import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart' hide Category;
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/transactions_flutter.dart';

final class _FakeRepository implements TransactionsRepository {
  _FakeRepository({
    this.accountList = const [],
    this.expenses = const [],
    this.income = const [],
  });

  List<Account> accountList;
  List<Category> expenses;
  List<Category> income;
  final recorded = <TransactionDraft>[];
  Exception? failure;
  Exception? readFailure;

  @override
  Future<List<Account>> accounts() async {
    if (readFailure case final failure?) throw failure;
    return accountList;
  }

  @override
  Future<List<Category>> categories(CategoryKind kind) async =>
      kind == CategoryKind.expense ? expenses : income;

  @override
  Future<String?> lastAccountId() async => null;

  @override
  Future<void> record(TransactionDraft draft) async {
    if (failure case final failure?) throw failure;
    recorded.add(draft);
  }
}

Account _account(String name, {Currency currency = Currency.rub}) => Account(
  id: name,
  name: name,
  type: AccountType.debit,
  openingBalance: Money.zero(currency),
  includeInTotals: true,
  archived: false,
  sortOrder: 0,
);

Category _category(String name, {CategoryKind kind = CategoryKind.expense}) =>
    Category(
      id: name,
      kind: kind,
      name: name,
      archived: false,
      sortOrder: 0,
      icon: 'cart',
      color: '#4ade80',
    );

void main() {
  const space = ' ';
  final now = DateTime(2026, 10, 31, 9, 30);

  late _FakeRepository repository;
  var closed = 0;
  var addedAccounts = 0;
  var addedCategories = 0;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider(
          create: (_) => QuickAddCubit(repository, now: () => now),
          child: QuickAddPage(
            onClose: () => closed++,
            onAddAccount: () async => addedAccounts++,
            onAddCategories: () async => addedCategories++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, String keys) async {
    for (final key in keys.split('')) {
      await tester.tap(find.widgetWithText(GestureDetector, key).first);
      await tester.pump();
    }
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  BirkaButton save(WidgetTester tester) =>
      tester.widget<BirkaButton>(find.byType(BirkaButton));

  setUp(() {
    repository = _FakeRepository(
      accountList: [_account('Карта'), _account('Наличные')],
      expenses: [_category('Кафе'), _category('Продукты')],
      income: [_category('Зарплата', kind: CategoryKind.income)],
    );
    closed = 0;
    addedAccounts = 0;
    addedCategories = 0;
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('records an expense in three steps and closes', (tester) async {
    await pump(tester);

    await press(tester, '250');
    await tapText(tester, 'Кафе');
    await tapText(tester, 'СОХРАНИТЬ · КАФЕ');

    final draft = repository.recorded.single;
    expect(draft.entries.single.accountId, 'Карта');
    expect(draft.entries.single.amount, Money(-25000, Currency.rub));
    expect(draft.allocations.single.categoryId, 'Кафе');
    expect(closed, 1);
  });

  testWidgets('saving waits for the amount and the category', (tester) async {
    await pump(tester);
    expect(save(tester).onPressed, isNull);

    await press(tester, '5');
    expect(save(tester).onPressed, isNull);

    await tapText(tester, 'Кафе');
    expect(save(tester).onPressed, isNotNull);
  });

  testWidgets('shows the sum while it adds up', (tester) async {
    await pump(tester);

    await press(tester, '250');
    await tester.tap(find.bySemanticsLabel('Плюс'));
    await tester.pump();
    await press(tester, '120');

    expect(find.text('250 + 120'), findsOneWidget);
    expect(find.text('−370$space₽'), findsOneWidget);
  });

  testWidgets('the key with the point follows the language', (tester) async {
    await pump(tester);

    await press(tester, '1,5');

    expect(find.text('−1,50$space₽'), findsOneWidget);
  });

  testWidgets('the key that erases takes the last digit back', (tester) async {
    await pump(tester);

    await press(tester, '25');
    await tester.tap(find.bySemanticsLabel('Стереть'));
    await tester.pump();

    expect(find.text('−2$space₽'), findsOneWidget);
  });

  testWidgets('an income takes the categories of income', (tester) async {
    await pump(tester);

    await tapText(tester, 'ДОХОД');
    expect(find.text('Кафе'), findsNothing);

    await press(tester, '100');
    expect(find.text('+100$space₽'), findsOneWidget);

    await tapText(tester, 'Зарплата');
    await tapText(tester, 'СОХРАНИТЬ · ЗАРПЛАТА');
    expect(repository.recorded.single.kind, TransactionKind.income);
  });

  testWidgets('yesterday moves the day', (tester) async {
    await pump(tester);

    await press(tester, '5');
    await tapText(tester, 'Кафе');
    await tapText(tester, 'Вчера');
    await tapText(tester, 'СОХРАНИТЬ · КАФЕ');

    expect(repository.recorded.single.occurredOn, CivilDate(2026, 10, 30));
  });

  testWidgets('the account comes from a sheet', (tester) async {
    await pump(tester);

    await tapText(tester, 'Карта');
    await tapText(tester, 'Наличные');
    expect(find.text('Наличные'), findsOneWidget);

    await press(tester, '5');
    await tapText(tester, 'Кафе');
    await tapText(tester, 'СОХРАНИТЬ · КАФЕ');
    expect(repository.recorded.single.entries.single.accountId, 'Наличные');
  });

  testWidgets('a note comes from a sheet and stays on the chip', (
    tester,
  ) async {
    await pump(tester);

    await tapText(tester, '+ Заметка');
    await tester.enterText(find.byType(TextField), 'Кофе с собой');
    await tapText(tester, 'ГОТОВО');

    expect(find.text('Кофе с собой'), findsOneWidget);
    await press(tester, '5');
    await tapText(tester, 'Кафе');
    await tapText(tester, 'СОХРАНИТЬ · КАФЕ');
    expect(repository.recorded.single.note, 'Кофе с собой');
  });

  group('a transfer', () {
    testWidgets('picks the other account', (tester) async {
      await pump(tester);

      await tapText(tester, 'ПЕРЕВОД');
      expect(find.text('Куда'), findsOneWidget);
      await press(tester, '100');
      await tapText(tester, 'Наличные');
      await tapText(tester, 'СОХРАНИТЬ · НАЛИЧНЫЕ');

      final [from, to] = repository.recorded.single.entries;
      expect(from.accountId, 'Карта');
      expect(to.accountId, 'Наличные');
    });

    testWidgets('between currencies asks for both amounts', (tester) async {
      repository.accountList = [
        _account('Карта'),
        _account('Евро', currency: Currency.eur),
      ];
      await pump(tester);

      await tapText(tester, 'ПЕРЕВОД');
      await tapText(tester, 'Евро');
      await press(tester, '900');
      expect(save(tester).onPressed, isNull);

      await tapText(tester, 'Зачислить');
      await press(tester, '10');
      await tapText(tester, 'СОХРАНИТЬ · ЕВРО');

      final [from, to] = repository.recorded.single.entries;
      expect(from.amount, Money(-90000, Currency.rub));
      expect(to.amount, Money(1000, Currency.eur));
    });

    testWidgets('with one account it asks for another', (tester) async {
      repository.accountList = [_account('Карта')];
      await pump(tester);

      await tapText(tester, 'ПЕРЕВОД');
      expect(find.text('Для перевода нужен второй счёт.'), findsOneWidget);

      await tapText(tester, 'ДОБАВИТЬ СЧЁТ');
      expect(addedAccounts, 1);
    });
  });

  group('the categories on the sheet', () {
    setUp(() {
      repository.expenses = [
        for (var i = 0; i < 9; i++) _category('К$i'),
      ];
    });

    testWidgets('the rest are one tap away', (tester) async {
      await pump(tester);
      expect(find.text('К8'), findsNothing);

      await tapText(tester, 'Ещё');
      await tapText(tester, 'К8');

      expect(find.text('К8'), findsOneWidget);
      expect(find.text('Все категории'), findsNothing);
      await press(tester, '5');
      await tapText(tester, 'СОХРАНИТЬ · К8');
      expect(repository.recorded.single.allocations.single.categoryId, 'К8');
    });
  });

  testWidgets('without accounts it leads to adding one', (tester) async {
    repository.accountList = [];
    await pump(tester);

    expect(find.text('Пока нет счетов'), findsOneWidget);
    expect(find.byType(GlassKeypad), findsNothing);

    repository.accountList = [_account('Карта')];
    await tapText(tester, 'ДОБАВИТЬ СЧЁТ');

    expect(addedAccounts, 1);
    expect(find.byType(GlassKeypad), findsOneWidget);
  });

  testWidgets('without categories it leads to adding them', (tester) async {
    repository.expenses = [];
    await pump(tester);

    await tapText(tester, 'ДОБАВИТЬ КАТЕГОРИИ');

    expect(addedCategories, 1);
  });

  testWidgets('a failed save says so and stays', (tester) async {
    repository.failure = Exception('disk full');
    await pump(tester);

    await press(tester, '5');
    await tapText(tester, 'Кафе');
    await tapText(tester, 'СОХРАНИТЬ · КАФЕ');

    expect(
      find.text('Не удалось сохранить. Попробуйте ещё раз.'),
      findsOneWidget,
    );
    expect(closed, 0);
  });

  testWidgets('choices it cannot read offer another try', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester);

    expect(
      find.text('Не удалось прочитать счета и категории.'),
      findsOneWidget,
    );
    expect(find.text('ДОБАВИТЬ СЧЁТ'), findsNothing);

    repository.readFailure = null;
    await tapText(tester, 'ПОВТОРИТЬ');

    expect(find.byType(GlassKeypad), findsOneWidget);
    expect(addedAccounts, 0);
  });

  testWidgets('reading again on the sheet does not speak of saving', (
    tester,
  ) async {
    repository.accountList = [_account('Карта')];
    await pump(tester);

    await tapText(tester, 'ПЕРЕВОД');
    repository.readFailure = Exception('disk');
    await tapText(tester, 'ДОБАВИТЬ СЧЁТ');

    expect(
      find.text('Не удалось прочитать счета и категории.'),
      findsOneWidget,
    );
    expect(find.byType(GlassKeypad), findsOneWidget);
  });

  testWidgets('the cross closes without saving', (tester) async {
    await pump(tester);

    await press(tester, '5');
    await tester.tap(find.bySemanticsLabel('Закрыть'));

    expect(closed, 1);
    expect(repository.recorded, isEmpty);
  });

  testWidgets('fits a small phone by scrolling', (tester) async {
    await pump(tester);
    tester.view.physicalSize = const Size(640, 1136);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GlassKeypad), findsOneWidget);
  });
}
