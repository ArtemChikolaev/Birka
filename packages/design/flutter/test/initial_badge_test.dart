import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the first letter of a name in capitals', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: Scaffold(
          body: InitialBadge(name: ' маша', color: CardArt.emerald.tint),
        ),
      ),
    );

    expect(find.text('М'), findsOneWidget);
    final tile = tester.widget<Container>(find.byType(Container).last);
    final decoration = tile.decoration! as BoxDecoration;
    expect(
      decoration.color,
      const Color(BirkaTokens.colorPaletteGreen).withValues(alpha: 0.16),
    );
  });

  test('a name without letters gets a question mark', () {
    expect(InitialBadge.letterOf('  '), '?');
    expect(InitialBadge.letterOf('Ира'), 'И');
  });

  test('every art has a bright tint of its own', () {
    final tints = {for (final art in CardArt.values) art.tint};
    expect(tints, hasLength(CardArt.values.length));
    expect(CardArt.graphite.tint, const Color(BirkaTokens.colorPaletteCyan));
  });
}
