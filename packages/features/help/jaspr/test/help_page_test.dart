import 'package:design_jaspr/design_jaspr.dart';
import 'package:help_common/help_common.dart';
import 'package:help_jaspr/help_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';

import 'fakes.dart';

void main() {
  late FakeHelpLinks links;

  Future<void> pump(ComponentTester tester, {bool wide = false}) async {
    final cubit = HelpCubit(links, Future.value(sampleAbout));
    addTearDown(cubit.close);
    tester.pumpComponent(
      BlocProvider.value(
        value: cubit,
        child: HelpPage(wide: wide),
      ),
    );
    await tester.pump();
  }

  Future<void> clickText(ComponentTester tester, String text) async {
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

  Iterable<String?> expanded() => find
      .tag('button')
      .evaluate()
      .map((it) => (it.component as DomComponent).attributes?['aria-expanded'])
      .nonNulls;

  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
    links = FakeHelpLinks();
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('asks the common questions and offers ways to write', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Где хранятся мои данные?'), findsOneComponent);
    expect(find.text('Как скрыть суммы?'), findsOneComponent);
    expect(find.text('Написать разработчику'), findsOneComponent);
    expect(find.text('Сообщить об ошибке'), findsOneComponent);
    expect(find.text('Предложить идею'), findsOneComponent);
    expect(find.text('Ошибки и идеи на GitHub'), findsOneComponent);
    expect(
      find.text('Birka 0.1.0 · Android 14 · русский'),
      findsOneComponent,
    );
    expect(find.byType(DotBadge), findsNComponents(4));
  });

  testComponents('a wide page has the ways to write at the side', (
    tester,
  ) async {
    await pump(tester, wide: true);

    final side = find.byComponentPredicate(
      (component) =>
          component is DomComponent &&
          component.classes == 'birka-split__aside',
    );
    expect(
      find.descendant(of: side, matching: find.text('Написать разработчику')),
      findsOneComponent,
    );
    expect(
      find.descendant(of: side, matching: find.text('Как скрыть суммы?')),
      findsNothing,
    );
  });

  testComponents('opens one answer at a time', (tester) async {
    await pump(tester);
    expect(expanded(), everyElement('false'));

    await clickText(tester, t.help.ratesQuestion);
    expect(expanded().where((it) => it == 'true'), hasLength(1));

    await clickText(tester, t.help.moveQuestion);
    expect(expanded().where((it) => it == 'true'), hasLength(1));

    await clickText(tester, t.help.moveQuestion);
    expect(expanded(), everyElement('false'));
  });

  testComponents('searches the questions and their answers', (tester) async {
    await pump(tester);

    await search(tester, 'банка россии');
    expect(find.text(t.help.ratesQuestion), findsOneComponent);
    expect(find.text(t.help.storageQuestion), findsNothing);

    await search(tester, 'криптокошелёк');
    expect(find.text(t.help.ratesQuestion), findsNothing);
    expect(find.text(t.help.nothingFound), findsOneComponent);
  });

  testComponents('shows the whole letter in place of the ways to write', (
    tester,
  ) async {
    await pump(tester);

    await clickText(tester, 'Сообщить об ошибке');

    expect(find.text(t.help.letterText), findsOneComponent);
    expect(find.text(supportAddress), findsOneComponent);
    expect(find.text('Birka 0.1.0 · ошибка'), findsOneComponent);
    expect(
      find.text(
        'Что случилось:\n\nЧто ожидали:\n\n'
        '—\nBirka 0.1.0 (42) · Android 14 · ru\u2011RU',
      ),
      findsOneComponent,
    );
    expect(find.text('Написать разработчику'), findsNothing);

    await clickText(tester, t.help.openMail);

    expect(links.letters.single.queryParameters, {
      'subject': 'Birka 0.1.0 · ошибка',
      'body':
          'Что случилось:\r\n\r\nЧто ожидали:\r\n\r\n'
          '—\r\nBirka 0.1.0 (42) · Android 14 · ru-RU',
    });
    expect(find.text(t.help.letterText), findsNothing);
    expect(find.text('Написать разработчику'), findsOneComponent);
  });

  testComponents('lets a letter go without the mail app', (tester) async {
    await pump(tester);

    await clickText(tester, 'Предложить идею');
    await clickText(tester, t.help.cancel);

    expect(links.letters, isEmpty);
    expect(find.text(t.help.letterText), findsNothing);
  });

  testComponents('leads to the public page of bugs and ideas', (tester) async {
    await pump(tester);

    await clickText(tester, 'Ошибки и идеи на GitHub');

    expect(links.pages, [issuesPage]);
    expect(find.byType(GlassToast), findsNothing);
  });

  testComponents('says so when the page does not open', (tester) async {
    links.pageOpens = false;
    await pump(tester);

    await clickText(tester, 'Ошибки и идеи на GitHub');

    final toast =
        find.byType(GlassToast).evaluate().single.component as GlassToast;
    expect(toast.text, 'Страница не открылась. Попробуйте ещё раз.');
    expect(toast.trouble, isTrue);
  });
}
