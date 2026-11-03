import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(
  List<Page<void>> pages, {
  TargetPlatform platform = TargetPlatform.android,
  bool disableAnimations = false,
  void Function(Page<Object?> page)? onRemoved,
}) => MaterialApp(
  theme: BirkaTheme.dark().copyWith(platform: platform),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(disableAnimations: disableAnimations),
    child: child!,
  ),
  home: Navigator(pages: pages, onDidRemovePage: onRemoved ?? (_) {}),
);

const below = MaterialPage<void>(
  key: ValueKey('below'),
  child: Text('Below'),
);

Route<dynamic> routeOf(WidgetTester tester, String text) =>
    ModalRoute.of(tester.element(find.text(text)))!;

double riseOf(WidgetTester tester) => tester
    .widget<Transform>(
      find.ancestor(of: find.text('Rises'), matching: find.byType(Transform)),
    )
    .transform
    .getTranslation()
    .y;

void main() {
  group('BirkaSheetPage', () {
    testWidgets('is the sheet of the system on iOS', (tester) async {
      await tester.pumpWidget(
        app(const [
          below,
          BirkaSheetPage(key: ValueKey('sheet'), child: Text('Sheet')),
        ], platform: TargetPlatform.iOS),
      );

      expect(routeOf(tester, 'Sheet'), isA<CupertinoSheetRoute<void>>());
    });

    for (final (distance, closes) in [(200.0, true), (40.0, false)]) {
      testWidgets(
        'on iOS ${closes ? 'closes' : 'stays'} when its list is pulled '
        'down by $distance',
        (tester) async {
          final removed = <Page<Object?>>[];
          await tester.pumpWidget(
            app(
              [
                below,
                BirkaSheetPage(
                  key: const ValueKey('sheet'),
                  child: ListView(
                    children: [for (var i = 0; i < 30; i++) Text('Row $i')],
                  ),
                ),
              ],
              platform: TargetPlatform.iOS,
              onRemoved: removed.add,
            ),
          );

          await tester.drag(find.text('Row 3'), Offset(0, distance));
          await tester.pumpAndSettle();

          expect(removed.map((page) => page.key), [
            if (closes) const ValueKey('sheet'),
          ]);
        },
      );
    }

    testWidgets('is a full screen dialog elsewhere', (tester) async {
      await tester.pumpWidget(
        app(const [
          below,
          BirkaSheetPage(key: ValueKey('sheet'), child: Text('Sheet')),
        ]),
      );

      final route = routeOf(tester, 'Sheet');
      expect(route, isA<MaterialRouteTransitionMixin<void>>());
      expect((route as PageRoute<void>).fullscreenDialog, isTrue);
    });
  });

  group('BirkaFadePage', () {
    const page = BirkaFadePage<void>(
      key: ValueKey('fade'),
      child: BirkaRise(child: Text('Rises')),
    );

    testWidgets('fades in over the page below while its parts rise', (
      tester,
    ) async {
      await tester.pumpWidget(app(const [below]));
      await tester.pumpWidget(app(const [below, page]));
      await tester.pump(BirkaMotion.slow ~/ 2);

      final opacity = tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: find.text('Rises'),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value;
      expect(opacity, inExclusiveRange(0, 1));
      expect(find.text('Below'), findsOneWidget);
      expect(riseOf(tester), inExclusiveRange(0, BirkaTokens.spaceXl));

      await tester.pumpAndSettle();

      expect(riseOf(tester), 0);
      expect(find.text('Below'), findsNothing);
      final route = routeOf(tester, 'Rises') as PageRoute<void>;
      expect(route.transitionDuration, BirkaMotion.slow);
      expect(route.reverseTransitionDuration, BirkaMotion.base);
    });

    testWidgets('keeps its parts in place when asked for less motion', (
      tester,
    ) async {
      await tester.pumpWidget(app(const [below], disableAnimations: true));
      await tester.pumpWidget(
        app(const [below, page], disableAnimations: true),
      );
      await tester.pump(BirkaMotion.slow ~/ 2);

      expect(
        find.ancestor(of: find.text('Rises'), matching: find.byType(Transform)),
        findsNothing,
      );
    });
  });

  testWidgets('BirkaRise stays put outside a fade page', (tester) async {
    await tester.pumpWidget(
      app(const [
        MaterialPage(
          key: ValueKey('page'),
          child: BirkaRise(child: Text('Rises')),
        ),
      ]),
    );

    expect(
      find.ancestor(of: find.text('Rises'), matching: find.byType(Transform)),
      findsNothing,
    );
  });
}
