import 'dart:convert';

import 'package:birka_mobile/app/app.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the app name', (tester) async {
    await tester.pumpWidget(const BirkaApp());

    expect(find.text('Birka'), findsOneWidget);
  });

  testWidgets('dresses the app in the Birka theme', (tester) async {
    await tester.pumpWidget(const BirkaApp());

    final theme = Theme.of(tester.element(find.text('Birka')));
    expect(theme.extension<BirkaColors>(), same(BirkaColors.dark));
    expect(find.byType(AmbientBackground), findsOneWidget);
    expect(find.byType(GlassSurface), findsOneWidget);
  });

  test('bundles the fonts of the design system and their licenses', () async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json'))
            as List<Object?>;
    final families = [
      for (final font in manifest.cast<Map<String, Object?>>()) font['family'],
    ];
    expect(
      families,
      containsAll([
        for (final family in bundledFonts) 'packages/$fontPackage/$family',
      ]),
    );

    for (final family in bundledFonts) {
      final license = await rootBundle.loadString(
        'packages/$fontPackage/fonts/$family-OFL.txt',
      );
      expect(license, contains('SIL OPEN FONT LICENSE'));
    }
  });
}
