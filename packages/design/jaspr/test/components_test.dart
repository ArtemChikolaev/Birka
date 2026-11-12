import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:fake_async/fake_async.dart';
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

/// A bell whose count the test changes through the setter it gets.
class _Counting extends StatefulComponent {
  const _Counting(this.onSetter);

  final void Function(void Function(int count)) onSetter;

  @override
  State<_Counting> createState() => _CountingState();
}

class _CountingState extends State<_Counting> {
  var _count = 2;

  @override
  void initState() {
    super.initState();
    component.onSetter((count) => setState(() => _count = count));
  }

  @override
  Component build(BuildContext context) => GlassIconButton(
    glyph: BirkaGlyph.bell,
    label: 'Notifications',
    onPressed: () {},
    badge: _count,
  );
}

void main() {
  testComponents('BirkaArrowButton is a button with an arrow', (tester) async {
    var taps = 0;
    tester.pumpComponent(
      BirkaArrowButton(label: 'Start', onPressed: () => taps++),
    );

    await tester.click(find.tag('button'));

    expect(taps, 1);
    expect(find.text('Start'), findsOneComponent);
    expect(find.byType(BirkaIcon), findsOneComponent);
  });

  testComponents('BirkaArrowButton without an action is off', (tester) async {
    tester.pumpComponent(const BirkaArrowButton(label: 'Start'));

    final element = find.byType(button).evaluate().single.component as button;
    expect(element.disabled, isTrue);
    expect(element.type, ButtonType.button);
  });

  testComponents('BirkaArrowButton can submit a form', (tester) async {
    tester.pumpComponent(const BirkaArrowButton(label: 'Start', submits: true));

    final element = find.byType(button).evaluate().single.component as button;
    expect(element.disabled, isFalse);
    expect(element.type, ButtonType.submit);
  });

  testComponents('BirkaStepBars lights the bars up to the current step', (
    tester,
  ) async {
    tester.pumpComponent(const BirkaStepBars(count: 3, current: 1));

    expect(
      withClasses('birka-steps__bar birka-steps__bar--lit'),
      findsNComponents(2),
    );
    expect(withClasses('birka-steps__bar'), findsOneComponent);
    expect(attributesOf(withClasses('birka-steps'))['aria-label'], '2 / 3');
  });

  testComponents('BirkaChangePill goes up in its own color', (tester) async {
    tester.pumpComponent(const BirkaChangePill(label: '+5', rise: true));

    expect(
      withClasses('birka-change-pill birka-change-pill--rise'),
      findsOneComponent,
    );
    expect(find.text('+5'), findsOneComponent);
    final icon = find.byType(BirkaIcon).evaluate().single.component;
    expect((icon as BirkaIcon).glyph, BirkaGlyph.rise);
  });

  testComponents('BirkaChangePill goes down in its own color', (tester) async {
    tester.pumpComponent(const BirkaChangePill(label: '−5', rise: false));

    expect(
      withClasses('birka-change-pill birka-change-pill--fall'),
      findsOneComponent,
    );
    final icon = find.byType(BirkaIcon).evaluate().single.component;
    expect((icon as BirkaIcon).glyph, BirkaGlyph.fall);
  });

  testComponents('WelcomeArt stays out of screen readers', (tester) async {
    tester.pumpComponent(const WelcomeArt());

    final art = find.byType(img).evaluate().single.component as img;
    expect(art.alt, '');
    expect(art.src, 'packages/design_jaspr/images/welcome.webp');
  });

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

    testComponents('ends with a suffix', (tester) async {
      tester.pumpComponent(
        BirkaTextField(
          label: 'Amount',
          value: '449',
          onChanged: (_) {},
          suffix: '₽',
        ),
      );

      expect(
        find.descendant(
          of: withClasses('text-body birka-field__suffix'),
          matching: find.text('₽'),
        ),
        findsOneComponent,
      );
    });
  });

  group('BirkaSplit', () {
    testComponents('puts the side beside the main column', (tester) async {
      tester.pumpComponent(
        const BirkaSplit(
          main: [Component.text('List')],
          aside: [Component.text('Sum')],
          asideWidth: 340,
        ),
      );

      expect(
        find.descendant(
          of: withClasses('birka-split__main'),
          matching: find.text('List'),
        ),
        findsOneComponent,
      );
      expect(
        find.descendant(
          of: withClasses('birka-split__aside'),
          matching: find.text('Sum'),
        ),
        findsOneComponent,
      );
      expect(find.tag('aside'), findsOneComponent);
      final split =
          withClasses('birka-split').evaluate().single.component
              as DomComponent;
      expect(split.styles!.properties['--birka-split-aside'], '340px');
    });

    testComponents('splits the width in halves', (tester) async {
      tester.pumpComponent(
        const BirkaSplit(
          main: [Component.text('Ring')],
          aside: [Component.text('Lines')],
          halves: true,
        ),
      );

      expect(withClasses('birka-split birka-split--halves'), findsOneComponent);
      expect(withClasses('birka-split__main'), findsNComponents(2));
      expect(find.tag('aside'), findsNothing);
    });

    testComponents('can keep the side to a wide screen', (tester) async {
      tester.pumpComponent(
        const BirkaSplit(
          main: [Component.text('List')],
          aside: [Component.text('Hints')],
          asideWhenNarrow: false,
        ),
      );

      expect(
        withClasses('birka-split birka-split--wide-aside'),
        findsOneComponent,
      );
      final css = BirkaSplit.styles.map((rule) => rule.toCss()).join();
      expect(css, contains('.birka-split--wide-aside > .birka-split__aside'));
    });
  });

  group('TintedBox', () {
    testComponents('tints what it holds', (tester) async {
      tester.pumpComponent(
        const TintedBox(color: '#fbbf24', children: [Component.text('Rent')]),
      );

      final box =
          withClasses('tinted-box').evaluate().single.component as DomComponent;
      expect(box.styles!.properties['--tint'], '#fbbf24');
      expect(find.text('Rent'), findsOneComponent);
    });

    testComponents('a notice has a mark, a title and quieter words', (
      tester,
    ) async {
      tester.pumpComponent(
        const TintedNotice(
          color: '#3ddc97',
          title: 'Found in the statement',
          text: 'Marked as posted',
          glyph: BirkaGlyph.check,
        ),
      );

      expect(find.byType(GlyphBadge), findsOneComponent);
      expect(
        withClasses('text-body-strong tinted-notice__title'),
        findsOneComponent,
      );
      expect(
        withClasses('text-body tinted-notice__text tinted-notice__text--quiet'),
        findsOneComponent,
      );
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

    testComponents('counts what is new on its corner', (tester) async {
      tester.pumpComponent(
        const GlassIconButton(
          glyph: BirkaGlyph.bell,
          label: 'Notifications, 2 new',
          href: 'notifications/',
          badge: 2,
        ),
      );

      final badge = withClasses('text-label glass-icon-button__badge');
      expect(badge, findsOneComponent);
      expect(find.text('2'), findsOneComponent);
      // The label says the count, so the figure is not read twice.
      expect(attributesOf(badge)['aria-hidden'], 'true');
      expect(attributesOf(find.tag('a'))['aria-label'], 'Notifications, 2 new');
    });

    testComponents('its count jumps as it grows and shrinks away at nought', (
      tester,
    ) async {
      fakeAsync((time) {
        late void Function(int count) count;
        tester.pumpComponent(_Counting((setter) => count = setter));
        time.flushMicrotasks();
        expect(
          withClasses('text-label glass-icon-button__badge'),
          findsOneComponent,
        );

        count(3);
        time.flushMicrotasks();
        expect(
          withClasses(
            'text-label glass-icon-button__badge '
            'glass-icon-button__badge--jump',
          ),
          findsOneComponent,
        );
        expect(find.text('3'), findsOneComponent);

        time.elapse(const Duration(milliseconds: 150));
        expect(
          withClasses('text-label glass-icon-button__badge'),
          findsOneComponent,
        );

        count(0);
        time.flushMicrotasks();
        // The figure stays while the count shrinks away.
        expect(
          withClasses(
            'text-label glass-icon-button__badge '
            'glass-icon-button__badge--off',
          ),
          findsOneComponent,
        );
        expect(find.text('3'), findsOneComponent);
      });
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

    testComponents('that has just come opens from nothing', (tester) async {
      tester.pumpComponent(const GlassListRow(title: 'Rent', entering: true));

      expect(withClasses('glass-row glass-row--entering'), findsOneComponent);
    });

    testComponents('whose card is open beside the list is marked', (
      tester,
    ) async {
      tester.pumpComponent(
        const GlassListRow(title: 'Cafe', href: '#cafe', picked: true),
      );

      expect(
        withClasses('glass-row glass-row--action glass-row--picked'),
        findsOneComponent,
      );
    });

    testComponents('can say its second line in a color of its own', (
      tester,
    ) async {
      tester.pumpComponent(
        const GlassListRow(
          title: 'Rent',
          subtitle: 'Posted at 9:14',
          subtitleLines: 2,
          subtitleColor: 'var(--color-positive)',
        ),
      );

      final subtitle = withClasses(
        'text-caption glass-row__lines glass-row__subtitle',
      );
      final styles = (subtitle.evaluate().single.component as DomComponent)
          .styles!
          .properties;
      expect(styles['color'], 'var(--color-positive)');
      expect(styles['-webkit-line-clamp'], '2');
    });
  });

  testComponents('GlassToast says it, then goes and says so', (tester) async {
    fakeAsync((time) {
      var gone = 0;
      tester.pumpComponent(GlassToast('Copy saved', onGone: () => gone++));

      expect(find.text('Copy saved'), findsOneComponent);
      expect(attributesOf(withClasses('glass-toast'))['role'], 'status');

      time
        ..elapse(GlassToast.stay)
        ..flushMicrotasks();
      expect(
        withClasses('glass-toast glass-toast--leaving'),
        findsOneComponent,
      );
      expect(gone, 0);

      time.elapse(GlassToast.leave);
      expect(gone, 1);
    });
  });

  testComponents('GlassToast offers an action and goes as it happens', (
    tester,
  ) async {
    fakeAsync((time) {
      var gone = 0;
      var undone = 0;
      tester.pumpComponent(
        GlassToast(
          'Hid it',
          onGone: () => gone++,
          action: (label: 'Undo', onPressed: () => undone++),
        ),
      );
      expect(withClasses('glass-toast glass-toast--action'), findsOneComponent);

      unawaited(tester.click(find.tag('button')));
      time.flushMicrotasks();
      expect(undone, 1);
      expect(
        withClasses('glass-toast glass-toast--action glass-toast--leaving'),
        findsOneComponent,
      );

      time.elapse(GlassToast.leave);
      expect(gone, 1);
      // Its stay no longer runs out.
      time.elapse(GlassToast.stay);
      expect(gone, 1);
    });
  });

  testComponents('GlassToast of trouble wears a cross', (tester) async {
    tester.pumpComponent(
      GlassToast('Not a copy', trouble: true, onGone: () {}),
    );

    expect(withClasses('glass-toast glass-toast--trouble'), findsOneComponent);
    final icon =
        find.byType(BirkaIcon).evaluate().single.component as BirkaIcon;
    expect(icon.glyph, BirkaGlyph.close);
  });

  testComponents('GlassListRow that leads on ends with a chevron', (
    tester,
  ) async {
    tester.pumpComponent(
      const GlassListRow(title: 'Help', href: 'help/', chevron: true),
    );

    expect(withClasses('glass-row__chevron'), findsOneComponent);
    final icon =
        find.byType(BirkaIcon).evaluate().single.component as BirkaIcon;
    expect(icon.glyph, BirkaGlyph.chevron);
  });

  testComponents('GlassListRow has no chevron unless asked', (tester) async {
    tester.pumpComponent(const GlassListRow(title: 'Help', href: 'help/'));

    expect(withClasses('glass-row__chevron'), findsNothing);
  });

  testComponents('GlassListRow that cannot be taken back is red', (
    tester,
  ) async {
    tester.pumpComponent(
      GlassListRow(title: 'Delete everything', danger: true, onTap: () {}),
    );

    expect(
      withClasses('glass-row glass-row--action glass-row--danger'),
      findsOneComponent,
    );
  });

  group('GlassStepPills', () {
    testComponents('marks the steps passed, on screen and ahead', (
      tester,
    ) async {
      final opened = <int>[];
      tester.pumpComponent(
        GlassStepPills(
          labels: const ['File', 'Bank', 'Columns', 'Account'],
          current: 1,
          reachable: 2,
          onStep: opened.add,
        ),
      );

      expect(
        withClasses(
          'text-body-strong glass-step-pills__pill '
          'glass-step-pills__pill--passed',
        ),
        findsNComponents(2),
      );
      expect(
        attributesOf(
          withClasses(
            'text-body-strong glass-step-pills__pill '
            'glass-step-pills__pill--current',
          ),
        )['aria-current'],
        'step',
      );
      expect(find.text('4'), findsOneComponent);
      expect(find.byType(BirkaIcon), findsNComponents(2));

      await tester.click(find.tag('button').first);

      expect(opened, [0]);
    });

    testComponents('opens no step ahead of the furthest', (tester) async {
      tester.pumpComponent(
        GlassStepPills(
          labels: const ['File', 'Bank'],
          current: 0,
          reachable: 0,
          onStep: (_) {},
        ),
      );

      expect(find.tag('button'), findsNothing);
    });
  });

  group('FileDropZone', () {
    testComponents('opens the chooser and names the kinds', (tester) async {
      var chosen = 0;
      tester.pumpComponent(
        FileDropZone(
          title: 'Drop a statement here',
          text: 'From your bank',
          buttonLabel: 'Choose a file',
          kinds: const ['CSV', 'Excel'],
          note: 'Up to 10 000 rows',
          onChoose: () => chosen++,
          onDrop: (_, _) {},
        ),
      );

      await tester.click(find.tag('button'));

      expect(chosen, 1);
      expect(find.text('CSV'), findsOneComponent);
      expect(find.text('Up to 10 000 rows'), findsOneComponent);
    });

    testComponents('holds its button while a file reads', (tester) async {
      tester.pumpComponent(
        FileDropZone(
          title: 'Drop a statement here',
          text: 'From your bank',
          buttonLabel: 'Choose a file',
          busy: true,
          onChoose: () {},
          onDrop: (_, _) {},
        ),
      );

      final element = find.byType(button).evaluate().single.component as button;
      expect(element.disabled, isTrue);
    });
  });

  group('BirkaSelect', () {
    testComponents('lists the options and picks one', (tester) async {
      final picked = <int>[];
      tester.pumpComponent(
        BirkaSelect<int>(
          label: 'Role',
          options: const {1: 'Date', 2: 'Amount', 3: 'Skip'},
          selected: 2,
          dot: 'var(--color-accent)',
          onChanged: picked.add,
        ),
      );

      final options = [
        for (final element in find.byType(option).evaluate())
          element.component as option,
      ];
      expect([for (final it in options) it.selected], [false, true, false]);
      expect(attributesOf(find.tag('select'))['aria-label'], 'Role');
      expect(withClasses('birka-select__dot'), findsOneComponent);
      expect(
        find.descendant(
          of: withClasses('text-body-strong birka-select__value'),
          matching: find.text('Amount'),
        ),
        findsOneComponent,
      );

      (find.byType(select).evaluate().single.component as select).onChange!([
        '2',
      ]);

      expect(picked, [3]);
    });

    testComponents('moves a nested option in', (tester) async {
      tester.pumpComponent(
        BirkaSelect<String>(
          label: 'Category',
          options: const {'food': 'Food', 'market': 'Market'},
          selected: 'food',
          nested: const {'market'},
          onChanged: (_) {},
        ),
      );

      final indent = String.fromCharCodes(const [0xA0, 0xA0, 0xA0, 0xA0]);
      expect(find.text('${indent}Market'), findsOneComponent);
      expect(find.text('Food'), findsNComponents(2));
    });

    testComponents('of the quiet value is dimmed', (tester) async {
      tester.pumpComponent(
        BirkaSelect<String>(
          label: 'Role',
          options: const {'skip': 'Skip'},
          selected: 'skip',
          quiet: true,
          pill: true,
          onChanged: (_) {},
        ),
      );

      expect(
        withClasses('birka-select birka-select--pill birka-select--quiet'),
        findsOneComponent,
      );
    });
  });

  group('GlassOption', () {
    testComponents('says whether it is chosen and chooses itself', (
      tester,
    ) async {
      var taps = 0;
      tester.pumpComponent(
        GlassOption(
          title: 'Salary card',
          tag: 'CSV',
          badge: 'the card matched',
          subtitle: 'Rubles · Debit',
          selected: true,
          trailing: const span([Component.text('142 679,81 ₽')]),
          onTap: () => taps++,
        ),
      );

      await tester.click(find.tag('button'));

      expect(taps, 1);
      final attributes = attributesOf(find.tag('button'));
      expect(attributes['role'], 'radio');
      expect(attributes['aria-checked'], 'true');
      expect(find.text('the card matched'), findsOneComponent);
      expect(
        withClasses('glass-option glass-option--selected'),
        findsOneComponent,
      );
    });

    testComponents('that fits worse is dimmed', (tester) async {
      tester.pumpComponent(
        GlassOption(
          title: 'Euro card',
          selected: false,
          dimmed: true,
          onTap: () {},
        ),
      );

      expect(
        withClasses('glass-option glass-option--dimmed'),
        findsOneComponent,
      );
      expect(attributesOf(find.tag('button'))['aria-checked'], 'false');
    });
  });

  testComponents('BirkaButton that is compact is as wide as its label', (
    tester,
  ) async {
    tester.pumpComponent(
      BirkaButton(label: 'Undo', compact: true, quiet: true, onPressed: () {}),
    );

    expect(
      withClasses(
        'text-label birka-button birka-button--quiet '
        'birka-button--compact',
      ),
      findsOneComponent,
    );
  });

  testComponents('BirkaChip says how many things its option holds', (
    tester,
  ) async {
    tester.pumpComponent(
      BirkaChip(label: 'All', selected: true, count: 15, onTap: () {}),
    );

    expect(find.text('15'), findsOneComponent);
    expect(withClasses('text-caption birka-chip__count'), findsOneComponent);
    expect(
      withClasses('birka-chip__room birka-chip__room--open'),
      findsOneComponent,
    );
  });

  testComponents('BirkaChip keeps the room of a count shut without one', (
    tester,
  ) async {
    tester.pumpComponent(
      BirkaChip(label: 'Imports', selected: false, onTap: () {}),
    );

    expect(withClasses('birka-chip__room'), findsOneComponent);
    expect(withClasses('text-caption birka-chip__count'), findsNothing);
  });

  testComponents('BirkaCheckbox ticks and says so', (tester) async {
    final changes = <bool>[];
    tester.pumpComponent(
      BirkaCheckbox(checked: false, label: 'Pick', onChanged: changes.add),
    );

    await tester.click(find.tag('button'));

    expect(changes, [true]);
    final attributes = attributesOf(find.tag('button'));
    expect(attributes['role'], 'checkbox');
    expect(attributes['aria-checked'], 'false');
    expect(attributes['aria-label'], 'Pick');
    expect(find.byType(BirkaIcon), findsNothing);
  });

  testComponents('BirkaCheckbox that is ticked shows a check', (tester) async {
    tester.pumpComponent(
      BirkaCheckbox(checked: true, label: 'Pick', onChanged: (_) {}),
    );

    expect(
      withClasses('birka-checkbox birka-checkbox--checked'),
      findsOneComponent,
    );
    expect(find.byType(BirkaIcon), findsOneComponent);
  });

  group('GlassPageHeader', () {
    testComponents('can have a way back and a line under the heading', (
      tester,
    ) async {
      tester.pumpComponent(
        const GlassPageHeader(
          title: 'Payments',
          subtitle: 'Next on 25 November',
          leading: Component.text('Back'),
          trailing: Component.text('Add'),
        ),
      );

      expect(
        withClasses('glass-page-header glass-page-header--full'),
        findsOneComponent,
      );
      expect(
        find.descendant(
          of: withClasses('glass-page-header__heading'),
          matching: find.text('Next on 25 November'),
        ),
        findsOneComponent,
      );
      expect(find.tag('h1'), findsOneComponent);
    });

    testComponents('stays as it was without them', (tester) async {
      tester.pumpComponent(const GlassPageHeader(title: 'Accounts'));

      expect(withClasses('glass-page-header'), findsOneComponent);
      expect(withClasses('glass-page-header__heading'), findsNothing);
    });
  });

  group('GlassListRow with an action', () {
    testComponents('keeps the button out of its link', (tester) async {
      var dropped = 0;
      tester.pumpComponent(
        GlassListRow(
          title: 'Plus',
          href: 'new',
          action: GlassIconButton(
            glyph: BirkaGlyph.close,
            label: 'Not regular',
            glass: false,
            onPressed: () => dropped++,
          ),
        ),
      );

      expect(withClasses('glass-row glass-row--split'), findsOneComponent);
      expect(attributesOf(find.tag('a'))['href'], 'new');
      expect(
        find.descendant(of: find.tag('a'), matching: find.tag('button')),
        findsNothing,
      );
      expect(
        withClasses('glass-icon-button glass-icon-button--plain'),
        findsOneComponent,
      );

      await tester.click(find.tag('button'));
      expect(dropped, 1);
    });
  });

  testComponents('GlassSteps numbers its points under its title', (
    tester,
  ) async {
    tester.pumpComponent(
      const GlassSteps(title: 'How it works', points: ['Read', 'Check']),
    );

    expect(find.text('How it works'), findsOneComponent);
    expect(find.tag('li'), findsNComponents(2));
    expect(
      find.descendant(
        of: withClasses('text-caption glass-steps__number'),
        matching: find.text('2'),
      ),
      findsOneComponent,
    );
  });

  group('BirkaFold', () {
    testComponents('is out of reach while closed', (tester) async {
      tester.pumpComponent(
        const BirkaFold(open: false, children: [Component.text('Advance')]),
      );

      final fold =
          withClasses('birka-fold').evaluate().single.component as DomComponent;
      expect(fold.attributes, containsPair('aria-hidden', 'true'));
      expect(fold.attributes, contains('inert'));
      expect(find.text('Advance'), findsOneComponent);
    });

    testComponents('opens with the gap of its column', (tester) async {
      tester.pumpComponent(
        const BirkaFold(
          open: true,
          gap: 'var(--space-md)',
          children: [Component.text('Advance')],
        ),
      );

      final fold =
          withClasses('birka-fold birka-fold--open').evaluate().single.component
              as DomComponent;
      expect(fold.attributes, isNull);
      expect(fold.styles!.properties['--birka-fold-gap'], 'var(--space-md)');
    });
  });

  testComponents('BirkaForm puts its aside and its button beside the fields', (
    tester,
  ) async {
    tester.pumpComponent(
      BirkaForm(
        title: 'New payment',
        closeLabel: 'Close',
        onClose: () {},
        submitLabel: 'Save',
        onSubmit: () {},
        aside: const [Component.text('Preview')],
        children: const [Component.text('Name')],
      ),
    );

    expect(
      find.descendant(
        of: withClasses('birka-split__aside'),
        matching: find.text('Preview'),
      ),
      findsOneComponent,
    );
    expect(
      find.descendant(
        of: withClasses('birka-split__aside'),
        matching: withClasses('birka-form__actions'),
      ),
      findsOneComponent,
    );
    expect(
      find.descendant(
        of: withClasses('birka-split__main'),
        matching: find.text('Name'),
      ),
      findsOneComponent,
    );
  });

  group('ForecastChart', () {
    ForecastChart chart({required double pace}) => ForecastChart(
      start: 29651,
      pace: pace,
      days: 17,
      label: 'Money runs out on 2 December.',
      from: 'today',
      to: '5 Dec · payday',
      usual: 'as usual',
      planned: 'by the plan',
    );

    testComponents('marks where the usual pace runs out', (tester) async {
      tester.pumpComponent(chart(pace: 2100));

      expect(
        attributesOf(withClasses('forecast-chart__plot'))['aria-label'],
        'Money runs out on 2 December.',
      );
      expect(withClasses('forecast-chart__under'), findsOneComponent);
      expect(withClasses('forecast-chart__dot'), findsOneComponent);
      expect(find.text('5 Dec · payday'), findsOneComponent);
      expect(find.text('by the plan'), findsOneComponent);
    });

    testComponents('has no dot while the money lasts', (tester) async {
      tester.pumpComponent(chart(pace: 1500));

      expect(withClasses('forecast-chart__under'), findsNothing);
      expect(withClasses('forecast-chart__dot'), findsNothing);
    });
  });

  testComponents('GlassPanel holds a view on glass that comes in', (
    tester,
  ) async {
    tester.pumpComponent(const GlassPanel(child: Component.text('Card')));

    expect(withClasses('glass glass-panel'), findsOneComponent);
    expect(find.text('Card'), findsOneComponent);
  });

  testComponents('BirkaLinkRow leads on with a chevron at its end', (
    tester,
  ) async {
    tester.pumpComponent(
      const BirkaLinkRow(label: 'Report for October', href: 'reports/'),
    );

    expect(attributesOf(find.tag('a'))['href'], 'reports/');
    expect(find.text('Report for October'), findsOneComponent);
    expect(find.byType(BirkaIcon), findsOneComponent);
  });

  testComponents('BirkaRule is a thin line', (tester) async {
    tester.pumpComponent(const BirkaRule());

    expect(withClasses('birka-rule'), findsOneComponent);
  });

  testComponents('BirkaFieldPair stands two fields side by side', (
    tester,
  ) async {
    tester.pumpComponent(
      const BirkaFieldPair(
        stacksWhenNarrow: true,
        children: [Component.text('Name'), Component.text('Amount')],
      ),
    );

    expect(
      withClasses('birka-field-pair birka-field-pair--stacks'),
      findsOneComponent,
    );
    expect(find.text('Amount'), findsOneComponent);
  });
}
