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

  group('BirkaForm', () {
    BirkaForm formWith({
      VoidCallback? onClose,
      bool submitting = false,
      String? failure,
      Component? leading,
    }) => BirkaForm(
      title: 'New',
      closeLabel: 'Close',
      onClose: onClose ?? () {},
      submitLabel: 'Save',
      onSubmit: () {},
      submitting: submitting,
      failure: failure,
      leading: leading,
      children: const [Component.text('Field')],
    );

    testComponents('holds a heading, its fields and a submit button', (
      tester,
    ) async {
      tester.pumpComponent(formWith(leading: const Component.text('Badge')));

      final inForm = find.descendant(
        of: find.tag('form'),
        matching: find.text('Field'),
      );
      expect(inForm, findsOneComponent);
      expect(find.text('New'), findsOneComponent);
      expect(find.text('Badge'), findsOneComponent);
      final save = find.ancestor(
        of: find.text('Save'),
        matching: find.tag('button'),
      );
      expect(attributesOf(save)['type'], 'submit');
      expect(attributesOf(save), isNot(contains('disabled')));
    });

    testComponents('the cross closes the form', (tester) async {
      var closed = 0;
      tester.pumpComponent(formWith(onClose: () => closed++));

      await tester.click(find.byType(GlassIconButton));

      expect(closed, 1);
    });

    testComponents('turns the button off while it saves', (tester) async {
      tester.pumpComponent(formWith(submitting: true));

      final save = find.ancestor(
        of: find.text('Save'),
        matching: find.tag('button'),
      );
      expect(attributesOf(save), contains('disabled'));
    });

    testComponents('says why a save failed', (tester) async {
      tester.pumpComponent(formWith(failure: 'Could not save.'));

      expect(find.text('Could not save.'), findsOneComponent);
    });
  });

  testComponents('BirkaChoice puts a label over its options', (tester) async {
    tester.pumpComponent(
      const BirkaChoice(
        label: 'Type',
        children: [Component.text('Cash')],
      ),
    );

    expect(find.text('Type'), findsOneComponent);
    expect(
      find.descendant(
        of: withClasses('birka-choice__options'),
        matching: find.text('Cash'),
      ),
      findsOneComponent,
    );
  });

  testComponents('BirkaColumn stacks its blocks', (tester) async {
    tester.pumpComponent(
      const BirkaColumn(children: [Component.text('Block')]),
    );

    expect(
      find.descendant(
        of: withClasses('birka-column'),
        matching: find.text('Block'),
      ),
      findsOneComponent,
    );
  });

  group('GlassNotice', () {
    testComponents('a plain notice is one line and its buttons', (
      tester,
    ) async {
      tester.pumpComponent(
        const GlassNotice(
          text: 'It broke.',
          actions: [BirkaButton(label: 'Retry', href: 'again')],
        ),
      );

      expect(find.text('It broke.'), findsOneComponent);
      expect(find.text('Retry'), findsOneComponent);
      expect(withClasses('glass-notice__message'), findsOneComponent);
    });

    testComponents('a heading makes the text quieter', (tester) async {
      tester.pumpComponent(
        const GlassNotice(title: 'Empty', text: 'Add one.', actions: []),
      );

      expect(find.text('Empty'), findsOneComponent);
      expect(
        withClasses('glass-notice__message glass-notice__message--quiet'),
        findsOneComponent,
      );
    });
  });

  testComponents('GlassPageHeader leads back and to a new item', (
    tester,
  ) async {
    tester.pumpComponent(
      const GlassPageHeader(
        backHref: './',
        backLabel: 'Back',
        addHref: 'new',
        addLabel: 'Add',
      ),
    );

    final links = find
        .tag('a')
        .evaluate()
        .map(
          (element) => (element.component as DomComponent).attributes,
        );
    expect(links.map((attributes) => attributes?['href']), ['./', 'new']);
    expect(links.map((attributes) => attributes?['aria-label']), [
      'Back',
      'Add',
    ]);
  });

  testComponents('GlassSegmented says what is picked and reports a click', (
    tester,
  ) async {
    final picked = <int>[];
    tester.pumpComponent(
      GlassSegmented<int>(
        segments: const {1: 'One', 2: 'Two'},
        selected: 1,
        onChanged: picked.add,
      ),
    );

    final two = find.ancestor(
      of: find.text('Two'),
      matching: find.tag('button'),
    );
    await tester.click(two);

    expect(picked, [2]);
    expect(attributesOf(two)['aria-pressed'], 'false');
    expect(
      attributesOf(
        find.ancestor(of: find.text('One'), matching: find.tag('button')),
      )['aria-pressed'],
      'true',
    );
  });

  testComponents('GlyphBadge tints its tile with its color', (tester) async {
    tester.pumpComponent(
      const GlyphBadge(glyph: BirkaGlyph.cart, color: '#123456', size: 28),
    );

    final badge = withClasses('glyph-badge').evaluate().single.component;
    final styles = (badge as DomComponent).styles!.properties;
    expect(styles['color'], '#123456');
    expect(styles['background'], contains('#123456 16%'));
    expect(styles['width'], '28px');
    expect(styles['height'], '28px');
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

    testComponents('stands further in under its parent', (tester) async {
      tester.pumpComponent(const GlassListRow(title: 'Cafe', indented: true));

      expect(withClasses('glass-row glass-row--indented'), findsOneComponent);
    });
  });
}
