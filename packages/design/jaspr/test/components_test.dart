import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

/// Finds the DOM element with exactly these [classes].
Finder withClasses(String classes) => find.byComponentPredicate(
  (component) => component is DomComponent && component.classes == classes,
  description: 'element with classes "$classes"',
);

/// The attributes of the one element that [finder] finds.
Map<String, String> attributesOf(Finder finder) =>
    (finder.evaluate().single.component as DomComponent).attributes ?? {};

/// The text input that a [BirkaTextField] renders.
input<String> fieldInput() =>
    find.byType(input<String>).evaluate().single.component as input<String>;

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

  group('BirkaButton', () {
    testComponents('runs its action on a click', (tester) async {
      var pressed = 0;
      tester.pumpComponent(
        BirkaButton(label: 'Save', onPressed: () => pressed++),
      );

      await tester.click(find.tag('button'));

      expect(pressed, 1);
      expect(attributesOf(find.tag('button'))['type'], 'button');
    });

    testComponents('is a link when it has an address', (tester) async {
      tester.pumpComponent(const BirkaButton(label: 'Add', href: 'new'));

      expect(attributesOf(find.tag('a'))['href'], 'new');
      expect(find.tag('button'), findsNothing);
    });

    testComponents('is disabled with nothing to do', (tester) async {
      tester.pumpComponent(const BirkaButton(label: 'Save'));

      expect(attributesOf(find.tag('button')), contains('disabled'));
    });

    testComponents('submits the form around it', (tester) async {
      tester.pumpComponent(const BirkaButton(label: 'Save', submits: true));

      final attributes = attributesOf(find.tag('button'));
      expect(attributes['type'], 'submit');
      expect(attributes, isNot(contains('disabled')));
    });

    testComponents('has a quiet look', (tester) async {
      tester.pumpComponent(const BirkaButton(label: 'Later', quiet: true));

      expect(
        withClasses('text-label birka-button birka-button--quiet'),
        findsOneComponent,
      );
    });
  });

  testComponents('BirkaForm is a form around its children', (tester) async {
    tester.pumpComponent(
      BirkaForm(
        classes: 'sign',
        onSubmit: () {},
        children: const [Component.text('Field')],
      ),
    );

    expect(
      find.descendant(of: find.tag('form'), matching: find.text('Field')),
      findsOneComponent,
    );
    expect(withClasses('sign'), findsOneComponent);
  });

  group('BirkaChip', () {
    testComponents('says when it is picked and reports a click', (
      tester,
    ) async {
      var tapped = 0;
      tester.pumpComponent(
        BirkaChip(label: 'Cash', selected: true, onTap: () => tapped++),
      );

      await tester.click(find.tag('button'));

      expect(tapped, 1);
      expect(attributesOf(find.tag('button'))['aria-pressed'], 'true');
    });

    testComponents('cannot change without an action', (tester) async {
      tester.pumpComponent(
        const BirkaChip(label: 'RUB', selected: false, onTap: null),
      );

      final attributes = attributesOf(find.tag('button'));
      expect(attributes, contains('disabled'));
      expect(attributes['aria-pressed'], 'false');
    });
  });

  testComponents('BirkaSwitch reports the opposite of its value', (
    tester,
  ) async {
    final values = <bool>[];
    tester.pumpComponent(
      BirkaSwitch(value: true, label: 'Count it', onChanged: values.add),
    );

    await tester.click(find.tag('button'));

    expect(values, [false]);
    final attributes = attributesOf(find.tag('button'));
    expect(attributes['role'], 'switch');
    expect(attributes['aria-checked'], 'true');
    expect(attributes['aria-label'], 'Count it');
  });

  group('BirkaTextField', () {
    testComponents('labels the input and passes on what it gets', (
      tester,
    ) async {
      final typed = <String>[];
      tester.pumpComponent(
        BirkaTextField(
          label: 'Name',
          value: 'Card',
          onChanged: typed.add,
          hint: 'Salary',
          inputMode: 'decimal',
          maxLength: 4,
          sentence: true,
        ),
      );

      expect(
        find.descendant(of: find.tag('label'), matching: find.text('Name')),
        findsOneComponent,
      );
      final field = fieldInput();
      expect(field.value, 'Card');
      expect(field.attributes, {
        'autocomplete': 'off',
        'placeholder': 'Salary',
        'inputmode': 'decimal',
        'maxlength': '4',
        'autocapitalize': 'sentences',
      });

      field.onInput!('Visa');
      expect(typed, ['Visa']);
    });

    testComponents('shows an error and marks the input', (tester) async {
      tester.pumpComponent(
        BirkaTextField(
          label: 'Name',
          value: '',
          onChanged: (_) {},
          error: 'Give it a name.',
        ),
      );

      expect(find.text('Give it a name.'), findsOneComponent);
      expect(fieldInput().attributes?['aria-invalid'], 'true');
    });

    testComponents('takes a text style', (tester) async {
      tester.pumpComponent(
        BirkaTextField(
          label: 'Amount',
          value: '',
          onChanged: (_) {},
          textClass: 'text-amount',
        ),
      );

      expect(fieldInput().classes, 'text-amount birka-field__input');
    });
  });

  group('card art', () {
    testComponents('a card holds its content on the art', (tester) async {
      tester.pumpComponent(
        const CardArtSurface(art: CardArt.amber, child: Component.text('Top')),
      );

      expect(
        find.descendant(
          of: withClasses('card-art card-art--amber'),
          matching: find.text('Top'),
        ),
        findsOneComponent,
      );
    });

    testComponents('a thumbnail stands out when asked', (tester) async {
      tester.pumpComponent(
        const div([
          CardArtThumbnail(art: CardArt.rose),
          CardArtThumbnail(art: CardArt.violet, highlighted: true),
        ]),
      );

      expect(
        withClasses('card-art card-art--rose card-art--thumbnail'),
        findsOneComponent,
      );
      expect(
        withClasses(
          'card-art card-art--violet card-art--thumbnail '
          'card-art--highlighted',
        ),
        findsOneComponent,
      );
    });

    test('only amber glows from the top', () {
      final css = CardArtSurface.styles.map((rule) => rule.toCss()).join();
      expect('at 0% 0%'.allMatches(css), hasLength(1));
      expect(
        'at 100% 100%'.allMatches(css),
        hasLength(CardArt.values.length - 1),
      );
    });
  });

  group('GlassIconButton', () {
    testComponents('is a named button that reports a click', (tester) async {
      var pressed = 0;
      tester.pumpComponent(
        GlassIconButton(
          glyph: BirkaGlyph.close,
          label: 'Close',
          onPressed: () => pressed++,
        ),
      );

      await tester.click(find.tag('button'));

      expect(pressed, 1);
      expect(attributesOf(find.tag('button'))['aria-label'], 'Close');
      expect(find.byType(BirkaIcon), findsOneComponent);
    });

    testComponents('is a link when it has an address', (tester) async {
      tester.pumpComponent(
        const GlassIconButton(
          glyph: BirkaGlyph.plus,
          label: 'Add',
          href: 'accounts/#new',
        ),
      );

      final attributes = attributesOf(find.tag('a'));
      expect(attributes['href'], 'accounts/#new');
      expect(attributes['aria-label'], 'Add');
    });
  });

  group('GlassListRow', () {
    testComponents('shows its lines and what stands around them', (
      tester,
    ) async {
      tester.pumpComponent(
        const GlassListGroup(
          children: [
            GlassListRow(
              title: 'Card',
              subtitle: 'Rubles',
              leading: Component.text('Art'),
              trailing: Component.text('100'),
            ),
          ],
        ),
      );

      expect(find.text('Card'), findsOneComponent);
      expect(find.text('Rubles'), findsOneComponent);
      expect(find.text('Art'), findsOneComponent);
      expect(find.text('100'), findsOneComponent);
      expect(withClasses('glass-row'), findsOneComponent);
    });

    testComponents('is a link when it has an address', (tester) async {
      tester.pumpComponent(const GlassListRow(title: 'Card', href: '#card'));

      expect(attributesOf(find.tag('a'))['href'], '#card');
    });

    testComponents('is a button with an action', (tester) async {
      var tapped = 0;
      tester.pumpComponent(GlassListRow(title: 'Card', onTap: () => tapped++));

      await tester.click(find.tag('button'));

      expect(tapped, 1);
    });
  });
}
