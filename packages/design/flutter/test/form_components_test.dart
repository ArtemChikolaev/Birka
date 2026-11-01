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

    testWidgets('does nothing while it is disabled', (tester) async {
      await tester.pumpWidget(app(const BirkaButton(label: 'Save')));
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, lessThan(1));
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
