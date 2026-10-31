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
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final card = testAccount('Карта');
  final cash = testAccount('Наличные');
  final cafe = testCategory('Кафе');
  final food = testCategory('Продукты');
  final salary = testCategory('Зарплата', kind: CategoryKind.income);

  late FakeRepository repository;

  Future<void> pump(ComponentTester tester, {String? note}) async {
    tester.pumpComponent(
      BlocProvider(
        create: (_) => OperationsCubit(
          repository,
          now: () => DateTime(2026, 10, 31, 9, 30),
        ),
        child: OperationsPage(
          addHref: 'add',
          hrefOf: (id) => 'open/$id',
          note: note,
        ),
      ),
    );
    await tester.pump();
  }

  List<String?> links() => [
    for (final element in find.tag('a').evaluate())
      (element.component as DomComponent).attributes?['href'],
  ];

  Future<void> tap(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
  }

  Future<void> search(ComponentTester tester, String text) async {
    (find.byType(GlassSearchField).evaluate().single.component
            as GlassSearchField)
        .onChanged(text);
    await tester.pump();
  }

  setUp(() {
    repository = FakeRepository(
      accountList: [card, cash],
      operations: [
        testOperation(
          'coffee',
          amount: rub(-25000),
          account: card,
          category: cafe,
          note: 'Кофейня у дома',
        ),
        testOperation(
          'bread',
          amount: rub(-13000),
          account: cash,
          category: food,
        ),
        testOperation(
          'pay',
          amount: rub(10000000),
          account: card,
          category: salary,
          day: CivilDate(2026, 10, 30),
        ),
        testOperation(
          'move',
          amount: rub(-500000),
          account: card,
          toAccount: cash,
          kind: TransactionKind.transfer,
          day: CivilDate(2026, 10, 3),
        ),
        testOperation(
          'old',
          amount: rub(-100),
          account: card,
          category: food,
          day: CivilDate(2026, 9, 15),
          note: 'Прошлый месяц',
        ),
      ],
    );
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('shows the month day by day with its totals', (tester) async {
    await pump(tester);

    expect(find.text('Октябрь'), findsOneComponent);
    expect(find.text('Сегодня'), findsOneComponent);
    expect(find.text('Вчера'), findsOneComponent);
    expect(find.text('3 октября'), findsOneComponent);
    expect(find.text('Кофейня у дома'), findsOneComponent);
    expect(find.text('Кафе · Карта'), findsOneComponent);
    expect(find.text('Карта → Наличные'), findsOneComponent);
    // The day and the month it opens.
    expect(find.text('−380$space₽'), findsNComponents(2));
    expect(find.text('+100${space}000$space₽'), findsNComponents(3));
    expect(find.text('Прошлый месяц'), findsNothing);
  });

  testComponents('leads to every row', (tester) async {
    await pump(tester);

    expect(links(), [
      'open/coffee',
      'open/bread',
      'open/pay',
      'open/move',
    ]);
  });

  testComponents('says where the data lives', (tester) async {
    await pump(tester, note: 'Только в этом браузере');

    expect(find.text('Только в этом браузере'), findsOneComponent);
  });

  testComponents('a filter narrows the list', (tester) async {
    await pump(tester);

    await tap(tester, 'Переводы');

    expect(find.text('Карта → Наличные'), findsOneComponent);
    expect(find.text('Кофейня у дома'), findsNothing);
  });

  testComponents('the search narrows it, and an empty one brings it back', (
    tester,
  ) async {
    await pump(tester);

    await search(tester, 'кофей');
    expect(find.text('Кофейня у дома'), findsOneComponent);
    expect(find.text('Продукты'), findsNothing);

    await search(tester, '');
    expect(find.text('Продукты'), findsOneComponent);
  });

  testComponents('says when nothing is found, with nothing to do about it', (
    tester,
  ) async {
    await pump(tester);

    await search(tester, 'такси');

    expect(find.text('Ничего не нашлось'), findsOneComponent);
    expect(find.text('Пока нет операций'), findsNothing);
    expect(find.byType(BirkaButton), findsNothing);
  });

  testComponents('an empty month leads to the first operation', (tester) async {
    repository.operations = const [];
    await pump(tester);

    expect(find.text('Пока нет операций'), findsOneComponent);
    expect(links(), ['add']);
  });

  testComponents('another month can be picked', (tester) async {
    repository.monthList = [CivilDate(2026, 10, 1), CivilDate(2026, 9, 1)];
    await pump(tester);

    await tap(tester, 'Октябрь');
    await tester.pump();
    expect(find.text('Сентябрь'), findsOneComponent);
    expect(
      find.byComponentPredicate(
        (component) =>
            component is BirkaIcon && component.glyph == BirkaGlyph.check,
      ),
      findsOneComponent,
    );

    await tap(tester, 'Сентябрь');
    await tester.pump();

    expect(find.text('Прошлый месяц'), findsOneComponent);
    expect(find.text('Кофейня у дома'), findsNothing);
    // On the chip alone: the choice has closed.
    expect(find.text('Сентябрь'), findsOneComponent);
  });

  testComponents('the chip closes the choice of a month too', (tester) async {
    repository.monthList = [CivilDate(2026, 9, 1)];
    await pump(tester);

    await tap(tester, 'Октябрь');
    await tester.pump();
    await tap(tester, 'Октябрь');
    await tester.pump();

    expect(find.text('Сентябрь'), findsNothing);
  });

  testComponents('a month of another year says which', (tester) async {
    repository.monthList = [CivilDate(2025, 12, 1)];
    await pump(tester);

    await tap(tester, 'Октябрь');
    await tester.pump();

    expect(find.text('Декабрь 2025'), findsOneComponent);
  });

  testComponents('a failure offers another try', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester);

    expect(find.text('Не удалось прочитать операции.'), findsOneComponent);

    repository.readFailure = null;
    await tap(tester, 'Повторить');
    await tester.pump();

    expect(find.text('Кофейня у дома'), findsOneComponent);
  });

  testComponents('a correction has the picture of a check mark', (
    tester,
  ) async {
    repository.operations = [
      testOperation(
        'fix',
        amount: rub(5000),
        account: card,
        kind: TransactionKind.adjustment,
      ),
    ];
    await pump(tester);

    expect(find.text('Корректировка'), findsOneComponent);
    final badge =
        find.byType(GlyphBadge).evaluate().single.component as GlyphBadge;
    expect(badge.glyph, BirkaGlyph.check);
  });
}
