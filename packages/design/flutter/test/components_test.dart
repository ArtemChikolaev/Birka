import 'dart:ui' as ui;

import 'package:design_flutter/design_flutter.dart';
import 'package:design_flutter/src/components/glass_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(
  theme: BirkaTheme.dark(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  const colors = BirkaColors.dark;

  group('GlassSurface', () {
    testWidgets('blurs the backdrop inside its rounded corners', (
      tester,
    ) async {
      await tester.pumpWidget(app(const GlassSurface(child: Text('Inside'))));

      final clip = tester.widget<ClipRRect>(
        find
            .ancestor(of: find.text('Inside'), matching: find.byType(ClipRRect))
            .first,
      );
      expect(
        clip.borderRadius,
        const BorderRadius.all(Radius.circular(BirkaTokens.radiusLg)),
      );
      expect(
        find.ancestor(
          of: find.text('Inside'),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
    });

    test('saturation 1 keeps the colors as they are', () {
      expect(saturationMatrix(1), [
        for (final value in [
          [1, 0, 0, 0, 0],
          [0, 1, 0, 0, 0],
          [0, 0, 1, 0, 0],
          [0, 0, 0, 1, 0],
        ].expand((row) => row))
          closeTo(value, 1e-9),
      ]);
    });

    test('saturation 0 turns every channel into the same gray', () {
      final matrix = saturationMatrix(0);
      for (final row in [0, 5, 10]) {
        expect(matrix.sublist(row, row + 3), [
          closeTo(0.213, 1e-9),
          closeTo(0.715, 1e-9),
          closeTo(0.072, 1e-9),
        ]);
      }
    });
  });

  group('AmbientBackground', () {
    testWidgets('glows in the corner and stays black in the middle', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: const AmbientBackground(child: SizedBox.expand()),
        ),
      );

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final pixels = (await tester.runAsync(() async {
        final image = await boundary.toImage();
        return image.toByteData();
      }))!;
      ui.Color pixel(int x, int y) {
        final i = (y * 390 + x) * 4;
        return ui.Color.fromARGB(
          pixels.getUint8(i + 3),
          pixels.getUint8(i),
          pixels.getUint8(i + 1),
          pixels.getUint8(i + 2),
        );
      }

      final corner = pixel(2, 2);
      expect(corner.g, greaterThan(corner.r));
      expect(pixel(195, 422), colors.background);
    });

    testWidgets('makes the system bars see-through', (tester) async {
      await tester.pumpWidget(
        const AmbientBackground(child: SizedBox.expand()),
      );

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      expect(region.value.statusBarColor, Colors.transparent);
      expect(region.value.systemNavigationBarColor, Colors.transparent);
      expect(region.value.statusBarIconBrightness, Brightness.light);
      expect(region.value.systemNavigationBarIconBrightness, Brightness.light);
    });
  });

  group('AmountText', () {
    testWidgets('takes the color of its tone', (tester) async {
      for (final (tone, color) in [
        (AmountTone.neutral, null),
        (AmountTone.positive, colors.positive),
        (AmountTone.negative, colors.negative),
        (AmountTone.muted, colors.textMuted),
      ]) {
        await tester.pumpWidget(app(AmountText('1 000', tone: tone)));

        expect(tester.widget<Text>(find.text('1 000')).style?.color, color);
      }
    });

    testWidgets('sets digits in tabular figures', (tester) async {
      await tester.pumpWidget(
        app(
          AmountText('1 000', style: BirkaTextStyles.standard.caption),
        ),
      );

      expect(
        tester.widget<Text>(find.text('1 000')).style?.fontFeatures,
        const [FontFeature.tabularFigures()],
      );
    });

    testWidgets('shrinks rather than wraps when it does not fit', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const SizedBox(width: 60, child: AmountText('1 000 000 000 000')),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(FittedBox)).width, 60);
      final text = tester.widget<Text>(find.text('1 000 000 000 000'));
      expect(text.maxLines, 1);
    });
  });

  group('AmountText with a value', () {
    late ValueNotifier<bool> hidden;
    setUp(() => hidden = ValueNotifier(false));
    tearDown(() => hidden.dispose());

    Widget figure(
      String text,
      num value, {
      AmountRise? rise = AmountRise.good,
      bool inSight = true,
      bool reduced = false,
    }) => app(
      HiddenAmounts(
        notifier: hidden,
        child: TickerMode(
          enabled: inSight,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: AmountText(text, value: value, rise: rise),
          ),
        ),
      ),
    );

    Color? colorOf(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style?.color;

    testWidgets('rolls only the digits that change', (tester) async {
      await tester.pumpWidget(figure('49 650 ₽', 4965000));
      await tester.pumpWidget(figure('49 150 ₽', 4915000));
      await tester.pump(BirkaMotion.roll ~/ 2);

      expect(find.text('49 150 ₽'), findsNothing);
      expect(find.text('49 '), findsOneWidget);
      expect(find.text('50 ₽'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('49 150 ₽'), findsOneWidget);
      expect(find.text('49 '), findsNothing);
    });

    for (final (rise, from, to, news) in [
      (AmountRise.good, 4965000, 4915000, colors.negative),
      (AmountRise.good, 4915000, 4965000, colors.positive),
      (AmountRise.bad, 4915000, 4965000, colors.negative),
      (AmountRise.bad, 4965000, 4915000, colors.positive),
    ]) {
      testWidgets('takes the color of the news when a ${rise.name} figure '
          '${to > from ? 'grows' : 'shrinks'}, then its own', (tester) async {
        String label(int value) => '49 ${value ~/ 10000 % 10}50 ₽';
        await tester.pumpWidget(figure(label(from), from, rise: rise));
        await tester.pumpWidget(figure(label(to), to, rise: rise));
        await tester.pump(BirkaMotion.roll ~/ 2);

        expect(colorOf(tester, '49 '), news);

        await tester.pumpAndSettle();

        expect(colorOf(tester, label(to)), isNot(news));
      });
    }

    testWidgets('without a rise it rolls in its own color', (tester) async {
      await tester.pumpWidget(figure('49 650 ₽', 4965000, rise: null));
      await tester.pumpWidget(figure('49 150 ₽', 4915000, rise: null));
      await tester.pump(BirkaMotion.roll ~/ 2);

      expect(find.text('49 '), findsOneWidget);
      expect(colorOf(tester, '49 '), isNot(colors.negative));
    });

    testWidgets('a figure of another shape rolls out as the new one rolls in', (
      tester,
    ) async {
      await tester.pumpWidget(figure('999 ₽', 99900));
      await tester.pumpWidget(figure('1 000 ₽', 100000));
      await tester.pump(BirkaMotion.roll ~/ 2);

      expect(find.text('999 ₽'), findsOneWidget);
      expect(find.text('1 000 ₽'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('999 ₽'), findsNothing);
      expect(find.text('1 000 ₽'), findsOneWidget);
    });

    testWidgets('waits out of sight and rolls once it shows again', (
      tester,
    ) async {
      await tester.pumpWidget(figure('49 650 ₽', 4965000));
      await tester.pumpWidget(figure('49 150 ₽', 4915000, inSight: false));
      await tester.pump(BirkaMotion.roll * 2);

      expect(find.text('49 650 ₽', skipOffstage: false), findsOneWidget);

      await tester.pumpWidget(figure('49 150 ₽', 4915000));
      await tester.pump(BirkaMotion.roll ~/ 2);

      expect(find.text('49 '), findsOneWidget);
      expect(colorOf(tester, '49 '), colors.negative);

      await tester.pumpAndSettle();

      expect(find.text('49 150 ₽'), findsOneWidget);
    });

    for (final (why, from, to, hide) in [
      ('the first time it shows', null, '49 650 ₽', false),
      ('into another currency', '100 ₽', r'$200', false),
      ('while amounts are hidden', '100 ₽', '200 ₽', true),
    ]) {
      testWidgets('just changes $why', (tester) async {
        hidden.value = hide;
        if (from != null) await tester.pumpWidget(figure(from, 10000));
        await tester.pumpWidget(figure(to, 20000));
        await tester.pump(BirkaMotion.roll ~/ 2);

        expect(
          find.text(
            HiddenAmounts.mask(tester.element(find.byType(AmountText)), to),
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('only flashes when the system asks for less motion', (
      tester,
    ) async {
      await tester.pumpWidget(figure('49 650 ₽', 4965000, reduced: true));
      await tester.pumpWidget(figure('49 150 ₽', 4915000, reduced: true));
      await tester.pump(BirkaMotion.roll ~/ 2);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('6'), findsNothing);
      expect(colorOf(tester, '49 '), colors.negative);
    });
  });

  group('SectionLabel', () {
    testWidgets('shows capitals but reads the text as written', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app(const SectionLabel('Accounts')));

      expect(find.text('ACCOUNTS'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(SectionLabel)),
        containsSemantics(label: 'Accounts', isHeader: true),
      );
      semantics.dispose();
    });
  });
}
