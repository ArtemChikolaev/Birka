import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_common/help_common.dart';
import 'package:help_flutter/help_flutter.dart';
import 'package:l10n/l10n.dart';

import 'fakes.dart';

void main() {
  late FakeHelpLinks links;
  var left = 0;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final cubit = HelpCubit(links, Future.value(sampleAbout));
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider.value(
          value: cubit,
          child: HelpPage(onBack: () => left++),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  setUp(() {
    links = FakeHelpLinks();
    left = 0;
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('asks the common questions and offers ways to write', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('ПОМОЩЬ'), findsOneWidget);
    expect(find.text('Где хранятся мои данные?'), findsOneWidget);
    expect(find.text('Как скрыть суммы?'), findsOneWidget);
    expect(find.text('Написать разработчику'), findsOneWidget);
    expect(find.text('Сообщить об ошибке'), findsOneWidget);
    expect(find.text('Предложить идею'), findsOneWidget);
    expect(find.text('Ошибки и идеи на GitHub'), findsOneWidget);
    expect(find.text('Birka 0.1.0 · Android 14 · русский'), findsOneWidget);
  });

  testWidgets('opens one answer at a time', (tester) async {
    await pump(tester);
    final storage = t.help.storageAnswer;
    final rates = t.help.ratesAnswer;

    expect(find.text(storage), findsNothing);
    await tapText(tester, t.help.storageQuestion);
    expect(find.text(storage), findsOneWidget);

    await tapText(tester, t.help.ratesQuestion);
    expect(find.text(storage), findsNothing);
    expect(find.text(rates), findsOneWidget);

    await tapText(tester, t.help.ratesQuestion);
    expect(find.text(rates), findsNothing);
  });

  testWidgets('tells screen readers whether a question is open', (
    tester,
  ) async {
    await pump(tester);
    final semantics = tester.ensureSemantics();
    final question = find.text(t.help.moveQuestion);

    expect(
      tester.getSemantics(question),
      containsSemantics(hasExpandedState: true, isExpanded: false),
    );
    await tapText(tester, t.help.moveQuestion);
    expect(
      tester.getSemantics(question),
      containsSemantics(hasExpandedState: true, isExpanded: true),
    );
    semantics.dispose();
  });

  testWidgets('searches the questions and their answers', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'банка россии');
    await tester.pumpAndSettle();
    expect(find.text(t.help.ratesQuestion), findsOneWidget);
    expect(find.text(t.help.storageQuestion), findsNothing);
    expect(find.text(t.help.nothingFound), findsNothing);

    await tester.enterText(find.byType(TextField), 'криптокошелёк');
    await tester.pumpAndSettle();
    expect(find.text(t.help.ratesQuestion), findsNothing);
    expect(find.text(t.help.nothingFound), findsOneWidget);
  });

  testWidgets('shows the whole letter before the mail app gets it', (
    tester,
  ) async {
    await pump(tester);

    await tapText(tester, 'Сообщить об ошибке');

    expect(find.text(t.help.letterText), findsOneWidget);
    expect(
      find.text('Кому: $supportAddress', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('Тема: Birka 0.1.0 · ошибка', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text(
        'Что случилось:\n\nЧто ожидали:\n\n'
        '—\nBirka 0.1.0 (42) · Android 14 · ru-RU',
      ),
      findsOneWidget,
    );
    expect(find.text(t.help.letterPrivacy), findsOneWidget);

    await tapText(tester, t.help.openMail.toUpperCase());

    expect(links.letters, hasLength(1));
    expect(links.letters.single.path, supportAddress);
    expect(
      links.letters.single.queryParameters['subject'],
      'Birka 0.1.0 · ошибка',
    );
    expect(find.text(t.help.letterText), findsNothing);
  });

  testWidgets('lets a letter go without the mail app', (tester) async {
    await pump(tester);

    await tapText(tester, 'Предложить идею');
    await tapText(tester, t.help.cancel.toUpperCase());

    expect(links.letters, isEmpty);
    expect(find.text(t.help.letterText), findsNothing);
  });

  testWidgets('copies the address when no mail app opens', (tester) async {
    links.mailOpens = false;
    await pump(tester);

    await tapText(tester, 'Написать разработчику');
    await tapText(tester, t.help.openMail.toUpperCase());

    expect(links.copied, [supportAddress]);
    expect(
      find.text('Почта не открылась. Адрес скопирован: $supportAddress'),
      findsOneWidget,
    );
  });

  testWidgets('leads to the public page of bugs and ideas', (tester) async {
    await pump(tester);

    await tapText(tester, 'Ошибки и идеи на GitHub');

    expect(links.pages, [issuesPage]);
  });

  testWidgets('goes back', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel(t.help.back));

    expect(left, 1);
  });
}
