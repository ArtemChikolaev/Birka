import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ValueNotifier<int> value;
  late List<(int, int)> heard;

  setUp(() {
    value = ValueNotifier(1);
    heard = [];
  });
  tearDown(() => value.dispose());

  Widget app({bool inSight = true}) => MaterialApp(
    theme: BirkaTheme.dark(),
    home: TickerMode(
      enabled: inSight,
      child: ValueListenableBuilder<int>(
        valueListenable: value,
        builder: (context, now, _) => HeldOutOfSight<int>(
          value: now,
          onShown: (before, now) => heard.add((before, now)),
          builder: (context, shown) => Text('Shows $shown'),
        ),
      ),
    ),
  );

  testWidgets('shows a new value at once while in sight', (tester) async {
    await tester.pumpWidget(app());

    value.value = 2;
    await tester.pump();

    expect(find.text('Shows 2'), findsOneWidget);
    expect(heard, [(1, 2)]);
  });

  testWidgets('keeps its value under a sheet until the sheet has gone', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        CupertinoSheetRoute<void>(builder: (_) => const SizedBox.expand()),
      ),
    );
    await tester.pumpAndSettle();

    // The page below shows at the top of the sheet and keeps ticking.
    value.value = 2;
    await tester.pump();
    expect(find.text('Shows 1'), findsOneWidget);

    navigator.pop();
    await tester.pump();
    await tester.pump(BirkaMotion.slow);
    expect(find.text('Shows 1'), findsOneWidget);
    expect(heard, isEmpty);

    await tester.pumpAndSettle();
    expect(find.text('Shows 2'), findsOneWidget);
    expect(heard, [(1, 2)]);
  });

  testWidgets('keeps its value on a tab out of sight, and gives up a change '
      'that went back', (tester) async {
    await tester.pumpWidget(app(inSight: false));

    value.value = 2;
    await tester.pump();
    value.value = 3;
    await tester.pump();
    expect(find.text('Shows 1', skipOffstage: false), findsOneWidget);

    await tester.pumpWidget(app());
    await tester.pump();
    expect(find.text('Shows 3'), findsOneWidget);
    expect(heard, [(1, 3)]);

    await tester.pumpWidget(app(inSight: false));
    value.value = 4;
    await tester.pump();
    value.value = 3;
    await tester.pump();
    await tester.pumpWidget(app());
    await tester.pump();
    expect(find.text('Shows 3'), findsOneWidget);
    expect(heard, [(1, 3)]);
  });
}
