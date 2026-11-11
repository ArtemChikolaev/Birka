import 'package:birka_web/app/site_version.dart';
import 'package:birka_web/pages/more_page.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';

final class _Store implements SettingsStore {
  @override
  String? read(String key) => null;

  @override
  Future<void> write(String key, String value) async {}
}

void main() {
  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  void pump(ComponentTester tester, {Component? inbox, bool wide = false}) =>
      tester.pumpComponent(
        BlocProvider(
          create: (_) => SettingsCubit(
            _Store(),
            deviceLanguage: 'ru',
            baseCurrency: BaseCurrency(null),
            monthStart: MonthStart(1),
          ),
          child: MorePage(inbox: inbox, wide: wide),
        ),
      );

  testComponents('a wide page has the tiles on one half and the settings on '
      'the other', (tester) async {
    pump(tester, wide: true);
    await tester.pump();

    final halves = find
        .byComponentPredicate(
          (component) =>
              component is DomComponent &&
              component.classes == 'birka-split__main',
        )
        .evaluate()
        .toList();
    expect(halves, hasLength(2));
    Finder inHalf(int index, Finder finder) => find.descendant(
      of: find.byElementPredicate((element) => element == halves[index]),
      matching: finder,
    );
    expect(inHalf(0, find.text('Счета')), findsOneComponent);
    expect(inHalf(1, find.text('Помощь и отзыв')), findsOneComponent);
  });

  testComponents('leads to the accounts, the categories, the import, the data '
      'and help', (
    tester,
  ) async {
    pump(tester);

    expect(find.text('Ещё'), findsOneComponent);
    expect(
      find
          .tag('a')
          .evaluate()
          .map(
            (element) =>
                (element.component as DomComponent).attributes?['href'],
          ),
      [
        'accounts/',
        'categories/',
        'import/',
        'data/',
        'help/',
        'https://github.com/ArtemChikolaev/Birka',
        'https://www.cbr-xml-daily.ru/',
      ],
    );
    expect(
      find.descendant(of: find.tag('a'), matching: find.text('Счета')),
      findsOneComponent,
    );
    expect(
      find.descendant(of: find.tag('a'), matching: find.text('Категории')),
      findsOneComponent,
    );
    expect(
      find.descendant(of: find.tag('a'), matching: find.text('Данные')),
      findsOneComponent,
    );
    expect(
      find.descendant(of: find.tag('a'), matching: find.text('Помощь и отзыв')),
      findsOneComponent,
    );
  });

  testComponents('puts the way to the inbox over the tiles, as wide', (
    tester,
  ) async {
    pump(tester, inbox: const a(href: 'inbox/', [.text('Входящие')]));

    final links = [
      for (final element in find.tag('a').evaluate())
        (element.component as DomComponent).attributes?['href'],
    ];
    expect(links.take(2), ['inbox/', 'accounts/']);
    final wide = [
      for (final element in find.byType(div).evaluate())
        if ((element.component as div).classes == 'more__wide') element,
    ];
    expect(wide, hasLength(1));
  });

  testComponents('has nothing left to come', (tester) async {
    pump(tester);

    expect(
      find.descendant(of: find.tag('a'), matching: find.text('Импорт')),
      findsOneComponent,
    );
    expect(find.text('скоро'), findsNothing);
  });

  testComponents('ends with the version, the code and the rates', (
    tester,
  ) async {
    pump(tester);

    expect(
      find.text('Birka $siteVersion · данные хранятся в этом браузере'),
      findsOneComponent,
    );
    final away = find
        .descendant(of: find.tag('footer'), matching: find.tag('a'))
        .evaluate()
        .map((element) => (element.component as DomComponent).attributes);
    expect(away.map((attributes) => attributes?['target']), [
      '_blank',
      '_blank',
    ]);
    expect(away.map((attributes) => attributes?['rel']), [
      'noopener',
      'noopener',
    ]);
    expect(find.text('Исходный код на GitHub'), findsOneComponent);
    expect(find.text('Курсы ЦБ РФ в XML и JSON, API'), findsOneComponent);
  });

  testComponents('holds the settings', (tester) async {
    pump(tester);

    expect(find.text('Язык'), findsOneComponent);
    expect(find.text('Скрывать суммы'), findsOneComponent);
  });
}
