import 'package:ask_common/ask_common.dart';
import 'package:ask_common/testing.dart';
import 'package:ask_flutter/ask_flutter.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

String nb(String text) => text.replaceAll(' ', String.fromCharCode(0xA0));

Finder amount(String text) => find.byWidgetPredicate(
  (widget) => widget is AmountText && widget.text == nb(text),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  final shown = <(int, String)>[];
  final places = <AskPlace>[];

  Future<void> pump(
    WidgetTester tester, {
    FakeAskRepository? repository,
    Widget? Function(BuildContext, AskFact)? fact,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    shown.clear();
    places.clear();
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider(
          create: (_) => AskCubit(repository ?? FakeAskRepository()),
          child: AskPage(
            onBack: () {},
            onShowOperations: (answer, title) =>
                shown.add((answer.count, title)),
            onOpenPlace: places.add,
            onOpenHelp: () {},
            fact: fact,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> ask(WidgetTester tester, String question) async {
    await tester.enterText(find.byType(TextField), question);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('offers questions from the ledger and types one in', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('МОЖНО СПРОСИТЬ'), findsOneWidget);
    expect(find.text('Продукты в октябре'), findsOneWidget);
    expect(find.text('Траты в поездке «Тбилиси»'), findsOneWidget);
    expect(find.text('Как перенести данные'), findsOneWidget);

    await tester.tap(find.text('Продукты в октябре'));
    await tester.pump(const Duration(milliseconds: 100));
    // The question is typed in letter by letter.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isNot('Продукты в октябре'),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Продукты в октябре',
    );
    expect(find.text('ПОНЯЛ ТАК'), findsOneWidget);
    expect(find.text('Октябрь 2026'), findsOneWidget);
    expect(amount('5 640 ₽'), findsOneWidget);
  });

  testWidgets('counts a question again for the period picked on its plaque', (
    tester,
  ) async {
    await pump(tester);
    await ask(tester, 'кафе в октябре');

    expect(amount('5 220 ₽'), findsOneWidget);
    expect(find.text('КАФЕ · ОКТЯБРЬ 2026'), findsOneWidget);
    expect(find.text('САМЫЕ КРУПНЫЕ'), findsOneWidget);
    expect(find.text('Кофейня Surf'), findsOneWidget);

    await tester.tap(find.text('Октябрь 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Период'), findsOneWidget);

    await tester.tap(find.text('Сентябрь 2026'));
    await tester.pumpAndSettle();

    expect(amount('2 400 ₽'), findsOneWidget);
    expect(find.text('Сентябрь 2026'), findsOneWidget);
  });

  testWidgets('leads to the operations the answer counted', (tester) async {
    await pump(tester);
    await ask(tester, 'кафе в октябре');

    await tester.ensureVisible(find.text('ПОКАЗАТЬ 4 ОПЕРАЦИИ'));
    await tester.tap(find.text('ПОКАЗАТЬ 4 ОПЕРАЦИИ'));

    expect(shown, [(4, 'Кафе · Октябрь 2026')]);
  });

  testWidgets('answers the capital with the accounts', (tester) async {
    await pump(tester);
    await ask(tester, 'сколько у меня денег');

    expect(amount('437 180 ₽'), findsOneWidget);
    expect(find.text('Накопления'), findsOneWidget);
  });

  testWidgets('puts the card of another feature for what can be spent', (
    tester,
  ) async {
    await pump(tester, fact: (_, fact) => Text('card of ${fact.name}'));
    await ask(tester, 'сколько можно тратить');

    expect(find.text('card of allowance'), findsOneWidget);
    await tester.tap(find.text('Деньги до зарплаты'));
    expect(places, [AskPlace.payday]);
  });

  testWidgets('answers from the help and names the screen', (tester) async {
    await pump(tester);
    await ask(tester, 'как перенести данные на новый телефон');

    expect(
      find.text('Как перенести учёт на другое устройство?'),
      findsOneWidget,
    );
    expect(find.text('Данные'), findsOneWidget);
  });

  testWidgets('gives no advice and offers questions it can answer', (
    tester,
  ) async {
    await pump(tester);
    await ask(tester, 'стоит ли покупать доллары');

    expect(find.text('Советов о вложениях и курсах не даю'), findsOneWidget);
    expect(find.text('Курс доллара'), findsOneWidget);
  });

  testWidgets('keeps the questions asked last until they are cleared', (
    tester,
  ) async {
    await pump(tester, repository: FakeAskRepository(recent: ['курс лари']));

    expect(find.text('НЕДАВНИЕ'), findsOneWidget);
    expect(find.text('курс лари'), findsOneWidget);

    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();

    expect(find.text('курс лари'), findsNothing);
  });
}
