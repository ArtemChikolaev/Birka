import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/transactions_jaspr.dart';

import 'fake_repository.dart';

void main() {
  const space = ' ';
  final now = DateTime(2026, 10, 31, 9, 30);

  late FakeRepository repository;
  var closed = 0;

  Future<void> pump(ComponentTester tester, {QuickAddSource? source}) async {
    tester.pumpComponent(
      BlocProvider(
        create: (_) =>
            QuickAddCubit(repository, now: () => now, source: source),
        child: QuickAddPage(
          onClose: () => closed++,
          addAccountHref: 'new-account',
          addCategoriesHref: 'categories',
        ),
      ),
    );
    await tester.pump();
  }

  List<String?> links() => [
    for (final element in find.tag('a').evaluate())
      (element.component as DomComponent).attributes?['href'],
  ];

  GlassKeypad keypad() =>
      find.byType(GlassKeypad).evaluate().single.component as GlassKeypad;

  BirkaForm form() =>
      find.byType(BirkaForm).evaluate().single.component as BirkaForm;

  Future<void> press(ComponentTester tester, String keys) async {
    keys.split('').forEach(keypad().press);
    await tester.pump();
  }

  Future<void> tap(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
  }

  Future<void> pickDay(ComponentTester tester, String day) async {
    (find.byType(BirkaDateChip).evaluate().single.component as BirkaDateChip)
        .onChanged(day);
    await tester.pump();
  }

  setUp(() {
    repository = FakeRepository(
      accountList: [testAccount('Карта'), testAccount('Наличные')],
      expenses: [testCategory('Кафе'), testCategory('Продукты')],
      income: [testCategory('Зарплата', kind: CategoryKind.income)],
    );
    closed = 0;
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('records an expense in three steps and closes', (
    tester,
  ) async {
    await pump(tester);

    await press(tester, '250');
    await tap(tester, 'Кафе');
    expect(find.text('Сохранить · Кафе'), findsOneComponent);
    // Where a click on the button of a real form ends.
    form().onSubmit();
    await tester.pump();

    final draft = repository.recorded.single;
    expect(draft.entries.single.accountId, 'Карта');
    expect(draft.entries.single.amount, Money(-25000, Currency.rub));
    expect(draft.allocations.single.categoryId, 'Кафе');
    expect(closed, 1);
  });

  testComponents('the Enter key saves', (tester) async {
    await pump(tester);

    await press(tester, '250');
    await tap(tester, 'Кафе');
    keypad().press('Enter');
    await tester.pump();

    expect(repository.recorded, hasLength(1));
    expect(closed, 1);
  });

  testComponents('saving waits for the amount and the category', (
    tester,
  ) async {
    await pump(tester);
    expect(form().ready, isFalse);

    await press(tester, '5');
    expect(form().ready, isFalse);

    await tap(tester, 'Кафе');
    expect(form().ready, isTrue);
  });

  testComponents('shows the sum while it adds up', (tester) async {
    await pump(tester);

    await press(tester, '250+120');

    expect(find.text('250 + 120'), findsOneComponent);
    expect(find.text('−370$space₽'), findsOneComponent);
  });

  testComponents('a long amount takes a smaller style to stay on a line', (
    tester,
  ) async {
    String style() =>
        (find.byType(AmountText).evaluate().single.component as AmountText)
            .textClass;

    await pump(tester);
    await press(tester, '1234');
    expect(style(), 'text-display');

    await press(tester, '567');
    expect(style(), 'text-title');
  });

  testComponents('the keys of the screen type too', (tester) async {
    await pump(tester);

    await tap(tester, '7');

    expect(find.text('−7$space₽'), findsOneComponent);
  });

  testComponents('the point follows the language', (tester) async {
    await pump(tester);

    await press(tester, '1.5');

    expect(find.text('−1,50$space₽'), findsOneComponent);
    expect(find.text(','), findsOneComponent);
  });

  testComponents('Backspace takes the last digit back', (tester) async {
    await pump(tester);

    await press(tester, '25');
    keypad().press('Backspace');
    await tester.pump();

    expect(find.text('−2$space₽'), findsOneComponent);
  });

  testComponents('an income takes the categories of income', (tester) async {
    await pump(tester);

    await tap(tester, 'Кафе');
    await tap(tester, 'Доход');

    expect(find.text('Зарплата'), findsOneComponent);
    expect(find.text('Кафе'), findsNothing);
    expect(form().ready, isFalse);
  });

  group('the day', () {
    Future<void> record(ComponentTester tester) async {
      await press(tester, '1');
      await tap(tester, 'Кафе');
      keypad().press('Enter');
      await tester.pump();
    }

    testComponents('yesterday moves it', (tester) async {
      await pump(tester);

      await tap(tester, 'Вчера');
      await record(tester);

      expect(repository.recorded.single.occurredOn, CivilDate(2026, 10, 30));
    });

    testComponents('the calendar takes an earlier one and shows it', (
      tester,
    ) async {
      await pump(tester);

      await pickDay(tester, '2026-09-15');

      expect(find.text('15 сентября'), findsOneComponent);
      await record(tester);
      expect(repository.recorded.single.occurredOn, CivilDate(2026, 9, 15));
    });

    testComponents('the calendar keeps to its dates', (tester) async {
      await pump(tester);
      final chip =
          find.byType(BirkaDateChip).evaluate().single.component
              as BirkaDateChip;
      expect(chip.value, '2026-10-31');
      expect(chip.first, '2000-01-01');
      expect(chip.last, '2026-10-31');
      expect(chip.label, isNull);

      for (final day in ['', 'nonsense', '2026-11-01', '1999-12-31']) {
        await pickDay(tester, day);
      }
      await record(tester);

      expect(repository.recorded.single.occurredOn, CivilDate(2026, 10, 31));
    });
  });

  testComponents('the account comes from a list that closes', (tester) async {
    await pump(tester);

    await tap(tester, 'Карта');
    await tap(tester, 'Наличные');
    await press(tester, '1');
    await tap(tester, 'Кафе');

    expect(find.text('RUB'), findsNothing);
    expect(find.text('Наличные'), findsOneComponent);
    keypad().press('Enter');
    await tester.pump();
    expect(repository.recorded.single.entries.single.accountId, 'Наличные');
  });

  testComponents('a note is typed in place', (tester) async {
    await pump(tester);

    (find.byType(BirkaChipField).evaluate().single.component as BirkaChipField)
        .onChanged('На вынос');
    await press(tester, '1');
    await tap(tester, 'Кафе');
    keypad().press('Enter');
    await tester.pump();

    expect(repository.recorded.single.note, 'На вынос');
  });

  group('a transfer', () {
    testComponents('picks the other account', (tester) async {
      await pump(tester);

      await tap(tester, 'Перевод');
      await press(tester, '100');
      await tap(tester, 'Наличные');
      expect(find.text('Сохранить · Наличные'), findsOneComponent);
      keypad().press('Enter');
      await tester.pump();

      final draft = repository.recorded.single;
      expect(draft.kind, TransactionKind.transfer);
      expect(draft.entries, hasLength(2));
    });

    testComponents('between currencies asks for both amounts', (tester) async {
      repository.accountList = [
        testAccount('Карта'),
        testAccount('Евро', currency: Currency.eur),
      ];
      await pump(tester);

      await tap(tester, 'Перевод');
      await tap(tester, 'Евро');
      await press(tester, '9000');
      expect(find.text('Списать'), findsOneComponent);
      await tap(tester, 'Зачислить');
      await press(tester, '100');

      expect(find.text('9${space}000$space₽'), findsOneComponent);
      expect(find.text('100$space€'), findsOneComponent);
      expect(form().ready, isTrue);
    });

    testComponents('with one account it asks for another', (tester) async {
      repository.accountList = [testAccount('Карта')];
      await pump(tester);

      await tap(tester, 'Перевод');

      expect(find.text('Для перевода нужен второй счёт.'), findsOneComponent);
      expect(links(), ['new-account']);
    });
  });

  group('with many categories', () {
    setUp(() {
      repository.expenses = [
        for (var i = 0; i < 12; i++) testCategory('Категория $i'),
      ];
    });

    testComponents('the rest are one click away', (tester) async {
      await pump(tester);

      expect(find.text('Категория 6'), findsOneComponent);
      expect(find.text('Категория 7'), findsNothing);

      await tap(tester, 'Ещё');

      expect(find.text('Категория 11'), findsOneComponent);
      expect(find.text('Ещё'), findsNothing);
    });
  });

  testComponents('without accounts it leads to adding one', (tester) async {
    repository.accountList = const [];
    await pump(tester);

    expect(find.text('Пока нет счетов'), findsOneComponent);
    expect(links(), ['new-account']);

    await tester.click(find.byType(GlassIconButton));
    expect(closed, 1);
  });

  testComponents('without categories it leads to adding them', (tester) async {
    repository.expenses = const [];
    await pump(tester);

    expect(
      find.text('Добавьте категории, чтобы разбирать траты.'),
      findsOneComponent,
    );
    expect(links(), ['categories']);
  });

  testComponents('a failed save says so and stays', (tester) async {
    repository.failure = Exception('disk full');
    await pump(tester);

    await press(tester, '5');
    await tap(tester, 'Кафе');
    keypad().press('Enter');
    await tester.pump();

    expect(
      find.text('Не удалось сохранить. Попробуйте ещё раз.'),
      findsOneComponent,
    );
    expect(closed, 0);
  });

  testComponents('choices it cannot read offer another try', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester);

    expect(
      find.text('Не удалось прочитать счета и категории.'),
      findsOneComponent,
    );

    repository.readFailure = null;
    await tap(tester, 'Повторить');
    await tester.pump();

    expect(find.text('Кафе'), findsOneComponent);
  });

  testComponents('an operation being changed says so and is saved over', (
    tester,
  ) async {
    final card = repository.accountList.first;
    final cafe = repository.expenses.first;
    repository.operations = [
      testOperation(
        'coffee',
        amount: Money(-25000, Currency.rub),
        account: card,
        category: cafe,
        note: 'Капучино',
      ),
    ];
    await pump(tester, source: const QuickAddSource.edit('coffee'));

    expect(find.text('Изменить операцию'), findsOneComponent);
    expect(find.text('−250$space₽'), findsOneComponent);
    expect(
      (find.byType(BirkaChipField).evaluate().single.component
              as BirkaChipField)
          .value,
      'Капучино',
    );

    await press(tester, '0');
    keypad().press('Enter');
    await tester.pump();

    expect(repository.recorded, isEmpty);
    expect(
      repository.amended['coffee']!.entries.single.amount,
      Money(-250000, Currency.rub),
    );
    expect(closed, 1);
  });

  testComponents('the cross closes without saving', (tester) async {
    await pump(tester);

    await press(tester, '5');
    await tester.click(find.byType(GlassIconButton));

    expect(repository.recorded, isEmpty);
    expect(closed, 1);
  });
}
