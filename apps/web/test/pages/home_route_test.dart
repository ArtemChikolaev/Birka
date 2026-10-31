import 'package:birka_web/components/capital_preview.dart';
import 'package:birka_web/pages/home_route.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  testComponents('shows what Birka is', (tester) async {
    tester.pumpComponent(const HomeRoute());

    expect(find.text('Birka'), findsOneComponent);
    expect(find.text(HomeRoute.tagline), findsOneComponent);
    expect(find.text('Open the accounts'), findsOneComponent);
    expect(find.text('Open the categories'), findsOneComponent);
    expect(find.text('Source on GitHub'), findsOneComponent);
    expect(find.byType(CapitalPreview), findsOneComponent);
  });
}
