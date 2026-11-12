import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // One theme, so that the app does not animate into a new one.
  final theme = BirkaTheme.dark();

  Widget chart({
    double start = 29651,
    double pace = 2100,
    bool reduced = false,
    int days = 17,
    int? stepDay,
    double width = 318,
  }) => MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: ForecastChart(
              start: start,
              pace: pace,
              days: days,
              stepDay: stepDay,
              stepAmount: 55051,
              planPace: 1657,
              stepLabel: stepDay == null ? null : '20 ноя · аванс',
              label: 'Деньги кончатся 2 декабря',
              from: 'сегодня',
              to: '5 дек · зарплата',
              usual: 'как обычно',
              planned: 'по плану: 1 744 ₽ в день',
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('names its days and lines, and says what it shows', (
    tester,
  ) async {
    await tester.pumpWidget(chart());

    expect(find.bySemanticsLabel('Деньги кончатся 2 декабря'), findsOneWidget);
    for (final text in [
      'сегодня',
      '5 дек · зарплата',
      'как обычно',
      'по плану: 1 744 ₽ в день',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('moves its lines to new numbers over the time of a roll', (
    tester,
  ) async {
    await tester.pumpWidget(chart());
    await tester.pumpWidget(chart(pace: 1500));

    await tester.pump(BirkaMotion.roll ~/ 2);
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(BirkaMotion.roll);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('moves its lines at once when asked for less motion', (
    tester,
  ) async {
    await tester.pumpWidget(chart(reduced: true));
    await tester.pumpWidget(chart(pace: 1500, reduced: true));
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('names the day of an advance under it, between the ends', (
    tester,
  ) async {
    // The test font draws every letter as wide as it is tall.
    await tester.pumpWidget(
      chart(start: 11600, days: 22, stepDay: 7, width: 800),
    );

    final label = tester.getRect(find.text('20 ноя · аванс'));
    final from = tester.getRect(find.text('сегодня'));
    final to = tester.getRect(find.text('5 дек · зарплата'));
    expect(label.left, greaterThan(from.right));
    expect(label.right, lessThan(to.left));
    final chartLeft = tester.getTopLeft(find.byType(ForecastChart)).dx;
    // The step stands on day 7 of 22: 8 + 784 × 7 / 22 from the left.
    expect(label.center.dx - chartLeft, closeTo(8 + 784 * 7 / 22, 1));
  });

  testWidgets('leaves the name of the advance out when it has no room', (
    tester,
  ) async {
    await tester.pumpWidget(
      chart(start: 11600, days: 22, stepDay: 1, width: 320),
    );

    expect(find.text('20 ноя · аванс'), findsNothing);
    expect(find.text('сегодня'), findsOneWidget);
  });

  testWidgets('has no name of a step without one', (tester) async {
    await tester.pumpWidget(chart());

    expect(find.text('20 ноя · аванс'), findsNothing);
  });
}
