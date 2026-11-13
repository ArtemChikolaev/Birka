import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(
  theme: BirkaTheme.dark(),
  home: Scaffold(body: child),
);

void main() {
  group('GlassSearchField', () {
    late TextEditingController controller;

    setUp(() => controller = TextEditingController());
    tearDown(() => controller.dispose());

    Future<List<String>> pump(WidgetTester tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        app(
          GlassSearchField(
            label: 'Search',
            clearLabel: 'Clear',
            hint: 'Cafe or 250',
            controller: controller,
            onChanged: changes.add,
          ),
        ),
      );
      return changes;
    }

    testWidgets('reports what is typed', (tester) async {
      final changes = await pump(tester);

      expect(find.text('Cafe or 250'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'cafe');

      expect(changes, ['cafe']);
    });

    testWidgets('offers the cross only when there is something to clear', (
      tester,
    ) async {
      final changes = await pump(tester);
      expect(find.bySemanticsLabel('Clear'), findsNothing);

      await tester.enterText(find.byType(TextField), 'cafe');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changes, ['cafe', '']);
      expect(find.bySemanticsLabel('Clear'), findsNothing);
    });
  });

  testWidgets('the cross is a button of its own for screen readers', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'cafe');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(
        GlassSearchField(
          label: 'Search',
          clearLabel: 'Clear',
          controller: controller,
          onChanged: (_) {},
        ),
      ),
    );

    final button = tester.getRect(find.bySemanticsLabel('Clear'));
    final field = tester.getRect(find.byType(GlassSearchField));

    expect(button.width, lessThan(field.width / 2));
    expect(button.right, closeTo(field.right, 24));
  });

  testWidgets('takes the focus at once and answers the search key', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final sent = <String>[];
    await tester.pumpWidget(
      app(
        GlassSearchField(
          label: 'Search',
          clearLabel: 'Clear',
          controller: controller,
          onChanged: (_) {},
          autofocus: true,
          onSubmitted: sent.add,
        ),
      ),
    );
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(find.byType(TextField), 'cafe');
    await tester.testTextInput.receiveAction(TextInputAction.search);

    expect(sent, ['cafe']);
  });

  testWidgets('the cross keeps the keyboard for a new word', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(
        GlassSearchField(
          label: 'Search',
          clearLabel: 'Clear',
          controller: controller,
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'cafe');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Clear'));
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('a tap elsewhere puts the keyboard away', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(
        Column(
          children: [
            GlassSearchField(
              label: 'Search',
              clearLabel: 'Clear',
              controller: controller,
              onChanged: (_) {},
            ),
            const SizedBox(height: 200, child: Text('Elsewhere')),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.tap(find.text('Elsewhere'));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  group('GlassSwipeRow', () {
    late List<String> calls;

    setUp(() => calls = []);

    Widget row() => GlassSwipeRow(
      actions: [
        GlassSwipeAction(
          glyph: BirkaGlyph.copy,
          label: 'Repeat',
          onPressed: () => calls.add('repeat'),
        ),
        GlassSwipeAction(
          glyph: BirkaGlyph.trash,
          label: 'Delete',
          danger: true,
          onPressed: () => calls.add('delete'),
        ),
      ],
      child: GlassListRow(title: 'Coffee', onTap: () => calls.add('open')),
    );

    Finder glyph(BirkaGlyph glyph) => find.byWidgetPredicate(
      (widget) => widget is BirkaIcon && widget.glyph == glyph,
    );

    double slide(WidgetTester tester) =>
        tester.getTopLeft(find.text('Coffee')).dx;

    Future<double> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          Column(
            children: [
              row(),
              const SizedBox(height: 300, child: Text('Elsewhere')),
            ],
          ),
        ),
      );
      return slide(tester);
    }

    testWidgets('a closed row shows no buttons through its glass', (
      tester,
    ) async {
      await pump(tester);
      final room = find
          .ancestor(
            of: glyph(BirkaGlyph.trash),
            matching: find.byType(ClipRect),
          )
          .first;

      expect(tester.getSize(room).width, 0);

      await tester.drag(find.text('Coffee'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(tester.getSize(room).width, greaterThan(100));
    });

    testWidgets('a tap on a closed row goes to the row', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Coffee'));

      expect(calls, ['open']);
    });

    testWidgets('a swipe shows the buttons', (tester) async {
      final start = await pump(tester);

      await tester.drag(find.text('Coffee'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(slide(tester), lessThan(start));
      await tester.tap(glyph(BirkaGlyph.trash));
      await tester.pumpAndSettle();
      expect(calls, ['delete']);
      expect(slide(tester), start);
    });

    testWidgets('a short slow swipe falls back', (tester) async {
      final start = await pump(tester);

      await tester.timedDrag(
        find.text('Coffee'),
        const Offset(-30, 0),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();

      expect(slide(tester), start);
    });

    testWidgets('a flick opens it however short it is', (tester) async {
      final start = await pump(tester);

      await tester.fling(find.text('Coffee'), const Offset(-60, 0), 1000);
      await tester.pumpAndSettle();

      expect(slide(tester), lessThan(start));
    });

    testWidgets('cannot slide to the right', (tester) async {
      final start = await pump(tester);

      await tester.drag(find.text('Coffee'), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(slide(tester), start);
    });

    testWidgets('a tap on an open row closes it and opens nothing', (
      tester,
    ) async {
      final start = await pump(tester);
      await tester.drag(find.text('Coffee'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      final row = tester.getCenter(find.byType(GlassSwipeRow));
      await tester.tapAt(row);
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
      expect(slide(tester), start);
    });

    testWidgets('a tap elsewhere closes it', (tester) async {
      final start = await pump(tester);
      await tester.drag(find.text('Coffee'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elsewhere'));
      await tester.pumpAndSettle();

      expect(slide(tester), start);
    });

    testWidgets('screen readers get the actions without the swipe', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      final node = tester.getSemantics(find.byType(MergeSemantics));
      final labels = [
        for (final id in node.getSemanticsData().customSemanticsActionIds ?? [])
          CustomSemanticsAction.getAction(id as int)?.label,
      ];

      expect(labels, unorderedEquals(['Repeat', 'Delete']));
      handle.dispose();
    });
  });

  testWidgets('a button that cannot be taken back wears the loss color', (
    tester,
  ) async {
    const colors = BirkaColors.dark;
    await tester.pumpWidget(
      app(
        Center(
          child: BirkaButton(label: 'Delete', danger: true, onPressed: () {}),
        ),
      ),
    );

    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(BirkaButton),
        matching: find.byType(Container),
      ),
    );
    expect(
      (box.decoration! as BoxDecoration).color,
      colors.negative.withValues(alpha: 0.16),
    );
  });

  group('GlassListRow', () {
    testWidgets('a row that cannot be taken back has a red title', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(GlassListRow(title: 'Delete all data', danger: true, onTap: () {})),
      );

      final title = tester.widget<Text>(find.text('Delete all data'));
      expect(title.style!.color, BirkaColors.dark.negative);
    });

    testWidgets('a row that adds something has a title of the accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(GlassListRow(title: 'New category', accent: true, onTap: () {})),
      );

      final title = tester.widget<Text>(find.text('New category'));
      expect(title.style!.color, BirkaColors.dark.accent);
    });

    testWidgets('a subtitle takes the lines it is given', (tester) async {
      await tester.pumpWidget(
        app(
          const GlassListRow(
            title: 'Operations as CSV',
            subtitle: 'For Excel and Google Sheets',
            subtitleLines: 2,
          ),
        ),
      );

      final subtitle = tester.widget<Text>(
        find.text('For Excel and Google Sheets'),
      );
      expect(subtitle.maxLines, 2);
    });
  });

  group('GlassToast', () {
    testWidgets('says what came of an action and goes away', (tester) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showGlassToast(context, 'Copy saved'),
              child: const Text('Save'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Copy saved'), findsOneWidget);
      final icon = tester.widget<BirkaIcon>(find.byType(BirkaIcon));
      expect(icon.glyph, BirkaGlyph.check);
      // The overlay stands outside the material of the page, so the toast
      // brings its own text style instead of the bare fallback.
      final line = tester.widget<RichText>(
        find.descendant(
          of: find.text('Copy saved'),
          matching: find.byType(RichText),
        ),
      );
      expect(line.text.style?.decoration, isNot(TextDecoration.underline));

      // Its clock starts once it has come in.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Copy saved'), findsNothing);
    });

    double riseOf(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .ancestor(
                of: find.byType(GlassToast),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getTranslation()
        .y;

    // The toast stands on the overlay, above the page, so the system asks for
    // less motion above the navigator, as it does in the app.
    Widget saving({bool reduced = false}) => MaterialApp(
      theme: BirkaTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showGlassToast(context, 'Copy saved'),
              child: const Text('Save'),
            ),
          ),
        ),
      ),
    );

    testWidgets('comes up from below and reads itself out', (tester) async {
      final announced = <Object?>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            (message) async => announced.add(message),
          );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            ),
      );
      await tester.pumpWidget(saving());

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(BirkaMotion.spring ~/ 4);

      expect(riseOf(tester), greaterThan(0));
      expect(announced.toString(), contains('Copy saved'));

      await tester.pumpAndSettle();

      expect(riseOf(tester), moreOrLessEquals(0));
    });

    testWidgets('goes a little down as it fades away', (tester) async {
      await tester.pumpWidget(saving());

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(BirkaMotion.base ~/ 2);

      expect(riseOf(tester), inExclusiveRange(0, BirkaTokens.spaceMd + 1));

      await tester.pumpAndSettle();

      expect(find.byType(GlassToast), findsNothing);
    });

    testWidgets('only fades when asked for less motion', (tester) async {
      await tester.pumpWidget(saving(reduced: true));

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(BirkaMotion.spring ~/ 4);

      expect(riseOf(tester), 0);
    });

    testWidgets('takes the place of the toast before it', (tester) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showGlassToast(context, 'First');
                showGlassToast(context, 'Not a copy', trouble: true);
              },
              child: const Text('Go'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.text('First'), findsNothing);
      expect(find.text('Not a copy'), findsOneWidget);
      final icon = tester.widget<BirkaIcon>(find.byType(BirkaIcon));
      expect(icon.glyph, BirkaGlyph.close);
    });
  });
}
