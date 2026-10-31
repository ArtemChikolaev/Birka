import 'package:birka_web/pages/more_page.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testComponents('leads to the accounts and the categories', (tester) async {
    tester.pumpComponent(const MorePage());

    expect(find.text('Ещё'), findsOneComponent);
    expect(
      find
          .tag('a')
          .evaluate()
          .map(
            (element) =>
                (element.component as DomComponent).attributes?['href'],
          ),
      ['accounts/', 'categories/'],
    );
    expect(
      find.descendant(of: find.tag('a'), matching: find.text('Счета')),
      findsOneComponent,
    );
    expect(
      find.descendant(of: find.tag('a'), matching: find.text('Категории')),
      findsOneComponent,
    );
  });

  testComponents('says that the rest is yet to come', (tester) async {
    tester.pumpComponent(const MorePage());

    expect(find.text('Импорт'), findsOneComponent);
    expect(find.text('Бэкап'), findsOneComponent);
    expect(find.text('скоро'), findsNComponents(2));
  });
}
