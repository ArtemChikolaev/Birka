import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(
  List<Page<void>> pages, {
  TargetPlatform platform = TargetPlatform.android,
  bool disableAnimations = false,
  void Function(Page<Object?> page)? onRemoved,
  HeroController? heroes,
}) {
  final navigator = Navigator(
    pages: pages,
    onDidRemovePage: onRemoved ?? (_) {},
  );
  return MaterialApp(
    theme: BirkaTheme.dark().copyWith(platform: platform),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: disableAnimations),
      child: child!,
    ),
    home: heroes == null
        ? navigator
        : HeroControllerScope(controller: heroes, child: navigator),
  );
}

const below = MaterialPage<void>(
  key: ValueKey('below'),
  child: Text('Below'),
);

ModalRoute<dynamic> routeOf(WidgetTester tester, String text) =>
    ModalRoute.of(tester.element(find.text(text)))!;

/// How visible [text] is through the fades around it.
double opacityOf(WidgetTester tester, String text) => tester
    .widgetList<FadeTransition>(
      find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)),
    )
    .fold(1, (opacity, fade) => opacity * fade.opacity.value);

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

  group('BirkaZoomPage', () {
    const card = ValueKey('card');
    const place = ValueKey('place');

    // The card is 200 by 50 at 300 from the top of the screen below, and its
    // place is 300 by 100 at the top of the page.
    const below = MaterialPage<void>(
      key: ValueKey('below'),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(top: 300),
          child: DefaultTextStyle(
            style: TextStyle(fontSize: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BirkaZoomSource(
                  tag: 'a',
                  child: SizedBox(
                    key: card,
                    width: 200,
                    height: 50,
                    child: Text('Salary'),
                  ),
                ),
                BirkaGiveWay(child: Text('Bar')),
              ],
            ),
          ),
        ),
      ),
    );
    const zoom = BirkaZoomPage<void>(
      key: ValueKey('zoom'),
      tag: 'a',
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BirkaZoomTarget(
              child: SizedBox(key: place, width: 300, height: 100),
            ),
            Text('Page'),
          ],
        ),
      ),
    );
    const from = Rect.fromLTWH(0, 300, 200, 50);
    const to = Rect.fromLTWH(0, 0, 300, 100);

    late HeroController heroes;
    setUp(() => heroes = HeroController());
    tearDown(() => heroes.dispose());

    Iterable<Transform> barMoves(WidgetTester tester) =>
        tester.widgetList<Transform>(
          find.ancestor(of: find.text('Bar'), matching: find.byType(Transform)),
        );

    Future<void> backGesture(
      WidgetTester tester,
      String method, {
      double? progress,
    }) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.backGesture.name,
        SystemChannels.backGesture.codec.encodeMethodCall(
          MethodCall(
            method,
            progress == null
                ? null
                : {
                    'touchOffset': [5.0, 400.0],
                    'progress': progress,
                    'swipeEdge': 0,
                  },
          ),
        ),
        (_) {},
      );
      await tester.pump();
    }

    testWidgets('grows the card into its place as the page fades in', (
      tester,
    ) async {
      await tester.pumpWidget(app(const [below], heroes: heroes));
      expect(barMoves(tester), isEmpty);

      await tester.pumpWidget(app(const [below, zoom], heroes: heroes));
      await tester.pump();
      await tester.pump(BirkaMotion.zoom ~/ 2);

      final flying = tester.getRect(find.byKey(card));
      expect(flying.top, inExclusiveRange(to.top, from.top));
      expect(flying.height, inExclusiveRange(from.height, to.height));
      // It takes the style of its text along.
      final text = tester.widget<RichText>(
        find.descendant(of: find.byKey(card), matching: find.byType(RichText)),
      );
      expect(text.text.style!.fontSize, 13);
      expect(opacityOf(tester, 'Page'), inExclusiveRange(0, 1));
      expect(opacityOf(tester, 'Bar'), lessThan(1));
      expect(
        barMoves(tester).first.transform.getTranslation().y,
        inExclusiveRange(0, BirkaTokens.spaceXl),
      );

      await tester.pumpAndSettle();

      expect(tester.getRect(find.byKey(place)), to);
      expect(find.text('Bar'), findsNothing);
      final route = routeOf(tester, 'Page') as PageRoute<void>;
      expect(route.transitionDuration, BirkaMotion.zoom);
      expect(route.reverseTransitionDuration, BirkaMotion.slow);
    });

    testWidgets('flies the card back as the page closes', (tester) async {
      await tester.pumpWidget(app(const [below], heroes: heroes));
      await tester.pumpWidget(app(const [below, zoom], heroes: heroes));
      await tester.pumpAndSettle();

      await tester.pumpWidget(app(const [below], heroes: heroes));
      await tester.pump();
      await tester.pump(BirkaMotion.slow ~/ 2);

      final flying = tester.getRect(find.byKey(card));
      expect(flying.top, inExclusiveRange(to.top, from.top));
      expect(opacityOf(tester, 'Bar'), inExclusiveRange(0, 1));

      await tester.pumpAndSettle();

      expect(tester.getRect(find.byKey(card)), from);
      expect(opacityOf(tester, 'Bar'), 1);
      expect(find.text('Page'), findsNothing);
    });

    for (final (distance, closes) in [(500.0, true), (100.0, false)]) {
      testWidgets(
        'on iOS a swipe from the edge by $distance plays it backwards and '
        '${closes ? 'closes' : 'keeps'} the page',
        (tester) async {
          final removed = <Page<Object?>>[];
          for (final pages in const [
            [below],
            [below, zoom],
          ]) {
            await tester.pumpWidget(
              app(
                pages,
                platform: TargetPlatform.iOS,
                heroes: heroes,
                onRemoved: removed.add,
              ),
            );
            await tester.pumpAndSettle();
          }

          final gesture = await tester.startGesture(const Offset(5, 400));
          // The first move only starts the swipe.
          await gesture.moveBy(const Offset(kTouchSlop + 1, 0));
          await tester.pump();
          await gesture.moveBy(Offset(distance, 0));
          await tester.pump();

          expect(routeOf(tester, 'Page').animation!.value, lessThan(1));
          final flying = tester.getRect(find.byKey(card));
          expect(flying.top, inExclusiveRange(to.top, from.top));
          expect(find.byKey(place), findsNothing);

          await gesture.up();
          await tester.pumpAndSettle();

          expect(removed.map((page) => page.key), [
            if (closes) const ValueKey('zoom'),
          ]);
        },
      );
    }

    testWidgets('on iOS a touch of the edge leaves the swipe working', (
      tester,
    ) async {
      final removed = <Page<Object?>>[];
      for (final pages in const [
        [below],
        [below, zoom],
      ]) {
        await tester.pumpWidget(
          app(
            pages,
            platform: TargetPlatform.iOS,
            heroes: heroes,
            onRemoved: removed.add,
          ),
        );
        await tester.pumpAndSettle();
      }

      await tester.tapAt(const Offset(5, 400));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(const Offset(5, 400));
      await gesture.moveBy(const Offset(kTouchSlop + 1, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(500, 0));
      await tester.pump();

      expect(
        tester.getRect(find.byKey(card)).top,
        inExclusiveRange(to.top, from.top),
      );

      await gesture.up();
      await tester.pumpAndSettle();

      expect(removed.map((page) => page.key), [const ValueKey('zoom')]);
    });

    for (final closes in [true, false]) {
      testWidgets(
        'on Android the predictive back plays it backwards and '
        '${closes ? 'closes' : 'keeps'} the page',
        (tester) async {
          final removed = <Page<Object?>>[];
          for (final pages in const [
            [below],
            [below, zoom],
          ]) {
            await tester.pumpWidget(
              app(pages, heroes: heroes, onRemoved: removed.add),
            );
            await tester.pumpAndSettle();
          }

          await backGesture(tester, 'startBackGesture', progress: 0);
          await backGesture(
            tester,
            'updateBackGestureProgress',
            progress: 0.5,
          );

          expect(routeOf(tester, 'Page').animation!.value, closeTo(0.5, 0.01));
          expect(
            tester.getRect(find.byKey(card)).top,
            inExclusiveRange(to.top, from.top),
          );

          await backGesture(
            tester,
            closes ? 'commitBackGesture' : 'cancelBackGesture',
          );
          await tester.pumpAndSettle();

          expect(removed.map((page) => page.key), [
            if (closes) const ValueKey('zoom'),
          ]);
        },
      );
    }

    testWidgets('only fades when asked for less motion', (tester) async {
      await tester.pumpWidget(
        app(const [below], heroes: heroes, disableAnimations: true),
      );
      await tester.pumpWidget(
        app(const [below, zoom], heroes: heroes, disableAnimations: true),
      );
      await tester.pump();
      await tester.pump(BirkaMotion.zoom ~/ 2);

      expect(tester.getRect(find.byKey(card)), from);
      expect(tester.getRect(find.byKey(place)), to);
      expect(opacityOf(tester, 'Page'), inExclusiveRange(0, 1));
      expect(barMoves(tester), isEmpty);
    });

    testWidgets('a card flies only into a zoom page', (tester) async {
      const other = ValueKey('other');
      const slides = MaterialPage<void>(
        key: ValueKey('slides'),
        child: Align(
          alignment: Alignment.topLeft,
          child: BirkaZoomSource(
            tag: 'a',
            child: SizedBox(key: other, width: 300, height: 100),
          ),
        ),
      );
      await tester.pumpWidget(
        app(const [below], platform: TargetPlatform.iOS, heroes: heroes),
      );
      await tester.pumpWidget(
        app(
          const [below, slides],
          platform: TargetPlatform.iOS,
          heroes: heroes,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(card), findsOneWidget);
      expect(find.byKey(other), findsOneWidget);

      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(const Offset(5, 400));
      await gesture.moveBy(const Offset(150, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(150, 0));
      await tester.pump();

      expect(find.byKey(card), findsOneWidget);
      expect(find.byKey(other), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the place of a card is just its child on another page', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const [
          MaterialPage(
            key: ValueKey('page'),
            child: BirkaZoomTarget(child: Text('Card')),
          ),
        ], heroes: heroes),
      );

      expect(find.text('Card'), findsOneWidget);
      expect(find.byType(Hero), findsNothing);
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
