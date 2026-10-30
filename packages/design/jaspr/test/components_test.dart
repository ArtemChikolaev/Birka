import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

/// Finds the DOM element with exactly these [classes].
Finder withClasses(String classes) => find.byComponentPredicate(
  (component) => component is DomComponent && component.classes == classes,
  description: 'element with classes "$classes"',
);

void main() {
  testComponents('GlassSurface wraps its child in a glass panel', (
    tester,
  ) async {
    tester.pumpComponent(const GlassSurface(child: Component.text('Inside')));

    expect(
      find.descendant(of: withClasses('glass'), matching: find.text('Inside')),
      findsOneComponent,
    );
  });

  testComponents('AmbientBackground sets running text on the backdrop', (
    tester,
  ) async {
    tester.pumpComponent(
      const AmbientBackground(child: Component.text('Front')),
    );

    expect(
      find.descendant(
        of: withClasses('ambient text-body'),
        matching: find.text('Front'),
      ),
      findsOneComponent,
    );
  });

  group('AmountText', () {
    testComponents('uses the amount style by default', (tester) async {
      tester.pumpComponent(const AmountText('1 000'));

      expect(
        withClasses('text-amount amount amount--neutral'),
        findsOneComponent,
      );
      expect(find.text('1 000'), findsOneComponent);
    });

    testComponents('takes a tone and a text style', (tester) async {
      tester.pumpComponent(
        const AmountText(
          '+1 000',
          tone: AmountTone.positive,
          textClass: 'text-display',
        ),
      );

      expect(
        withClasses('text-display amount amount--positive'),
        findsOneComponent,
      );
    });
  });

  testComponents('SectionLabel is a heading with the text as written', (
    tester,
  ) async {
    tester.pumpComponent(const SectionLabel('Accounts'));

    expect(find.tag('h2'), findsOneComponent);
    expect(find.text('Accounts'), findsOneComponent);
    expect(withClasses('text-label section-label'), findsOneComponent);
  });

  test('the head links stay relative to the base of the site', () {
    final links = birkaHead.whereType<link>().map((item) => item.href);

    expect(links, [
      'packages/design_tokens/css/tokens.css',
      'packages/design_jaspr/fonts/fonts.css',
    ]);
  });
}
