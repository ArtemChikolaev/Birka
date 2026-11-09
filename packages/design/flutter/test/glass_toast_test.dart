import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(WidgetTester tester, {double? bar}) async {
    Widget page = Builder(
      builder: (context) => Center(
        child: GestureDetector(
          onTap: () => showGlassToast(context, 'Saved'),
          child: const Text('Save'),
        ),
      ),
    );
    if (bar != null) page = GlassNavBarSpace(height: bar, child: page);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: Scaffold(body: page),
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  double gapBelow(WidgetTester tester) =>
      tester.getSize(find.byType(Scaffold)).height -
      tester.getBottomLeft(find.byType(GlassToast)).dy;

  Future<void> letItGo(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(GlassToast), findsNothing);
  }

  testWidgets('a toast stands at the bottom of a page', (tester) async {
    await show(tester);

    expect(gapBelow(tester), BirkaTokens.spaceLg);
    await letItGo(tester);
  });

  testWidgets('a toast from a tab stands above the bar of the tabs', (
    tester,
  ) async {
    await show(tester, bar: 98);

    expect(gapBelow(tester), 98 + BirkaTokens.spaceSm);
    await letItGo(tester);
  });

  testWidgets('an action at the end of a toast happens and takes it away', (
    tester,
  ) async {
    var undone = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: GestureDetector(
                onTap: () => showGlassToast(
                  context,
                  'Dropped',
                  action: (label: 'Undo', onPressed: () => undone++),
                ),
                child: const Text('Drop'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Drop'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Undo'), findsOneWidget);
    // The button keeps the toast as tall as one without it.
    expect(
      tester.getSize(find.byType(GlassToast)).height,
      BirkaTokens.sizeTouchTarget + 2 * BirkaTokens.spaceXs,
    );
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(undone, 1);
    expect(find.byType(GlassToast), findsNothing);
  });
}
