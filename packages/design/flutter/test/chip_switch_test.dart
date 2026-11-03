import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const periods = {'week': 'Week', 'month': 'Month', 'year': 'Year'};

Widget switchOf(
  String selected, {
  ValueChanged<String>? onChanged,
  bool reduced = false,
}) => MaterialApp(
  theme: BirkaTheme.dark(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Align(
      alignment: Alignment.topLeft,
      child: ChipSwitch(
        options: periods,
        selected: selected,
        onChanged: onChanged ?? (_) {},
      ),
    ),
  ),
);

/// Where the white pill stands.
Rect pillOf(WidgetTester tester) =>
    tester.getRect(find.byType(AnimatedPositionedDirectional));

void main() {
  testWidgets('tells which option is tapped and which is picked', (
    tester,
  ) async {
    final tapped = <String>[];
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(switchOf('month', onChanged: tapped.add));

    await tester.tap(find.text('Year'));

    expect(tapped, ['year']);
    expect(
      tester.getSemantics(find.text('Month')),
      containsSemantics(label: 'Month', isButton: true, isSelected: true),
    );
    semantics.dispose();
  });

  testWidgets('slides its pill to the picked chip', (tester) async {
    await tester.pumpWidget(switchOf('week'));
    final week = pillOf(tester);
    final year = tester.getRect(
      find.ancestor(of: find.text('Year'), matching: find.byType(Center)),
    );

    await tester.pumpWidget(switchOf('year'));
    await tester.pump(BirkaMotion.spring ~/ 4);

    expect(pillOf(tester).left, inExclusiveRange(week.left, year.left));

    await tester.pumpAndSettle();

    expect(pillOf(tester).left, moreOrLessEquals(year.left));
    expect(pillOf(tester).width, moreOrLessEquals(year.width));
  });

  testWidgets('moves its pill at once when asked for less motion', (
    tester,
  ) async {
    await tester.pumpWidget(switchOf('week', reduced: true));
    await tester.pumpWidget(switchOf('year', reduced: true));
    await tester.pump();

    final year = tester.getRect(
      find.ancestor(of: find.text('Year'), matching: find.byType(Center)),
    );
    expect(pillOf(tester).left, moreOrLessEquals(year.left));
  });
}
