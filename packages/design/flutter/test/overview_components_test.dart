import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(
  theme: BirkaTheme.dark(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('HiddenAmounts', () {
    late ValueNotifier<bool> hidden;

    setUp(() => hidden = ValueNotifier(false));
    tearDown(() => hidden.dispose());

    Widget scope(Widget child) =>
        HiddenAmounts(notifier: hidden, child: app(child));

    testWidgets('a figure shows until the amounts are hidden', (tester) async {
      await tester.pumpWidget(scope(const AmountText('−1 250,50 ₽')));
      expect(find.text('−1 250,50 ₽'), findsOneWidget);

      hidden.value = true;
      await tester.pump();

      expect(find.text('−••• ₽'), findsOneWidget);
    });

    testWidgets('keeps a figure that is being typed', (tester) async {
      hidden.value = true;
      await tester.pumpWidget(
        scope(const AmountText('250 ₽', alwaysShown: true)),
      );

      expect(find.text('250 ₽'), findsOneWidget);
    });

    testWidgets('hides each amount of a line on its own', (tester) async {
      hidden.value = true;
      await tester.pumpWidget(scope(const AmountText(r'+$1,250 · 2 140 €')));

      expect(find.text(r'+$••• · ••• €'), findsOneWidget);
    });

    testWidgets('toggle goes both ways', (tester) async {
      await tester.pumpWidget(
        scope(
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => HiddenAmounts.toggle(context),
              child: const Text('eye'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('eye'));
      expect(hidden.value, isTrue);
      await tester.tap(find.text('eye'));
      expect(hidden.value, isFalse);
    });

    testWidgets('without a scope nothing is hidden', (tester) async {
      await tester.pumpWidget(app(const AmountText('250')));

      expect(find.text('250'), findsOneWidget);
    });
  });

  testWidgets('a round button stays apart from the text beside it', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Row(
          children: [
            const Expanded(child: Text('October')),
            GlassIconButton(
              glyph: BirkaGlyph.eye,
              label: 'Hide',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.bySemanticsLabel('Hide'), findsOneWidget);
  });

  group('AccountCard', () {
    testWidgets('shows the account and reacts to a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        app(
          AccountCard(
            art: CardArt.emerald,
            name: 'Salary',
            subtitle: 'Rubles',
            amount: '₽100',
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.text('SALARY'), findsOneWidget);
      expect(find.text('Rubles'), findsOneWidget);
      expect(tester.getSize(find.byType(AccountCard)).height, 190);

      await tester.tap(find.text('₽100'));
      expect(taps, 1);
    });

    testWidgets('a compact card is lower', (tester) async {
      await tester.pumpWidget(
        app(
          const SizedBox(
            width: 236,
            child: AccountCard(
              art: CardArt.emerald,
              name: 'Salary',
              subtitle: 'Rubles',
              amount: '₽1,284,560.50',
              compact: true,
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(AccountCard)).height,
        AccountCard.compactHeight,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('BirkaLineChart', () {
    Future<void> pump(WidgetTester tester, List<double> values) =>
        tester.pumpWidget(
          app(
            BirkaLineChart(values: values, label: 'The capital'),
          ),
        );

    testWidgets('reads its label', (tester) async {
      await pump(tester, [1, 2, 3]);

      expect(find.bySemanticsLabel('The capital'), findsOneWidget);
      expect(tester.getSize(find.byType(BirkaLineChart)).height, 96);
    });

    for (final (name, values) in [
      ('nothing', <double>[]),
      ('one value', [5.0]),
      ('two values', [1.0, 2.0]),
      ('a line without a change', [3.0, 3.0, 3.0]),
      ('a year of days', [for (var i = 0; i < 366; i++) i * i * 1.0]),
      ('values below zero', [-5.0, -1.0, -3.0]),
    ]) {
      testWidgets('paints $name', (tester) async {
        await pump(tester, values);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('BirkaRing', () {
    Future<void> pump(WidgetTester tester, List<RingSlice> slices) =>
        tester.pumpWidget(app(BirkaRing(slices: slices, label: 'Spending')));

    testWidgets('reads its label and keeps its size', (tester) async {
      await pump(tester, const [RingSlice(1, Color(0xFF00FF00))]);

      expect(find.bySemanticsLabel('Spending'), findsOneWidget);
      expect(tester.getSize(find.byType(BirkaRing)), const Size.square(96));
    });

    for (final (name, slices) in [
      ('nothing', const <RingSlice>[]),
      ('parts of nothing', const [RingSlice(0, Color(0xFF00FF00))]),
      (
        'a part too small for its gap',
        const [
          RingSlice(1000000, Color(0xFF00FF00)),
          RingSlice(1, Color(0xFF0000FF)),
        ],
      ),
    ]) {
      testWidgets('paints $name', (tester) async {
        await pump(tester, slices);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
