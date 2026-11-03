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

  group('wrapped', () {
    const types = {
      'debit': 'Debit card',
      'cash': 'Cash',
      'credit': 'Credit card',
      'savings': 'Savings',
    };

    Widget wrapped(String selected, {ValueChanged<String>? onChanged}) =>
        MaterialApp(
          theme: BirkaTheme.dark(),
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 260,
              child: ChipSwitch(
                options: types,
                selected: selected,
                onChanged: onChanged,
                wrap: true,
              ),
            ),
          ),
        );

    Rect chipOf(WidgetTester tester, String label) => tester.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(Center)),
    );

    testWidgets('goes on to another line instead of shrinking', (
      tester,
    ) async {
      await tester.pumpWidget(wrapped('debit', onChanged: (_) {}));

      final debit = chipOf(tester, 'Debit card');
      final credit = chipOf(tester, 'Credit card');
      expect(credit.top, greaterThan(debit.bottom));
      expect(credit.left, debit.left);
      expect(tester.getSize(find.byType(ChipSwitch<String>)).width, 260);
    });

    testWidgets('slides its pill to a chip on another line', (tester) async {
      await tester.pumpWidget(wrapped('debit', onChanged: (_) {}));
      final debit = pillOf(tester);
      final savings = chipOf(tester, 'Savings');

      await tester.pumpWidget(wrapped('savings', onChanged: (_) {}));
      await tester.pump(BirkaMotion.spring ~/ 4);

      expect(pillOf(tester).top, inExclusiveRange(debit.top, savings.top));

      await tester.pumpAndSettle();

      expect(pillOf(tester), rectMoreOrLessEquals(savings));
    });

    testWidgets('cannot change without onChanged', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(wrapped('debit'));

      await tester.tap(find.text('Cash'));
      await tester.pumpAndSettle();

      expect(
        pillOf(tester),
        rectMoreOrLessEquals(chipOf(tester, 'Debit card')),
      );
      expect(
        tester.getSemantics(find.text('Cash')),
        containsSemantics(label: 'Cash', isButton: true, isEnabled: false),
      );
      semantics.dispose();
    });
  });
}
