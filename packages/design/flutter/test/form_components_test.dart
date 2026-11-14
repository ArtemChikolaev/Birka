import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(
  theme: BirkaTheme.dark(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  const colors = BirkaColors.dark;

  group('GlassIconButton', () {
    testWidgets('reads its label and reacts to a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        app(
          GlassIconButton(
            glyph: BirkaGlyph.back,
            label: 'Back',
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      expect(taps, 1);
    });

    testWidgets('is big enough to hit', (tester) async {
      await tester.pumpWidget(
        app(
          GlassIconButton(
            glyph: BirkaGlyph.plus,
            label: 'Add',
            onPressed: () {},
          ),
        ),
      );
      final size = tester.getSize(find.byType(GlassIconButton));
      expect(size.width, BirkaTokens.sizeTouchTarget);
      expect(size.height, BirkaTokens.sizeTouchTarget);
    });

    testWidgets('can go without its glass and stay as big', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        app(
          GlassIconButton(
            glyph: BirkaGlyph.close,
            label: 'Close',
            glass: false,
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Close'));

      expect(taps, 1);
      expect(find.byType(GlassSurface), findsNothing);
      expect(
        tester.getSize(find.byType(GlassIconButton)),
        const Size.square(BirkaTokens.sizeTouchTarget),
      );
    });
  });

  group('BirkaArrowButton', () {
    testWidgets('reads its label and reacts to a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        app(BirkaArrowButton(label: 'Start', onPressed: () => taps++)),
      );

      await tester.tap(find.bySemanticsLabel('Start'));

      expect(taps, 1);
      expect(
        tester.getSize(find.byType(BirkaArrowButton)).height,
        BirkaArrowButton.height,
      );
    });

    testWidgets('says that it is off without a callback', (tester) async {
      await tester.pumpWidget(app(const BirkaArrowButton(label: 'Start')));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Start')),
        containsSemantics(isButton: true, isEnabled: false),
      );
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0.5,
      );
    });
  });

  group('BirkaChangePill', () {
    testWidgets('goes up in the color of a gain', (tester) async {
      await tester.pumpWidget(
        app(
          HiddenAmounts(
            notifier: ValueNotifier(false),
            child: const BirkaChangePill(label: '+100', rise: true),
          ),
        ),
      );

      expect(find.text('+100'), findsOneWidget);
      expect(
        tester.widget<BirkaIcon>(find.byType(BirkaIcon)).glyph,
        BirkaGlyph.rise,
      );
    });

    testWidgets('goes down in the color of a loss', (tester) async {
      await tester.pumpWidget(
        app(
          HiddenAmounts(
            notifier: ValueNotifier(false),
            child: const BirkaChangePill(label: '−100', rise: false),
          ),
        ),
      );

      final icon = tester.widget<BirkaIcon>(find.byType(BirkaIcon));
      expect(icon.glyph, BirkaGlyph.fall);
      expect(icon.color, colors.negative);
    });

    testWidgets('goes up in the color of bad news, as more spent', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          HiddenAmounts(
            notifier: ValueNotifier(false),
            child: const BirkaChangePill(
              label: '+100',
              rise: true,
              good: false,
            ),
          ),
        ),
      );

      final icon = tester.widget<BirkaIcon>(find.byType(BirkaIcon));
      expect(icon.glyph, BirkaGlyph.rise);
      expect(icon.color, colors.negative);
    });
  });

  group('BirkaStepBars', () {
    testWidgets('lights the bars up to the current step', (tester) async {
      await tester.pumpWidget(
        app(
          const SizedBox(
            width: 300,
            child: BirkaStepBars(count: 3, current: 1),
          ),
        ),
      );

      final fills = [
        for (final bar in tester.widgetList<AnimatedContainer>(
          find.byType(AnimatedContainer),
        ))
          (bar.decoration! as BoxDecoration).color,
      ];
      expect(fills, [colors.accent, colors.accent, colors.surfaceRaised]);
    });

    testWidgets('tells a screen reader where it stands', (tester) async {
      await tester.pumpWidget(
        app(
          const SizedBox(
            width: 300,
            child: BirkaStepBars(count: 3, current: 1),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(BirkaStepBars)),
        containsSemantics(value: '2 / 3'),
      );
    });
  });

  group('WelcomeArt', () {
    Future<Size> artOn(WidgetTester tester, Size screen) async {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const WelcomeArt()));
      return tester.getSize(find.byType(AspectRatio));
    }

    testWidgets('stops at its full size on a big screen', (tester) async {
      expect(await artOn(tester, const Size(800, 1200)), const Size(390, 300));
    });

    testWidgets('gives way on a short phone', (tester) async {
      final size = await artOn(tester, const Size(320, 568));

      expect(size.height, closeTo(193.1, 0.1));
      expect(size.width / size.height, closeTo(WelcomeArt.aspectRatio, 0.01));
    });

    testWidgets('stays out of screen readers', (tester) async {
      await tester.pumpWidget(app(const WelcomeArt()));

      expect(
        tester.widget<Image>(find.byType(Image)).excludeFromSemantics,
        isTrue,
      );
    });
  });

  testWidgets('GlassFileCard keeps the name of a file to one line', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: const Scaffold(
          body: SizedBox(
            width: 240,
            child: GlassFileCard(
              mark: GlyphBadge(
                glyph: BirkaGlyph.file,
                color: Color(0xFF8B5CF6),
              ),
              name: 'birka-2026-11-02-a-very-long-name-of-a-copy.birka',
              line: 'вчера, 18:40',
            ),
          ),
        ),
      ),
    );

    final name = tester.widget<Text>(
      find.text('birka-2026-11-02-a-very-long-name-of-a-copy.birka'),
    );
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(find.text('вчера, 18:40'), findsOneWidget);
    expect(find.byType(GlyphBadge), findsOneWidget);
  });

  group('showChoiceSheet', () {
    Future<void> open(
      WidgetTester tester,
      void Function((String?,)? picked) onClosed,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: BirkaTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => BirkaButton(
                label: 'Open',
                onPressed: () async => onClosed(
                  await showChoiceSheet<String?>(
                    context,
                    title: 'Pick',
                    choices: const [null, 'One'],
                    selected: 'One',
                    labelOf: (choice) => choice ?? 'None',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('marks what is selected', (tester) async {
      await open(tester, (_) {});

      expect(find.text('Pick'), findsOneWidget);
      expect(find.byType(BirkaIcon), findsOneWidget);
    });

    testWidgets('can give a choice a line and a mark', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: BirkaTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => BirkaButton(
                label: 'Open',
                onPressed: () => showChoiceSheet<String>(
                  context,
                  title: 'Pick',
                  choices: const ['One', 'Two'],
                  selected: 'One',
                  labelOf: (choice) => choice,
                  subtitleOf: (choice) => choice == 'Two' ? 'second' : null,
                  leadingOf: (choice) => choice == 'Two'
                      ? const CardArtThumbnail(art: CardArt.emerald)
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Open'));
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(find.byType(CardArtThumbnail), findsOneWidget);
    });

    testWidgets('can say more under the title and give a choice the accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: BirkaTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => BirkaButton(
                label: 'Open',
                onPressed: () => showChoiceSheet<String>(
                  context,
                  title: 'Pick',
                  subtitle: '14 operations',
                  choices: const ['One', 'New: Two'],
                  selected: 'One',
                  labelOf: (choice) => choice,
                  leadingOf: (choice) => const CategoryDot('#4ADE80'),
                  accentOf: (choice) => choice.startsWith('New'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Open'));
      await tester.pumpAndSettle();

      expect(find.text('14 operations'), findsOneWidget);
      expect(find.byType(CategoryDot), findsNWidgets(2));
      final made = tester.widget<Text>(find.text('New: Two'));
      final kept = tester.widget<Text>(find.text('One'));
      expect(made.style!.color, BirkaColors.dark.accent);
      expect(kept.style!.color, isNot(BirkaColors.dark.accent));
    });

    testWidgets('gives `null` as a choice in a record', (tester) async {
      (String?,)? picked;
      var closed = false;
      await open(tester, (choice) {
        picked = choice;
        closed = true;
      });

      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(picked, isNotNull);
      expect(picked?.$1, isNull);
    });

    testWidgets('gives no record when it is closed', (tester) async {
      (String?,)? picked = ('untouched',);
      await open(tester, (choice) => picked = choice);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(picked, isNull);
    });

    testWidgets('stops at the status bar and opens on the choice in use', (
      tester,
    ) async {
      // A phone of 390 by 800 with 60 of status bar above.
      tester.view
        ..physicalSize = const Size(780, 1600)
        ..devicePixelRatio = 2
        ..padding = const FakeViewPadding(top: 120)
        ..viewPadding = const FakeViewPadding(top: 120);
      addTearDown(tester.view.reset);
      int? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: BirkaTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => BirkaButton(
                label: 'Open',
                onPressed: () async {
                  final choice = await showChoiceSheet<int>(
                    context,
                    title: 'Day',
                    choices: [for (var day = 1; day <= 28; day++) day],
                    selected: 25,
                    labelOf: (day) => 'Day $day',
                  );
                  picked = choice?.$1;
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Open'));
      await tester.pumpAndSettle();

      // The title stays over the list, which opens on the choice in use.
      final title = tester.getRect(find.text('Day'));
      expect(title.top, greaterThan(60));
      final inUse = tester.getRect(find.text('Day 25'));
      expect(inUse.top, greaterThan(title.bottom));
      expect(inUse.bottom, lessThan(800));
      await tester.tap(find.text('Day 25'));
      await tester.pumpAndSettle();
      expect(picked, 25);
    });

    testWidgets('ends with an action that closes the sheet first', (
      tester,
    ) async {
      (String,)? picked = ('untouched',);
      final acted = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: BirkaTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => BirkaButton(
                label: 'Open',
                onPressed: () async => picked = await showChoiceSheet<String>(
                  context,
                  title: 'Pick',
                  choices: const ['One'],
                  selected: 'One',
                  labelOf: (choice) => choice,
                  action: (
                    label: 'New one',
                    onTap: () => acted.add(Navigator.of(context).canPop()),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Open'));
      await tester.pumpAndSettle();

      final label = tester.widget<Text>(find.text('New one'));
      expect(label.style!.color, BirkaColors.dark.accent);
      await tester.tap(find.text('New one'));
      await tester.pumpAndSettle();

      expect(acted, [false]);
      expect(picked, isNull);
      expect(find.text('Pick'), findsNothing);
    });
  });

  group('AccentLink', () {
    testWidgets('says its label in the accent with a chevron and taps', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        app(AccentLink(label: 'Turn on', onTap: () => taps++)),
      );

      final label = tester.widget<Text>(find.text('Turn on'));
      expect(label.style!.color, colors.accent);
      expect(find.byType(BirkaIcon), findsOneWidget);
      expect(tester.getSize(find.byType(AccentLink)).height, 44);
      await tester.tap(find.text('Turn on'));
      expect(taps, 1);
    });

    testWidgets('can span its width with the chevron at the end', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: AccentLink(label: 'All', onTap: () {}, expand: true),
          ),
        ),
      );

      expect(tester.getSize(find.byType(AccentLink)).width, 300);
      expect(
        tester.getTopRight(find.byType(BirkaIcon)).dx,
        tester.getTopRight(find.byType(AccentLink)).dx,
      );
    });
  });

  group('GlassListValue', () {
    testWidgets('leaves room for the title of its row', (tester) async {
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 320,
            child: GlassListRow(
              title: 'Base currency',
              trailing: GlassListValue('A value that goes on ' * 3),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(GlassListValue)).width, 180);
    });
  });

  group('GlassListGroup', () {
    testWidgets('draws a line only between rows', (tester) async {
      await tester.pumpWidget(
        app(
          const GlassListGroup(
            children: [
              GlassListRow(title: 'One'),
              GlassListRow(title: 'Two'),
              GlassListRow(title: 'Three'),
            ],
          ),
        ),
      );

      final lines = tester.widgetList<ColoredBox>(
        find.byWidgetPredicate(
          (widget) => widget is ColoredBox && widget.color == colors.hairline,
        ),
      );
      expect(lines, hasLength(2));
    });

    // A group stands in a list that scrolls, as on a screen.
    Widget keyed(List<String> titles) => app(
      SingleChildScrollView(
        child: SizedBox(
          width: 300,
          child: GlassListGroup(
            children: [
              for (final title in titles)
                GlassListRow(key: ValueKey(title), title: title),
            ],
          ),
        ),
      ),
    );

    testWidgets('opens a row that comes, with the line above it', (
      tester,
    ) async {
      await tester.pumpWidget(keyed(['One', 'Two']));
      final full = tester.getSize(find.byType(GlassListGroup)).height;
      await tester.pumpWidget(keyed(['One', 'Two', 'Three']));
      await tester.pump(BirkaMotion.slow ~/ 2);

      final half = tester.getSize(find.byType(GlassListGroup)).height;
      expect(half, greaterThan(full));

      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(GlassListGroup)).height,
        greaterThan(half),
      );
      final lines = tester.widgetList<ColoredBox>(
        find.byWidgetPredicate(
          (widget) => widget is ColoredBox && widget.color == colors.hairline,
        ),
      );
      expect(lines, hasLength(2));
    });

    testWidgets('closes a row that goes', (tester) async {
      await tester.pumpWidget(keyed(['One', 'Two', 'Three']));
      final full = tester.getSize(find.byType(GlassListGroup)).height;
      await tester.pumpWidget(keyed(['One', 'Three']));
      await tester.pump(BirkaMotion.slow ~/ 2);

      expect(find.text('Two'), findsOneWidget);
      final half = tester.getSize(find.byType(GlassListGroup)).height;
      expect(half, lessThan(full));

      await tester.pumpAndSettle();

      expect(find.text('Two'), findsNothing);
      expect(
        tester.getSize(find.byType(GlassListGroup)).height,
        lessThan(half),
      );
    });
  });

  group('GlassListRow', () {
    testWidgets('shows its text and what stands around it', (tester) async {
      await tester.pumpWidget(
        app(
          const GlassListRow(
            title: 'Card',
            subtitle: 'Rubles',
            leading: Text('Before'),
            trailing: Text('After'),
          ),
        ),
      );

      for (final text in ['Card', 'Rubles', 'Before', 'After']) {
        expect(find.text(text), findsOneWidget);
      }
    });

    testWidgets('is a button only with a callback', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        app(GlassListRow(title: 'Tap me', onTap: () => taps++)),
      );

      await tester.tap(find.text('Tap me'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.text('Tap me')),
        matchesSemantics(
          label: 'Tap me',
          isButton: true,
          hasTapAction: true,
        ),
      );

      await tester.pumpWidget(app(const GlassListRow(title: 'Plain')));
      expect(
        tester.getSemantics(find.text('Plain')),
        matchesSemantics(label: 'Plain'),
      );
      semantics.dispose();
    });
  });

  group('BirkaButton', () {
    testWidgets('writes its label in capitals and reads it as written', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(BirkaButton(label: 'Save', onPressed: () {})),
      );

      expect(find.text('SAVE'), findsOneWidget);
      expect(find.bySemanticsLabel('Save'), findsOneWidget);
    });

    testWidgets('a compact one is as wide as its label, with room to touch', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(BirkaButton(label: 'Yes', compact: true, onPressed: () {})),
      );

      final size = tester.getSize(find.byType(BirkaButton));
      expect(size.width, lessThan(120));
      expect(size.height, BirkaTokens.sizeTouchTarget);
      expect(find.text('YES'), findsOneWidget);
    });

    testWidgets('does nothing while it is disabled', (tester) async {
      await tester.pumpWidget(app(const BirkaButton(label: 'Save')));
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, lessThan(1));
    });

    Widget saving({required bool done, VoidCallback? onDone}) => app(
      SizedBox(
        width: 300,
        child: BirkaButton(
          label: 'Save',
          onPressed: done ? null : () {},
          done: done,
          onDone: onDone,
        ),
      ),
    );

    double widthOf(WidgetTester tester) => tester
        .getSize(
          find
              .descendant(
                of: find.byType(BirkaButton),
                matching: find.byType(Container),
              )
              .first,
        )
        .width;

    double checkOf(WidgetTester tester) => tester
        .widget<Opacity>(
          find.ancestor(
            of: find.byType(BirkaIcon),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;

    testWidgets('closes into a check mark once its action is done', (
      tester,
    ) async {
      var done = 0;
      await tester.pumpWidget(saving(done: false));
      await tester.pumpWidget(saving(done: true, onDone: () => done++));
      await tester.pump(BirkaMotion.fast);

      expect(widthOf(tester), inExclusiveRange(BirkaButton.height, 300));

      await tester.pump(BirkaMotion.slow);

      expect(widthOf(tester), moreOrLessEquals(BirkaButton.height));
      expect(checkOf(tester), closeTo(1, 0.01));
      expect(done, 0);

      await tester.pumpAndSettle();

      expect(done, 1);
      // It stays a check mark, without the dim of a disabled button.
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
    });

    testWidgets('can be measured on its way to the check mark', (
      tester,
    ) async {
      // Such as by a sheet that fills the rest of the screen.
      Widget measured({required bool done}) => app(
        IntrinsicHeight(
          child: SizedBox(
            width: 300,
            child: BirkaButton(
              label: 'Save',
              onPressed: done ? null : () {},
              done: done,
            ),
          ),
        ),
      );
      await tester.pumpWidget(measured(done: false));
      await tester.pumpWidget(measured(done: true));
      await tester.pump(BirkaMotion.fast);

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(BirkaButton)).height,
        BirkaButton.height,
      );
    });

    testWidgets('only fades into the check when asked for less motion', (
      tester,
    ) async {
      var done = 0;
      Widget reduced(Widget child) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: child,
      );
      await tester.pumpWidget(reduced(saving(done: false)));
      await tester.pumpWidget(
        reduced(saving(done: true, onDone: () => done++)),
      );
      await tester.pump(BirkaMotion.fast);

      expect(widthOf(tester), 300);
      expect(checkOf(tester), closeTo(1, 0.01));

      await tester.pumpAndSettle();

      expect(done, 1);
    });
  });

  group('BirkaChip', () {
    testWidgets('stands out when it is selected', (tester) async {
      Color fill() =>
          (tester
                      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                      .decoration!
                  as BoxDecoration)
              .color!;

      await tester.pumpWidget(
        app(BirkaChip(label: 'RUB', selected: true, onTap: () {})),
      );
      await tester.pumpAndSettle();
      expect(fill(), colors.text);

      await tester.pumpWidget(
        app(BirkaChip(label: 'RUB', selected: false, onTap: () {})),
      );
      await tester.pumpAndSettle();
      expect(fill(), colors.surfaceRaised);
    });

    testWidgets('is as wide as its label, not as the screen', (tester) async {
      await tester.pumpWidget(
        app(
          Wrap(
            children: [BirkaChip(label: 'EUR', selected: false, onTap: () {})],
          ),
        ),
      );
      expect(tester.getSize(find.byType(BirkaChip)).width, lessThan(120));
    });

    testWidgets('reports a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        app(BirkaChip(label: 'EUR', selected: false, onTap: () => taps++)),
      );
      await tester.tap(find.text('EUR'));
      expect(taps, 1);
    });

    testWidgets('shows its count beside its label', (tester) async {
      await tester.pumpWidget(
        app(BirkaChip(label: 'All', selected: true, count: 15, onTap: () {})),
      );

      expect(find.text('15'), findsOneWidget);
      expect(find.bySemanticsLabel('All, 15'), findsOneWidget);
    });

    testWidgets('shows a glyph after its label, turned as asked', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          BirkaChip(
            label: 'October',
            selected: true,
            trailingGlyph: BirkaGlyph.chevron,
            trailingTurns: 1,
            onTap: () {},
          ),
        ),
      );

      final icon = tester.widget<BirkaIcon>(find.byType(BirkaIcon));
      expect(icon.glyph, BirkaGlyph.chevron);
      expect(icon.color, colors.background);
      expect(
        tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns,
        1,
      );
      expect(
        tester.getTopLeft(find.byType(BirkaIcon)).dx,
        greaterThan(tester.getTopRight(find.text('October')).dx),
      );
    });
  });

  group('BirkaCheckbox', () {
    testWidgets('asks for the other state, in a place as large as a finger', (
      tester,
    ) async {
      bool? asked;
      await tester.pumpWidget(
        app(
          BirkaCheckbox(
            checked: false,
            label: 'Pick the coffee',
            onChanged: (value) => asked = value,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Pick the coffee'));

      expect(asked, isTrue);
      expect(
        tester.getSize(find.byType(BirkaCheckbox)),
        const Size.square(BirkaTokens.sizeTouchTarget),
      );
    });

    testWidgets('shows its check only when it is ticked', (tester) async {
      double check() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

      await tester.pumpWidget(
        app(BirkaCheckbox(checked: false, label: 'Pick', onChanged: (_) {})),
      );
      expect(check(), 0);

      await tester.pumpWidget(
        app(BirkaCheckbox(checked: true, label: 'Pick', onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(check(), 1);
    });
  });

  group('BirkaTextField', () {
    testWidgets('shows its label, hint and error', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          BirkaTextField(
            label: 'Name',
            controller: controller,
            hint: 'Salary card',
            error: 'Give it a name',
          ),
        ),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Salary card'), findsOneWidget);
      final error = tester.widget<Text>(find.text('Give it a name'));
      expect(error.style?.color, colors.negative);
    });

    testWidgets('reports what is typed', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final typed = <String>[];
      await tester.pumpWidget(
        app(
          BirkaTextField(
            label: 'Name',
            controller: controller,
            onChanged: typed.add,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Card');
      expect(typed, ['Card']);
      expect(controller.text, 'Card');
    });

    testWidgets('ends with its suffix', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(BirkaTextField(label: 'Sum', controller: controller, suffix: '₽')),
      );

      expect(find.text('₽'), findsOneWidget);
    });

    testWidgets('ends with a chip, takes several lines and glows for a '
        'moment', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var tapped = 0;
      Widget field({required bool highlighted}) => app(
        BirkaTextField(
          label: 'Phone',
          controller: controller,
          minLines: 3,
          maxLines: 6,
          highlighted: highlighted,
          trailing: BirkaChip(
            label: 'mobile',
            selected: false,
            compact: true,
            onTap: () => tapped++,
          ),
        ),
      );
      double glow() => tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(BirkaTextField),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity;
      await tester.pumpWidget(field(highlighted: false));

      await tester.tap(find.text('mobile'));
      expect(tapped, 1);
      final text = tester.widget<TextField>(find.byType(TextField));
      expect(text.minLines, 3);
      expect(text.maxLines, 6);
      expect(glow(), 0);

      await tester.pumpWidget(field(highlighted: true));
      expect(glow(), 1);
    });
  });

  group('showFieldSheet', () {
    testWidgets('says what the typed value means and fills in a suggestion', (
      tester,
    ) async {
      String? typed;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => BirkaButton(
              label: 'Open',
              onPressed: () async => typed = await showFieldSheet(
                context,
                label: 'Advance',
                done: 'Done',
                suffix: '₽',
                note: (text) => 'Rest: ${120 - (int.tryParse(text) ?? 0)}',
                suggestion: (label: 'Half · 60', value: '60'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Open'));
      await tester.pumpAndSettle();

      expect(find.text('₽'), findsOneWidget);
      expect(find.text('Rest: 120'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '40');
      await tester.pumpAndSettle();
      expect(find.text('Rest: 80'), findsOneWidget);

      await tester.tap(find.text('Half · 60'));
      await tester.pumpAndSettle();
      expect(find.text('Rest: 60'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Done'));
      await tester.pumpAndSettle();
      expect(typed, '60');
    });
  });

  group('CardArt', () {
    test('every art has its own color', () {
      final seen = {for (final art in CardArt.values) art.color};
      expect(seen, hasLength(CardArt.values.length));
    });

    testWidgets('a thumbnail keeps its size', (tester) async {
      await tester.pumpWidget(
        app(const CardArtThumbnail(art: CardArt.sapphire)),
      );
      expect(
        tester.getSize(find.byType(CardArtThumbnail)),
        CardArtThumbnail.size,
      );
    });

    testWidgets('a highlighted thumbnail has an accent border', (tester) async {
      await tester.pumpWidget(
        app(const CardArtThumbnail(art: CardArt.amber, highlighted: true)),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(CardArtSurface),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.border?.top.color, colors.accent);
    });

    // One theme for every frame, so that the app has no theme to animate to.
    final theme = BirkaTheme.dark();
    Widget card(
      CardArt art, {
      bool reduced = false,
      bool inSight = true,
    }) => MaterialApp(
      theme: theme,
      home: TickerMode(
        enabled: inSight,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Center(
            child: SizedBox(
              width: 300,
              height: 190,
              child: CardArtSurface(art: art),
            ),
          ),
        ),
      ),
    );

    testWidgets('a new art fades in over the old one', (tester) async {
      await tester.pumpWidget(card(CardArt.emerald));
      await tester.pumpAndSettle();
      await tester.pumpWidget(card(CardArt.amber));
      await tester.pump(BirkaMotion.slow ~/ 2);

      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpAndSettle();

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a new art waits until the card is in sight', (tester) async {
      await tester.pumpWidget(card(CardArt.emerald, inSight: false));
      await tester.pumpAndSettle();
      await tester.pumpWidget(card(CardArt.amber, inSight: false));
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(card(CardArt.amber));
      await tester.pump();

      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('a new art takes its place at once when asked for less '
        'motion', (tester) async {
      await tester.pumpWidget(card(CardArt.emerald, reduced: true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(card(CardArt.amber, reduced: true));

      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('GlassSegmented', () {
    testWidgets('writes its labels in capitals and reports a tap', (
      tester,
    ) async {
      final picked = <int>[];
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: GlassSegmented<int>(
              segments: const {1: 'One', 2: 'Two'},
              selected: 1,
              onChanged: picked.add,
            ),
          ),
        ),
      );

      await tester.tap(find.text('TWO'));
      expect(picked, [2]);
    });

    testWidgets('marks the picked option for screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: GlassSegmented<int>(
              segments: const {1: 'One', 2: 'Two'},
              selected: 2,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Two')),
        containsSemantics(label: 'Two', isButton: true, isSelected: true),
      );
      semantics.dispose();
    });
  });

  testWidgets('a badge tints its tile with the color of its icon', (
    tester,
  ) async {
    const color = Color(BirkaTokens.colorPaletteSky);
    await tester.pumpWidget(
      app(const GlyphBadge(glyph: BirkaGlyph.cart, color: color)),
    );

    final tile = tester.widget<Container>(
      find.descendant(
        of: find.byType(GlyphBadge),
        matching: find.byType(Container),
      ),
    );
    final decoration = tile.decoration! as BoxDecoration;
    expect(decoration.color, color.withValues(alpha: 0.16));
    expect(tester.widget<BirkaIcon>(find.byType(BirkaIcon)).color, color);
  });

  testWidgets('a badge eases into a new color', (tester) async {
    const sky = Color(BirkaTokens.colorPaletteSky);
    const amber = Color(BirkaTokens.colorPaletteAmber);
    final theme = BirkaTheme.dark();
    Widget badge(Color color) => MaterialApp(
      theme: theme,
      home: Center(
        child: GlyphBadge(glyph: BirkaGlyph.cart, color: color),
      ),
    );
    Color? iconColor() =>
        tester.widget<BirkaIcon>(find.byType(BirkaIcon)).color;
    await tester.pumpWidget(badge(sky));
    await tester.pumpWidget(badge(amber));
    await tester.pump(BirkaMotion.fast ~/ 2);

    expect(iconColor(), isNot(anyOf(sky, amber)));

    await tester.pumpAndSettle();

    expect(iconColor(), amber);
  });

  test('every glyph has its file', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final glyph in BirkaGlyph.values) {
      final svg = await rootBundle.loadString(
        'packages/design_flutter/icons/${glyph.name}.svg',
      );
      expect(svg, contains('currentColor'), reason: glyph.name);
    }
  });

  testWidgets('a quiet button leaves the emerald to the main one', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(BirkaButton(label: 'Later', quiet: true, onPressed: () {})),
    );
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(BirkaButton),
        matching: find.byType(Container),
      ),
    );
    expect((box.decoration! as BoxDecoration).color, colors.surfaceRaised);
  });

  testWidgets('a switch takes the accent when it is on', (tester) async {
    await tester.pumpWidget(app(Switch(value: true, onChanged: (_) {})));
    final theme = Theme.of(tester.element(find.byType(Switch))).switchTheme;
    expect(theme.trackColor?.resolve({WidgetState.selected}), colors.accent);
    expect(theme.trackColor?.resolve({}), colors.surfaceSelected);
  });

  group('GlassKeypad', () {
    late List<String> pressed;

    Future<void> pump(WidgetTester tester) async {
      pressed = [];
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 340,
            height: GlassKeypad.minHeight + 40,
            child: GlassKeypad(
              point: ',',
              pointLabel: 'Point',
              backspaceLabel: 'Erase',
              operatorLabels: const {KeypadOperator.add: 'Plus'},
              onDigit: (digit) => pressed.add('$digit'),
              onPoint: () => pressed.add('.'),
              onOperator: (key) => pressed.add(key.name),
              onBackspace: () => pressed.add('<'),
            ),
          ),
        ),
      );
    }

    testWidgets('has every digit', (tester) async {
      await pump(tester);

      for (var digit = 0; digit < 10; digit++) {
        await tester.tap(find.bySemanticsLabel('$digit'));
      }

      expect(pressed, [for (var digit = 0; digit < 10; digit++) '$digit']);
    });

    testWidgets('reports the keys that are not digits', (tester) async {
      await pump(tester);

      await tester.tap(find.bySemanticsLabel('Point'));
      await tester.tap(find.bySemanticsLabel('Erase'));
      await tester.tap(find.bySemanticsLabel('Plus'));
      await tester.tap(find.bySemanticsLabel('÷'));

      expect(pressed, ['.', '<', 'add', 'divide']);
    });

    testWidgets('shows the decimal mark it is given', (tester) async {
      await pump(tester);

      expect(find.text(','), findsOneWidget);
    });
  });

  group('BirkaChip', () {
    testWidgets('can stand with an icon', (tester) async {
      await tester.pumpWidget(
        app(
          BirkaChip(
            label: 'Card',
            selected: false,
            onTap: () {},
            glyph: BirkaGlyph.wallet,
          ),
        ),
      );

      final icon = tester.widget<BirkaIcon>(find.byType(BirkaIcon));
      expect(icon.glyph, BirkaGlyph.wallet);
      expect(find.text('Card'), findsOneWidget);
    });

    testWidgets('a long label stops at the edge of the screen', (tester) async {
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 120,
            child: BirkaChip(
              label: 'A very long name of an account',
              selected: false,
              onTap: () {},
              glyph: BirkaGlyph.wallet,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a dashed one has no fill', (tester) async {
      await tester.pumpWidget(
        app(
          BirkaChip(
            label: 'Add',
            selected: false,
            onTap: () {},
            dashed: true,
          ),
        ),
      );

      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0x00000000));
    });
  });

  group('what a database keeps as text', () {
    test('a glyph comes by its name', () {
      expect(BirkaGlyph.named('cart'), BirkaGlyph.cart);
    });

    test('a name from a newer version falls back', () {
      expect(BirkaGlyph.named('hologram'), BirkaGlyph.more);
      expect(BirkaGlyph.named(null), BirkaGlyph.more);
    });

    test('a color comes from its hex', () {
      expect(BirkaColors.fromHex('#4ade80'), const Color(0xFF4ADE80));
    });
  });
}
