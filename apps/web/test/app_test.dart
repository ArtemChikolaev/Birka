import 'package:birka_web/app.dart';
import 'package:birka_web/components/capital_preview.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  testComponents('shows what Birka is', (tester) async {
    tester.pumpComponent(const App());

    expect(find.text('Birka'), findsOneComponent);
    expect(find.text(App.tagline), findsOneComponent);
    expect(find.text('Source on GitHub'), findsOneComponent);
    expect(find.byType(CapitalPreview), findsOneComponent);
  });
}
