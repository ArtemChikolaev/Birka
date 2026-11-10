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
  }) => MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: ForecastChart(
          start: start,
          pace: pace,
          days: 17,
          label: 'Деньги кончатся 2 декабря',
          from: 'сегодня',
          to: '5 дек · зарплата',
          usual: 'как обычно',
          planned: 'по плану: 1 744 ₽ в день',
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
}
