import 'dart:convert';

import 'package:birka_mobile/app/app.dart';
import 'package:birka_mobile/app/placeholder_page.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens on the overview', (tester) async {
    await tester.pumpWidget(const BirkaApp());
    await tester.pumpAndSettle();

    // The title of the page and the label of the tab.
    expect(find.text(t.app.overview), findsNWidgets(2));
    expect(find.text(t.app.operations), findsOneWidget);
  });

  testWidgets('dresses the app in the Birka theme', (tester) async {
    await tester.pumpWidget(const BirkaApp());
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(GlassNavBar)));
    expect(theme.extension<BirkaColors>(), same(BirkaColors.dark));
    expect(find.byType(AmbientBackground), findsOneWidget);
  });

  testWidgets('a tab opens its page, and the bar follows', (tester) async {
    await tester.pumpWidget(const BirkaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.reports));
    await tester.pumpAndSettle();

    expect(find.text(t.app.reports), findsNWidgets(2));
    final bar = tester.widget<GlassNavBar>(find.byType(GlassNavBar));
    expect(bar.selectedIndex, 2);
  });

  testWidgets('the action opens quick add, and closing returns', (
    tester,
  ) async {
    await tester.pumpWidget(const BirkaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(t.app.newOperation));
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddPlaceholder), findsOneWidget);
    expect(find.byType(GlassNavBar), findsNothing);

    await tester.tap(find.bySemanticsLabel(t.app.close));
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddPlaceholder), findsNothing);
    expect(find.byType(GlassNavBar), findsOneWidget);
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
