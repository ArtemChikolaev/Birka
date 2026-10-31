import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
}
