import 'package:birka_web/components/capital_preview.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  // jaspr_bloc follows state changes only in the browser, and this test runs
  // on the VM.
  setUp(() => setIsClientForTesting(true));
  tearDown(resetIsClientForTesting);

  testComponents('the button hides the amount and shows it again', (
    tester,
  ) async {
    tester.pumpComponent(const CapitalPreview());
    expect(find.text('1 284 560 ₽'), findsOneComponent);

    await tester.click(find.tag('button'));
    expect(find.text('1 284 560 ₽'), findsNothing);
    expect(find.text('•••• ₽'), findsOneComponent);

    await tester.click(find.tag('button'));
    expect(find.text('1 284 560 ₽'), findsOneComponent);
  });
}
