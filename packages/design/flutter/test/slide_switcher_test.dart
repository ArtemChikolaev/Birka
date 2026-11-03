import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// One theme for every frame, so that the app has no theme to animate to.
final ThemeData theme = BirkaTheme.dark();

Widget app(Widget child, {bool reduced = false}) => MaterialApp(
  theme: theme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

/// How far the child that says [text] stands from its place.
double offsetOf(WidgetTester tester, String text) => tester
    .widget<Transform>(
      find
          .ancestor(of: find.text(text), matching: find.byType(Transform))
          .first,
    )
    .transform
    .getTranslation()
    .x;

double opacityOf(WidgetTester tester, String text) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first,
    )
    .opacity;

void main() {
  group('SlideSwitcher', () {
    Widget month(int value, {bool reduced = false}) => app(
      SlideSwitcher(
        value: value,
        child: SizedBox(width: 200, height: 40, child: Text('month $value')),
      ),
      reduced: reduced,
    );

    testWidgets('an earlier value comes from the start and pushes the old '
        'one toward the end', (tester) async {
      await tester.pumpWidget(month(11));
      await tester.pumpWidget(month(10));
      await tester.pump(BirkaMotion.base ~/ 2);

      expect(offsetOf(tester, 'month 11'), greaterThan(0));
      expect(offsetOf(tester, 'month 10'), lessThan(0));

      await tester.pumpAndSettle();

      expect(find.text('month 11'), findsNothing);
      expect(offsetOf(tester, 'month 10'), 0);
      expect(opacityOf(tester, 'month 10'), 1);
    });

    testWidgets('a later value comes from the end', (tester) async {
      await tester.pumpWidget(month(10));
      await tester.pumpWidget(month(11));
      await tester.pump(BirkaMotion.base ~/ 2);

      expect(offsetOf(tester, 'month 10'), lessThan(0));
      expect(offsetOf(tester, 'month 11'), greaterThan(0));
    });

    testWidgets('only cross-fades when asked for less motion', (tester) async {
      await tester.pumpWidget(month(11, reduced: true));
      await tester.pumpWidget(month(10, reduced: true));
      await tester.pump(BirkaMotion.base ~/ 2);

      expect(offsetOf(tester, 'month 11'), 0);
      expect(offsetOf(tester, 'month 10'), 0);
      expect(opacityOf(tester, 'month 11'), lessThan(1));
    });
  });

  group('SlideSwitcher.sliver', () {
    late List<int> tapped;

    Widget list(int value) => MaterialApp(
      theme: theme,
      home: CustomScrollView(
        slivers: [
          SlideSwitcher.sliver(
            value: value,
            sliver: SliverList.list(
              children: [
                GestureDetector(
                  onTap: () => tapped.add(value),
                  child: SizedBox(height: 40, child: Text('month $value')),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    setUp(() => tapped = []);

    testWidgets('slides the old list away and the new one in', (
      tester,
    ) async {
      await tester.pumpWidget(list(11));
      final rest = tester.getTopLeft(find.text('month 11')).dx;
      await tester.pumpWidget(list(10));
      await tester.pump(BirkaMotion.base ~/ 2);

      expect(tester.getTopLeft(find.text('month 11')).dx, greaterThan(rest));
      expect(tester.getTopLeft(find.text('month 10')).dx, lessThan(rest));

      await tester.tap(find.text('month 10'), warnIfMissed: false);
      expect(tapped, [10]);

      await tester.pumpAndSettle();

      expect(find.text('month 11'), findsNothing);
      expect(tester.getTopLeft(find.text('month 10')).dx, rest);
    });
  });

  group('SwipeBetween', () {
    late List<String> turned;

    Widget swipe() => app(
      SwipeBetween(
        onPrevious: () => turned.add('previous'),
        onNext: () => turned.add('next'),
        child: const SizedBox(
          width: 300,
          height: 300,
          child: SlideSwitcher(value: 1, follow: true, child: Text('page')),
        ),
      ),
    );

    setUp(() => turned = []);

    testWidgets('a swipe toward the end turns back, toward the start on', (
      tester,
    ) async {
      await tester.pumpWidget(swipe());

      await tester.drag(find.text('page'), const Offset(120, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.text('page'), const Offset(-120, 0));
      await tester.pumpAndSettle();

      expect(turned, ['previous', 'next']);
    });

    testWidgets('a short slow swipe goes back without turning', (
      tester,
    ) async {
      await tester.pumpWidget(swipe());

      await tester.timedDrag(
        find.text('page'),
        const Offset(30, 0),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();

      expect(turned, isEmpty);
      expect(offsetOf(tester, 'page'), 0);
    });

    testWidgets('the page follows the finger by half, up to half its way', (
      tester,
    ) async {
      await tester.pumpWidget(swipe());
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('page')),
      );

      await gesture.moveBy(const Offset(20, 0));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      final half = tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byType(AnimatedSwitcher),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getTranslation()
          .x;
      expect(half, inExclusiveRange(0, 24.01));

      await gesture.moveBy(const Offset(200, 0));
      await tester.pump();
      final most = tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byType(AnimatedSwitcher),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getTranslation()
          .x;
      expect(most, 24);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  testWidgets('a chip with an order slides its new label in', (tester) async {
    Widget chip(int month, String label) => app(
      BirkaChip(label: label, selected: false, onTap: () {}, order: month),
    );
    await tester.pumpWidget(chip(11, 'November'));
    await tester.pumpWidget(chip(10, 'October'));
    await tester.pump(BirkaMotion.base ~/ 2);

    expect(find.text('November'), findsOneWidget);
    expect(find.text('October'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('November'), findsNothing);
    expect(find.text('October'), findsOneWidget);
  });
}
