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

    testComponents('has the color of a loss', (tester) async {
      tester.pumpComponent(const BirkaButton(label: 'Delete', danger: true));

      expect(
        withClasses('text-label birka-button birka-button--danger'),
        findsOneComponent,
      );
    });
  });

  group('BirkaForm', () {
    BirkaForm formWith({
      VoidCallback? onClose,
      bool ready = true,
      bool submitting = false,
      String? failure,
      Component? leading,
    }) => BirkaForm(
      title: 'New',
      closeLabel: 'Close',
      onClose: onClose ?? () {},
      submitLabel: 'Save',
      onSubmit: () {},
      ready: ready,
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

    testComponents('turns the button off until it is ready', (tester) async {
      tester.pumpComponent(formWith(ready: false));

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
        const GlassNotice(title: 'Empty', text: 'Add one.'),
      );

      expect(find.text('Empty'), findsOneComponent);
      expect(
        withClasses('glass-notice__message glass-notice__message--quiet'),
        findsOneComponent,
      );
    });

    testComponents('leaves out the place for buttons without any', (
      tester,
    ) async {
      tester.pumpComponent(const GlassNotice(text: 'Nothing found'));

      expect(withClasses('glass-notice__actions'), findsNothing);
    });
  });

  testComponents('GlassPageHeader is the heading and what stands beside it', (
    tester,
  ) async {
    tester.pumpComponent(
      const GlassPageHeader(title: 'Accounts', trailing: Component.text('Add')),
    );

    expect(
      find.descendant(of: find.tag('h1'), matching: find.text('Accounts')),
      findsOneComponent,
    );
    expect(find.text('Add'), findsOneComponent);
  });

  group('GlassNavBar', () {
    const bar = GlassNavBar(
      destinations: [
        GlassNavDestination(glyph: BirkaGlyph.home, label: 'Home', href: 'a/'),
        GlassNavDestination(glyph: BirkaGlyph.list, label: 'List', href: 'b/'),
        GlassNavDestination(glyph: BirkaGlyph.more, label: 'More', href: 'c/'),
        GlassNavDestination(
          glyph: BirkaGlyph.wallet,
          label: 'Cash',
          href: 'd/',
        ),
      ],
      selectedIndex: 1,
      actionLabel: 'Add',
      actionHref: 'add',
    );

    List<Map<String, String>> links() => [
      for (final element in find.tag('a').evaluate())
        (element.component as DomComponent).attributes ?? const {},
    ];

    testComponents('puts the action between its tabs', (tester) async {
      tester.pumpComponent(bar);

      expect(links().map((attributes) => attributes['href']), [
        'a/',
        'b/',
        'add',
        'c/',
        'd/',
      ]);
      expect(links()[2]['aria-label'], 'Add');
      expect(find.text('Cash'), findsOneComponent);
    });

    testComponents('says which page stands open', (tester) async {
      tester.pumpComponent(bar);

      expect(links().map((attributes) => attributes['aria-current']), [
        null,
        'page',
        null,
        null,
        null,
      ]);
      expect(
        withClasses('glass-nav__tab glass-nav__tab--selected'),
        findsOneComponent,
      );
    });
  });

  group('HiddenAmounts', () {
    testComponents('hides the digits and keeps the sign and the currency', (
      tester,
    ) async {
      tester.pumpComponent(
        HiddenAmounts(
          hidden: true,
          onToggle: () {},
          child: const AmountText('−1\u00A0250,50\u00A0₽'),
        ),
      );

      expect(find.text('−•••\u00A0₽'), findsOneComponent);
    });

    testComponents('leaves alone what is always shown', (tester) async {
      tester.pumpComponent(
        HiddenAmounts(
          hidden: true,
          onToggle: () {},
          child: const AmountText('−250 ₽', alwaysShown: true),
        ),
      );

      expect(find.text('−250 ₽'), findsOneComponent);
    });

    testComponents('a compact amount does not tell its size', (tester) async {
      tester.pumpComponent(
        HiddenAmounts(
          hidden: true,
          onToggle: () {},
          child: const AmountText(r'$78k'),
        ),
      );

      expect(find.text(r'$•••'), findsOneComponent);
    });

    testComponents('shows amounts when they are not hidden', (tester) async {
      tester.pumpComponent(
        HiddenAmounts(
          hidden: false,
          onToggle: () {},
          child: const AmountText('250 ₽'),
        ),
      );

      expect(find.text('250 ₽'), findsOneComponent);
    });

    testComponents('shows amounts with nothing around them', (tester) async {
      tester.pumpComponent(const AmountText('250 ₽'));

      expect(find.text('250 ₽'), findsOneComponent);
    });

    testComponents('a button below it can toggle it', (tester) async {
      var toggled = 0;
      tester.pumpComponent(
        HiddenAmounts(
          hidden: false,
          onToggle: () => toggled++,
          child: Builder(
            builder: (context) => button(
              onClick: () => HiddenAmounts.toggle(context),
              const [Component.text('Eye')],
            ),
          ),
        ),
      );

      await tester.click(find.tag('button'));

      expect(toggled, 1);
    });
  });

  group('BirkaLineChart', () {
    List<DomComponent> shapes(String tag) => [
      for (final element in find.tag(tag).evaluate())
        element.component as DomComponent,
    ];

    /// The numbers of a path.
    List<double> numbers(String path) => [
      for (final match in RegExp(r'-?\d+\.\d').allMatches(path))
        double.parse(match[0]!),
    ];

    testComponents('names itself for screen readers', (tester) async {
      tester.pumpComponent(
        const BirkaLineChart(values: [1, 2], label: 'Capital'),
      );

      final attributes = attributesOf(find.tag('svg'));
      expect(attributes['aria-label'], 'Capital');
      expect(attributes['role'], 'img');
    });

    testComponents('rises to the right and ends on a dot', (tester) async {
      tester.pumpComponent(
        const BirkaLineChart(values: [10, 20, 30], label: 'Capital'),
      );

      final line = shapes('path').last.attributes?['d'] ?? '';
      final path = numbers(line);
      // The first point lies low, on the left.
      expect(path[0], 0);
      expect(path[1], 85);
      // The last point lies high, short of the edge by the room of the dot.
      expect(path[path.length - 2], 349);
      expect(path.last, 11);
      expect(shapes('circle').last.attributes, {
        'cx': '349.0',
        'cy': '11.0',
        'r': '5',
      });
    });

    testComponents('a line without any change runs through the middle', (
      tester,
    ) async {
      tester.pumpComponent(
        const BirkaLineChart(values: [5, 5], label: 'Capital'),
      );

      final path = numbers(shapes('path').last.attributes?['d'] ?? '');
      expect(path[1], 48);
      expect(path.last, 48);
    });

    testComponents('thins out a long line', (tester) async {
      tester.pumpComponent(
        BirkaLineChart(
          values: [for (var i = 0; i < 365; i++) i.toDouble()],
          label: 'Capital',
        ),
      );

      final line = shapes('path').last.attributes?['d'] ?? '';
      expect(RegExp('C').allMatches(line).length, lessThanOrEqualTo(60));
    });

    testComponents('draws nothing with fewer than two values', (tester) async {
      tester.pumpComponent(
        const BirkaLineChart(values: [5], label: 'Capital'),
      );

      expect(find.tag('svg'), findsOneComponent);
      expect(find.tag('path'), findsNothing);
    });
  });

  group('BirkaBars', () {
    List<String?> heights() => [
      for (final element in withClasses('birka-bars__bar').evaluate())
        (element.component as DomComponent).styles?.properties['height'],
    ];

    testComponents('measures every bar against the tallest', (tester) async {
      tester.pumpComponent(
        const BirkaBars(
          bars: [
            BirkaBar(value: 50, amount: '50', label: 'Sep'),
            BirkaBar(value: 100, amount: '100', label: 'Oct'),
          ],
        ),
      );

      expect(heights(), ['36.0px', '72.0px']);
      expect(find.text('Sep'), findsOneComponent);
      expect(find.text('100'), findsOneComponent);
    });

    testComponents('a bar without a value keeps its place', (tester) async {
      tester.pumpComponent(
        const BirkaBars(
          bars: [
            BirkaBar(value: 0, amount: '0', label: 'Sep'),
            BirkaBar(value: 0, amount: '0', label: 'Oct'),
          ],
        ),
      );

      expect(heights(), ['6.0px', '6.0px']);
    });

    testComponents('the bar that matters stands out', (tester) async {
      tester.pumpComponent(
        const BirkaBars(
          bars: [
            BirkaBar(value: 1, amount: '1', label: 'Sep'),
            BirkaBar(value: 2, amount: '2', label: 'Oct', highlighted: true),
          ],
        ),
      );

      expect(
        find.byComponentPredicate(
          (component) =>
              component is DomComponent &&
              (component.classes ?? '').contains(
                'birka-bars__item--highlighted',
              ),
        ),
        findsOneComponent,
      );
      expect(
        (find.text('2').evaluate().single.parent!.component as DomComponent)
            .classes,
        contains('amount--positive'),
      );
    });

    testComponents('names every bar for screen readers', (tester) async {
      tester.pumpComponent(
        const BirkaBars(
          bars: [BirkaBar(value: 1, amount: '37k', label: 'Oct')],
        ),
      );

      final item = attributesOf(withClasses('birka-bars__item'));
      expect(item['aria-label'], 'Oct: 37k');
      expect(item['role'], 'img');
    });

    testComponents('hides its figures along with other amounts', (
      tester,
    ) async {
      tester.pumpComponent(
        HiddenAmounts(
          hidden: true,
          onToggle: () {},
          child: const BirkaBars(
            bars: [BirkaBar(value: 1, amount: '37k', label: 'Oct')],
          ),
        ),
      );

      expect(find.text('37k'), findsNothing);
      expect(find.text('•••'), findsOneComponent);
      final item = attributesOf(withClasses('birka-bars__item'));
      expect(item['aria-label'], 'Oct: •••');
    });
  });

  group('BirkaRing', () {
    List<Map<String, String>> circles() => [
      for (final element in find.tag('circle').evaluate())
        (element.component as DomComponent).attributes ?? const {},
    ];

    /// The length of the dash of a circle.
    double dashOf(Map<String, String> attributes) =>
        double.parse((attributes['stroke-dasharray'] ?? '').split(' ').first);

    testComponents('names itself for screen readers', (tester) async {
      tester.pumpComponent(const BirkaRing(slices: [], label: 'Spending'));

      expect(attributesOf(find.tag('svg'))['aria-label'], 'Spending');
    });

    testComponents('an empty ring is only its track', (tester) async {
      tester.pumpComponent(const BirkaRing(slices: [], label: 'Spending'));

      expect(circles(), hasLength(1));
    });

    testComponents('one part closes the whole ring', (tester) async {
      tester.pumpComponent(
        const BirkaRing(slices: [RingSlice(5, '#4ade80')], label: 'Spending'),
      );

      final arc = circles().last;
      expect(arc['stroke'], '#4ade80');
      // A radius of 43.
      expect(dashOf(arc), closeTo(270.2, 0.1));
    });

    testComponents('parts take their shares, with room between them', (
      tester,
    ) async {
      tester.pumpComponent(
        const BirkaRing(
          slices: [RingSlice(3, '#111111'), RingSlice(1, '#222222')],
          label: 'Spending',
        ),
      );

      final [_, big, small] = circles();
      expect(big['stroke'], '#111111');
      expect(dashOf(big), closeTo(199.6, 0.1));
      expect(dashOf(small), closeTo(64.5, 0.1));
      // The second part starts where the first one ended.
      expect(
        double.parse(small['stroke-dashoffset'] ?? ''),
        closeTo(-204.2, 0.1),
      );
    });

    testComponents('a part too small for its gap is left out', (tester) async {
      tester.pumpComponent(
        const BirkaRing(
          slices: [RingSlice(1000, '#111111'), RingSlice(1, '#222222')],
          label: 'Spending',
        ),
      );

      expect(circles(), hasLength(2));
    });

    testComponents('holds a child in the middle', (tester) async {
      tester.pumpComponent(
        const BirkaRing(
          slices: [],
          label: 'Spending',
          child: Component.text('78k'),
        ),
      );

      expect(
        find.descendant(
          of: withClasses('birka-ring__middle'),
          matching: find.text('78k'),
        ),
        findsOneComponent,
      );
    });
  });

  group('AccountCard', () {
    const card = AccountCard(
      art: CardArt.emerald,
      name: 'Salary',
      subtitle: 'Rubles · Debit card',
      amount: '250 ₽',
    );

    testComponents('holds the name, the line under it and the amount', (
      tester,
    ) async {
      tester.pumpComponent(card);

      expect(find.text('Salary'), findsOneComponent);
      expect(find.text('Rubles · Debit card'), findsOneComponent);
      expect(find.text('250 ₽'), findsOneComponent);
      expect(find.tag('a'), findsNothing);
    });

    testComponents('is a link when it has an address', (tester) async {
      tester.pumpComponent(
        const AccountCard(
          art: CardArt.emerald,
          name: 'Salary',
          subtitle: 'Rubles',
          amount: '250 ₽',
          href: 'open',
        ),
      );

      expect(attributesOf(find.tag('a'))['href'], 'open');
    });

    testComponents('a compact one takes a smaller amount', (tester) async {
      tester.pumpComponent(
        const AccountCard(
          art: CardArt.emerald,
          name: 'Salary',
          subtitle: 'Rubles',
          amount: '250 ₽',
          compact: true,
        ),
      );

      expect(
        withClasses('account-card account-card--compact'),
        findsOneComponent,
      );
      final amount =
          find.byType(AmountText).evaluate().single.component as AmountText;
      expect(amount.textClass, 'text-title');
    });
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
        const BirkaChip(label: 'RUB', selected: false),
      );

      final attributes = attributesOf(find.tag('button'));
      expect(attributes, contains('disabled'));
      expect(attributes['aria-pressed'], 'false');
    });

    testComponents('is a link when it has an address', (tester) async {
      tester.pumpComponent(
        const BirkaChip(label: 'Edit', selected: false, href: 'edit'),
      );

      expect(attributesOf(find.tag('a'))['href'], 'edit');
      expect(find.tag('button'), findsNothing);
    });

    testComponents('can stand behind a glyph and take less room', (
      tester,
    ) async {
      tester.pumpComponent(
        const BirkaChip(
          label: 'October',
          selected: true,
          glyph: BirkaGlyph.calendar,
          compact: true,
        ),
      );

      expect(find.byType(BirkaIcon), findsOneComponent);
      expect(
        withClasses(
          'text-body-strong birka-chip birka-chip--selected '
          'birka-chip--compact',
        ),
        findsOneComponent,
      );
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

  testComponents('BirkaChipField says what it is for while it is empty', (
    tester,
  ) async {
    final typed = <String>[];
    tester.pumpComponent(
      BirkaChipField(label: '+ Note', value: 'Lunch', onChanged: typed.add),
    );

    final field = fieldInput();
    expect(field.value, 'Lunch');
    expect(field.attributes?['aria-label'], '+ Note');
    expect(field.attributes?['placeholder'], '+ Note');

    field.onInput!('Dinner');
    expect(typed, ['Dinner']);
  });

  group('BirkaDateChip', () {
    BirkaDateChip chip({String? label}) => BirkaDateChip(
      fieldLabel: 'Pick a day',
      label: label,
      value: '2026-10-15',
      first: '2000-01-01',
      last: '2026-10-31',
      onChanged: (_) {},
    );

    testComponents('opens the calendar between its dates', (tester) async {
      tester.pumpComponent(chip());

      final field =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(field.attributes, {
        'type': 'date',
        'value': '2026-10-15',
        'aria-label': 'Pick a day',
        'max': '2026-10-31',
        'min': '2000-01-01',
      });
      expect(field.events, contains('change'));
    });

    testComponents('is an icon until it has something to say', (tester) async {
      tester.pumpComponent(chip());

      expect(
        withClasses(
          'text-body-strong birka-chip birka-date-chip birka-date-chip--icon',
        ),
        findsOneComponent,
      );
    });

    testComponents('stands as picked with a label', (tester) async {
      tester.pumpComponent(chip(label: '15 October'));

      expect(find.text('15 October'), findsOneComponent);
      expect(
        withClasses(
          'text-body-strong birka-chip birka-date-chip birka-chip--selected',
        ),
        findsOneComponent,
      );
    });
  });

  group('GlassKeypad', () {
    late List<String> pressed;

    GlassKeypad keypad() => GlassKeypad(
      point: ',',
      pointLabel: 'Comma',
      backspaceLabel: 'Erase',
      operatorLabels: const {
        KeypadOperator.add: 'Plus',
        KeypadOperator.subtract: 'Minus',
        KeypadOperator.multiply: 'Times',
        KeypadOperator.divide: 'Divided by',
      },
      onDigit: (digit) => pressed.add('$digit'),
      onPoint: () => pressed.add('point'),
      onOperator: (operator) => pressed.add(operator.name),
      onBackspace: () => pressed.add('erase'),
      onEnter: () => pressed.add('enter'),
    );

    /// Finds the key that screen readers call [label].
    Finder key(String label) => find.byComponentPredicate(
      (component) =>
          component is DomComponent &&
          component.attributes?['aria-label'] == label,
      description: 'key "$label"',
    );

    setUp(() => pressed = []);

    testComponents('reports its keys', (tester) async {
      tester.pumpComponent(keypad());

      for (final label in ['7', 'Comma', 'Divided by', 'Plus', 'Erase']) {
        await tester.click(key(label));
      }

      expect(pressed, ['7', 'point', 'divide', 'add', 'erase']);
    });

    testComponents('shows every digit and the mark of the language', (
      tester,
    ) async {
      tester.pumpComponent(keypad());

      for (var digit = 0; digit < 10; digit++) {
        expect(find.text('$digit'), findsOneComponent);
      }
      expect(find.text(','), findsOneComponent);
      expect(find.text('÷'), findsOneComponent);
      expect(find.byType(BirkaIcon), findsOneComponent);
    });

    testComponents('leaves its keys out of the way of Tab', (tester) async {
      tester.pumpComponent(keypad());

      expect(attributesOf(key('7'))['tabindex'], '-1');
    });

    test('takes the keys of a real keyboard', () {
      final real = keypad();

      for (final name in [
        '4', '0', '.', ',', '+', '-', '*', '/', 'Backspace', 'Enter', //
      ]) {
        expect(real.press(name), isTrue, reason: name);
      }

      expect(pressed, [
        '4',
        '0',
        'point',
        'point',
        'add',
        'subtract',
        'multiply',
        'divide',
        'erase',
        'enter',
      ]);
    });

    test('leaves other keys alone', () {
      final real = keypad();

      for (final name in ['a', ' ', 'Tab', 'Escape', 'F1', 'ArrowLeft']) {
        expect(real.press(name), isFalse, reason: name);
      }

      expect(pressed, isEmpty);
    });
  });

  group('GlassSearchField', () {
    testComponents('labels the input and passes on what it gets', (
      tester,
    ) async {
      final typed = <String>[];
      tester.pumpComponent(
        GlassSearchField(
          label: 'Search',
          clearLabel: 'Clear',
          hint: 'Cafe',
          value: 'co',
          onChanged: typed.add,
        ),
      );

      final field = fieldInput();
      expect(field.value, 'co');
      expect(field.attributes?['aria-label'], 'Search');
      expect(field.attributes?['placeholder'], 'Cafe');

      field.onInput!('cof');
      expect(typed, ['cof']);
    });

    testComponents('the cross clears it', (tester) async {
      final typed = <String>[];
      tester.pumpComponent(
        GlassSearchField(
          label: 'Search',
          clearLabel: 'Clear',
          value: 'coffee',
          onChanged: typed.add,
        ),
      );

      expect(attributesOf(find.tag('button'))['aria-label'], 'Clear');
      await tester.click(find.tag('button'));

      expect(typed, ['']);
    });

    testComponents('an empty field has no cross', (tester) async {
      tester.pumpComponent(
        GlassSearchField(
          label: 'Search',
          clearLabel: 'Clear',
          value: '',
          onChanged: (_) {},
        ),
      );

      expect(find.tag('button'), findsNothing);
    });
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
