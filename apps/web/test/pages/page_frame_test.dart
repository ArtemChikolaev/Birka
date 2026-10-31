import 'package:birka_web/pages/accounts_island.dart';
import 'package:birka_web/pages/categories_island.dart';
import 'package:birka_web/pages/page_frame.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  List<String?> links() => [
    for (final element in find.tag('a').evaluate())
      (element.component as DomComponent).attributes?['href'],
  ];

  testComponents('the build leaves a frame for the accounts', (tester) async {
    tester.pumpComponent(const PageFrame(child: AccountsIsland()));

    expect(find.byType(AmbientBackground), findsOneComponent);
    expect(find.byType(BirkaPlaceholder), findsOneComponent);
    expect(links(), ['./', 'accounts/#new']);
  });

  testComponents('the build leaves a frame for the categories', (tester) async {
    tester.pumpComponent(const PageFrame(child: CategoriesIsland()));

    expect(find.byType(BirkaPlaceholder), findsOneComponent);
    expect(links(), ['./', 'categories/#new-expense']);
  });
}
