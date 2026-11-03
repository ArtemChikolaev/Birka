import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rows of 40 that say their names.
Widget column(
  List<String> rows, {
  bool inSight = true,
  bool reduced = false,
}) => MaterialApp(
  theme: BirkaTheme.dark(),
  home: TickerMode(
    enabled: inSight,
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Align(
        alignment: Alignment.topLeft,
        child: AnimatedColumn(
          children: [
            for (final row in rows)
              SizedBox(key: ValueKey(row), height: 40, child: Text(row)),
          ],
        ),
      ),
    ),
  ),
);

double heightOf(WidgetTester tester, String row) => tester
    .getSize(
      find.ancestor(
        of: find.text(row, skipOffstage: false),
        matching: find.byType(SizeTransition, skipOffstage: false),
      ),
    )
    .height;

double opacityOf(WidgetTester tester, String row) => tester
    .widget<FadeTransition>(
      find
          .ancestor(
            of: find.text(row, skipOffstage: false),
            matching: find.byType(FadeTransition, skipOffstage: false),
          )
          .first,
    )
    .opacity
    .value;

/// Counts how many times a row of [name] was made anew.
class Probe extends StatefulWidget {
  const Probe(this.name, this.made, {super.key});

  final String name;
  final Map<String, int> made;

  @override
  State<Probe> createState() => _ProbeState();
}

class _ProbeState extends State<Probe> {
  @override
  void initState() {
    super.initState();
    widget.made.update(widget.name, (n) => n + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 40, child: Text(widget.name));
}

void main() {
  testWidgets('opens a row that comes', (tester) async {
    await tester.pumpWidget(column(['a']));
    await tester.pumpWidget(column(['a', 'b']));
    await tester.pump(BirkaMotion.slow ~/ 2);

    expect(heightOf(tester, 'b'), inExclusiveRange(0, 40));

    await tester.pumpAndSettle();

    expect(heightOf(tester, 'b'), 40);
  });

  testWidgets('closes a row that goes, after the row it followed', (
    tester,
  ) async {
    await tester.pumpWidget(column(['a', 'b', 'c']));
    await tester.pumpWidget(column(['a', 'c']));
    await tester.pump(BirkaMotion.slow ~/ 2);

    expect(heightOf(tester, 'b'), inExclusiveRange(0, 40));
    final top = tester.getTopLeft(find.text('b')).dy;
    expect(top, greaterThan(tester.getTopLeft(find.text('a')).dy));
    expect(top, lessThan(tester.getTopLeft(find.text('c')).dy));

    await tester.pumpAndSettle();

    expect(find.text('b'), findsNothing);
    expect(heightOf(tester, 'c'), 40);
  });

  testWidgets('stands still the first time it shows', (tester) async {
    await tester.pumpWidget(column(['a', 'b']));

    expect(heightOf(tester, 'a'), 40);
    expect(heightOf(tester, 'b'), 40);
  });

  testWidgets('only fades a row in when asked for less motion', (
    tester,
  ) async {
    await tester.pumpWidget(column(['a'], reduced: true));
    await tester.pumpWidget(column(['a', 'b'], reduced: true));

    expect(heightOf(tester, 'b'), 40);
    await tester.pump(BirkaMotion.base ~/ 2);
    expect(opacityOf(tester, 'b'), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(opacityOf(tester, 'b'), 1);

    await tester.pumpWidget(column(['a'], reduced: true));

    expect(find.text('b'), findsNothing);
  });

  testWidgets('opens a row that came out of sight once it shows', (
    tester,
  ) async {
    await tester.pumpWidget(column(['a'], inSight: false));
    await tester.pumpWidget(column(['a', 'b'], inSight: false));
    await tester.pump(BirkaMotion.slow);

    expect(heightOf(tester, 'b'), 0);

    await tester.pumpWidget(column(['a', 'b']));
    await tester.pump(BirkaMotion.slow ~/ 2);

    expect(heightOf(tester, 'b'), inExclusiveRange(0, 40));

    await tester.pumpAndSettle();

    expect(heightOf(tester, 'b'), 40);
  });

  testWidgets('opens a row that came under a sheet once the sheet has gone', (
    tester,
  ) async {
    final rows = ValueNotifier(['a']);
    addTearDown(rows.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: Align(
          alignment: Alignment.topLeft,
          child: ValueListenableBuilder(
            valueListenable: rows,
            builder: (context, rows, _) => AnimatedColumn(
              children: [
                for (final row in rows)
                  SizedBox(key: ValueKey(row), height: 40, child: Text(row)),
              ],
            ),
          ),
        ),
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        CupertinoSheetRoute<void>(builder: (_) => const SizedBox.expand()),
      ),
    );
    await tester.pumpAndSettle();

    // The page below shows at the top of the sheet and keeps ticking.
    rows.value = ['a', 'b'];
    await tester.pump();
    await tester.pump(BirkaMotion.slow);

    expect(heightOf(tester, 'b'), 0);

    navigator.pop();
    await tester.pump();
    await tester.pump(BirkaMotion.slow);

    expect(heightOf(tester, 'b'), 0);

    await tester.pumpAndSettle();

    expect(heightOf(tester, 'b'), 40);
  });

  group('in a sliver', () {
    Widget sliver(List<String> rows, Map<String, int> made) => MaterialApp(
      theme: BirkaTheme.dark(),
      home: CustomScrollView(
        slivers: [
          SliverAnimatedColumn(
            children: [
              for (final row in rows) Probe(row, made, key: ValueKey(row)),
            ],
          ),
        ],
      ),
    );

    testWidgets('opens a row that comes and closes one that goes', (
      tester,
    ) async {
      final made = <String, int>{};
      await tester.pumpWidget(sliver(['b'], made));
      await tester.pumpWidget(sliver(['a', 'b'], made));
      await tester.pump(BirkaMotion.slow ~/ 2);

      expect(heightOf(tester, 'a'), inExclusiveRange(0, 40));

      await tester.pumpAndSettle();
      expect(heightOf(tester, 'a'), 40);

      await tester.pumpWidget(sliver(['b'], made));
      await tester.pump(BirkaMotion.slow ~/ 2);

      expect(heightOf(tester, 'a'), inExclusiveRange(0, 40));

      await tester.pumpAndSettle();
      expect(find.text('a'), findsNothing);
    });

    testWidgets('keeps a row as it is when another comes before it', (
      tester,
    ) async {
      final made = <String, int>{};
      await tester.pumpWidget(sliver(['b', 'c'], made));
      await tester.pumpWidget(sliver(['a', 'b', 'c'], made));
      await tester.pumpAndSettle();

      expect(made, {'a': 1, 'b': 1, 'c': 1});
    });
  });
}
