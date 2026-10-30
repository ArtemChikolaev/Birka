import 'dart:io';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const destinations = [
  GlassNavDestination(glyph: BirkaGlyph.home, label: 'Overview'),
  GlassNavDestination(glyph: BirkaGlyph.list, label: 'Operations'),
  GlassNavDestination(glyph: BirkaGlyph.reports, label: 'Reports'),
  GlassNavDestination(glyph: BirkaGlyph.more, label: 'More'),
];

void main() {
  Widget bar({
    int selected = 0,
    ValueChanged<int>? onSelected,
    VoidCallback? onAction,
  }) {
    return MaterialApp(
      theme: BirkaTheme.dark(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 326,
            child: GlassNavBar(
              destinations: destinations,
              selectedIndex: selected,
              onSelected: onSelected ?? (_) {},
              actionLabel: 'New transaction',
              onAction: onAction ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  // The first Positioned in the bar holds the bubble.
  double bubbleLeft(WidgetTester tester) =>
      tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).left!;

  testWidgets('shows every tab', (tester) async {
    await tester.pumpWidget(bar());

    for (final destination in destinations) {
      expect(find.text(destination.label), findsOneWidget);
    }
  });

  testWidgets('a tap on a tab reports its index', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(bar(onSelected: tapped.add));

    await tester.tap(find.text('Overview'));
    await tester.tap(find.text('Reports'));
    await tester.tap(find.text('More'));

    expect(tapped, [0, 2, 3]);
  });

  testWidgets('a tap in the middle runs the action', (tester) async {
    var actions = 0;
    await tester.pumpWidget(bar(onAction: () => actions++));

    await tester.tap(find.bySemanticsLabel('New transaction'));

    expect(actions, 1);
  });

  testWidgets('the bubble skips the slot of the action', (tester) async {
    await tester.pumpWidget(bar());
    const slot = (326 - 12) / 5;
    expect(bubbleLeft(tester), 0);

    await tester.pumpWidget(bar(selected: 1));
    expect(bubbleLeft(tester), closeTo(slot, 0.01));

    await tester.pumpWidget(bar(selected: 2));
    expect(bubbleLeft(tester), closeTo(slot * 3, 0.01));

    await tester.pumpWidget(bar(selected: 3));
    expect(bubbleLeft(tester), closeTo(slot * 4, 0.01));
  });

  testWidgets('tells screen readers which tab is selected', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(bar(selected: 1));

    expect(
      find.bySemanticsLabel('Operations'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Operations')),
      containsSemantics(isButton: true, isSelected: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Overview')),
      containsSemantics(isButton: true, isSelected: false),
    );
    semantics.dispose();
  });

  test('every glyph has its file', () {
    for (final glyph in BirkaGlyph.values) {
      expect(
        File('icons/${glyph.name}.svg').existsSync(),
        isTrue,
        reason: '$glyph',
      );
    }
  });
}
