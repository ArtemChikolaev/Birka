import 'package:birka_web/pages/accounts_island.dart';
import 'package:birka_web/pages/categories_island.dart';
import 'package:birka_web/pages/operations_island.dart';
import 'package:birka_web/pages/overview_island.dart';
import 'package:birka_web/pages/page_frame.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  // The build knows no language, so a word here would flash in the wrong one.
  for (final (name, island) in const <(String, Component)>[
    ('overview', OverviewIsland()),
    ('operations', OperationsIsland()),
    ('accounts', AccountsIsland()),
    ('categories', CategoriesIsland()),
  ]) {
    testComponents('the build leaves a frame without words for $name', (
      tester,
    ) async {
      tester.pumpComponent(PageFrame(child: island));

      expect(find.byType(AmbientBackground), findsOneComponent);
      expect(find.byType(BirkaPlaceholder), findsOneComponent);
      expect(find.tag('h1'), findsNothing);
      expect(find.tag('nav'), findsNothing);
    });
  }
}
