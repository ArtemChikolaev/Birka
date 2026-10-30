import 'dart:ui' as ui;

import 'package:design_flutter/design_flutter.dart';
import 'package:design_flutter/src/components/glass_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
