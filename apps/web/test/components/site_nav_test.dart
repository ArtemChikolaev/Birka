import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  List<Map<String, String>> links() => [
    for (final element in find.tag('a').evaluate())
      (element.component as DomComponent).attributes ?? const {},
  ];

  testComponents('leads to every page and to a new operation', (tester) async {
    tester.pumpComponent(const SiteNav(page: SitePage.overview));

    expect(links().map((attributes) => attributes['href']), [
      'overview/',
      'operations/',
      'operations/#new',
      'accounts/',
      'categories/',
    ]);
  });

  testComponents('marks the page that stands open', (tester) async {
    for (final page in SitePage.values) {
      tester.pumpComponent(SiteNav(page: page));
      await tester.pump();

      final bar =
          find.byType(GlassNavBar).evaluate().single.component as GlassNavBar;
      expect(bar.destinations[bar.selectedIndex].href, '${page.name}/');
    }
  });

  testComponents('speaks the language of the browser', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    tester.pumpComponent(const SiteNav(page: SitePage.accounts));

    expect(find.text('Обзор'), findsOneComponent);
    expect(find.text('Операции'), findsOneComponent);
    expect(find.text('Счета'), findsOneComponent);
    expect(find.text('Категории'), findsOneComponent);
  });
}
