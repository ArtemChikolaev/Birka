import 'package:accounts_jaspr/accounts_jaspr.dart';
import 'package:birka_web/pages/accounts_island.dart';
import 'package:birka_web/pages/accounts_route.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  testComponents('the build leaves the frame for the browser to fill', (
    tester,
  ) async {
    tester.pumpComponent(const AccountsRoute());

    expect(find.byType(AmbientBackground), findsOneComponent);
    expect(find.byType(AccountsIsland), findsOneComponent);
    expect(find.byType(AccountsHeader), findsOneComponent);

    final links = [
      for (final element in find.tag('a').evaluate())
        (element.component as DomComponent).attributes?['href'],
    ];
    expect(links, ['./', 'accounts/#new']);
  });
}
