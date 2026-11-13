import 'package:ask_common/ask_common.dart';
import 'package:ask_common/testing.dart';
import 'package:ask_jaspr/ask_jaspr.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';

String nb(String text) => text.replaceAll(' ', String.fromCharCode(0xA0));

/// Where the link around [text] leads.
String? hrefOf(String text) =>
    (find
                .ancestor(of: find.text(text), matching: find.tag('a'))
                .evaluate()
                .first
                .component
            as DomComponent)
        .attributes?['href'];

/// The button that says [text].
Finder buttonOf(String text) =>
    find.ancestor(of: find.text(text), matching: find.tag('button')).first;

void main() {
  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  final asked = <String>[];
  final shown = <(int, String, String)>[];

  Future<AskCubit> pump(
    ComponentTester tester, {
    FakeAskRepository? repository,
    String question = '',
    bool wide = false,
    AskFactBuilder? fact,
  }) async {
    asked.clear();
    shown.clear();
    final cubit = AskCubit(repository ?? FakeAskRepository());
    addTearDown(cubit.close);
    if (question.isNotEmpty) cubit.ask(question);
    tester.pumpComponent(
      BlocProvider<AskCubit>.value(
        value: cubit,
        child: AskPage(
          question: question,
          wide: wide,
          onQuestion: asked.add,
          operationsHref: 'operations/',
          onShowOperations: (answer, title, question) =>
              shown.add((answer.count, title, question)),
          hrefOfOperation: (id) => 'operations/#$id',
          hrefOfTag: (id) => 'tags/#$id',
          hrefOfPlace: (place) =>
              place == AskPlace.imports ? null : '${place.name}/',
          helpHref: 'help/',
          fact: fact,
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    return cubit;
  }

  input<String> field() =>
      find.byType(input<String>).evaluate().single.component as input<String>;

  testComponents('offers questions from the ledger and asks one at once', (
    tester,
  ) async {
    final cubit = await pump(tester);

    expect(find.text('Можно спросить'), findsOneComponent);
    expect(find.text('Продукты в октябре'), findsOneComponent);
    expect(find.text('Траты в поездке «Тбилиси»'), findsOneComponent);
    expect(find.text('Как перенести данные'), findsOneComponent);
    expect(
      find.text(
        'Отвечает само приложение: вопросы и ответы остаются в этом браузере.',
      ),
      findsOneComponent,
    );

    await tester.click(buttonOf('Продукты в октябре'));
    await tester.pump();
    await tester.pump();

    expect(field().value, 'Продукты в октябре');
    expect(asked, ['Продукты в октябре']);
    expect(find.text('Понял так'), findsOneComponent);
    // The chip of the days, and the same period among the closed choices.
    expect(find.text('Октябрь 2026'), findsNComponents(2));
    expect(find.text(nb('5 640 ₽')), findsOneComponent);
    expect(cubit.state.recent, ['Продукты в октябре']);
    expect(
      find.text(
        'Посчитано в этом браузере по курсу ЦБ на день каждой операции.',
      ),
      findsOneComponent,
    );
  });

  testComponents('a wide page keeps the examples beside the answer', (
    tester,
  ) async {
    await pump(tester, wide: true);

    final aside = find.tag('aside');
    expect(
      find.descendant(of: aside, matching: find.text('Продукты в октябре')),
      findsOneComponent,
    );
    expect(
      find.descendant(
        of: aside,
        matching: find.text('Клавиша / открывает «Спросить» с любой страницы.'),
      ),
      findsOneComponent,
    );
    expect(find.text('Спросите про деньги словами'), findsOneComponent);

    await tester.click(buttonOf('Продукты в октябре'));
    await tester.pump();
    await tester.pump();

    expect(find.text(nb('5 640 ₽')), findsOneComponent);
    expect(
      find.descendant(of: aside, matching: find.text('Продукты в октябре')),
      findsComponents,
    );
  });

  testComponents('reads a typed question once the fingers pause', (
    tester,
  ) async {
    await pump(tester);

    field().onInput!('кафе в октябре');
    await tester.pump();
    expect(asked, isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 450));
    await tester.pump();
    await tester.pump();

    expect(asked, ['кафе в октябре']);
    expect(find.text(nb('5 220 ₽')), findsOneComponent);
  });

  testComponents('counts a question again for the period picked under its '
      'plaque', (tester) async {
    await pump(tester, question: 'кафе в октябре');

    expect(find.text(nb('5 220 ₽')), findsOneComponent);
    expect(find.text('Кофейня Surf'), findsOneComponent);
    BirkaFold periods() =>
        find.byType(BirkaFold).evaluate().last.component as BirkaFold;
    expect(periods().open, isFalse);

    await tester.click(buttonOf('Октябрь 2026'));
    await tester.pump();
    expect(periods().open, isTrue);

    await tester.click(buttonOf('Сентябрь 2026'));
    await tester.pump();
    await tester.pump();

    expect(find.text(nb('2 400 ₽')), findsOneComponent);
    expect(periods().open, isFalse);
  });

  testComponents('leads to the operations that the answer counted', (
    tester,
  ) async {
    final cubit = await pump(tester, question: 'кафе в октябре');

    expect(hrefOf('Показать 4 операции'), 'operations/');
    await tester.click(
      find
          .ancestor(
            of: find.text('Показать 4 операции'),
            matching: find.tag('a'),
          )
          .first,
    );

    expect(shown, [(4, 'Кафе · Октябрь 2026', 'кафе в октябре')]);
    expect(cubit.state.recent, ['кафе в октябре']);
    expect(hrefOf('Кофейня Surf'), startsWith('operations/#'));
  });

  testComponents('answers the capital with the accounts', (tester) async {
    await pump(tester, question: 'сколько у меня денег');

    expect(find.text(nb('437 180 ₽')), findsOneComponent);
    expect(find.text('Накопления'), findsOneComponent);
    expect(hrefOf('Все счета'), 'accounts/');
  });

  testComponents('puts the card of another feature for what can be spent', (
    tester,
  ) async {
    await pump(
      tester,
      question: 'сколько можно тратить',
      fact: (fact) => p([.text('card of ${fact.name}')]),
    );

    expect(find.text('card of allowance'), findsOneComponent);
    expect(hrefOf('Деньги до зарплаты'), 'payday/');
  });

  testComponents('answers from the help and leaves out a page the site has '
      'not', (tester) async {
    await pump(tester, question: 'можно ли загрузить операции из банка');

    expect(find.text('Из справки'), findsOneComponent);
    expect(hrefOf('Вся справка'), 'help/');
    expect(find.text('Импорт выписки'), findsNothing);
  });

  testComponents('gives no advice and asks what it can answer', (
    tester,
  ) async {
    await pump(tester, question: 'стоит ли покупать доллары');

    expect(find.text('Советов о вложениях и курсах не даю'), findsOneComponent);

    await tester.click(buttonOf('Курс доллара'));
    await tester.pump();
    await tester.pump();

    expect(field().value, 'Курс доллара');
    expect(asked, ['Курс доллара']);
  });

  testComponents('asks a new question of the address at once', (tester) async {
    final cubit = AskCubit(FakeAskRepository());
    addTearDown(cubit.close);
    late void Function(String) readAddress;
    tester.pumpComponent(
      BlocProvider<AskCubit>.value(
        value: cubit,
        child: _Address(onReady: (read) => readAddress = read),
      ),
    );
    await tester.pump();
    await tester.pump();

    readAddress('кафе в октябре');
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }

    expect(field().value, 'кафе в октябре');
    expect(find.text(nb('5 220 ₽')), findsOneComponent);
  });

  testComponents('keeps the questions asked last until they are cleared', (
    tester,
  ) async {
    await pump(tester, repository: FakeAskRepository(recent: ['курс лари']));

    expect(find.text('Недавние'), findsOneComponent);
    expect(find.text('курс лари'), findsOneComponent);

    await tester.click(buttonOf('Очистить'));
    await tester.pump();

    final folds = find.byType(BirkaFold).evaluate();
    expect((folds.single.component as BirkaFold).open, isFalse);
  });
}

/// A page whose address changes its question, as a new fragment does.
class _Address extends StatefulComponent {
  const _Address({required this.onReady});

  /// Gives the way to put a question in the address.
  final void Function(void Function(String question) read) onReady;

  @override
  State<_Address> createState() => _AddressState();
}

class _AddressState extends State<_Address> {
  var _question = '';

  @override
  void initState() {
    super.initState();
    component.onReady((question) => setState(() => _question = question));
  }

  @override
  Component build(BuildContext context) => AskPage(
    question: _question,
    onQuestion: (_) {},
    operationsHref: 'operations/',
    onShowOperations: (_, _, _) {},
    hrefOfOperation: (id) => id,
    hrefOfTag: (id) => id,
    hrefOfPlace: (_) => null,
    helpHref: 'help/',
  );
}
