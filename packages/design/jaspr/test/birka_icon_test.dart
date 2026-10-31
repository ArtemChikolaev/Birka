import 'dart:io';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  test('every glyph holds the file of the Flutter kit', () {
    final files = Directory('../flutter/icons').listSync().whereType<File>();

    expect(
      {for (final glyph in BirkaGlyph.values) glyph.name: glyph.svg},
      {
        for (final file in files)
          file.uri.pathSegments.last.replaceAll('.svg', ''): file
              .readAsStringSync()
              .trim(),
      },
    );
  });

  test('a glyph comes by its name, and an unknown name gets a neutral one', () {
    expect(BirkaGlyph.named('cart'), BirkaGlyph.cart);
    expect(BirkaGlyph.named('from-a-newer-version'), BirkaGlyph.more);
    expect(BirkaGlyph.named(null), BirkaGlyph.more);
  });

  testComponents('BirkaIcon is hidden from screen readers', (tester) async {
    tester.pumpComponent(const BirkaIcon(BirkaGlyph.back));

    final icon = find.tag('span').evaluate().single.component as DomComponent;
    expect(icon.attributes?['aria-hidden'], 'true');
    expect(find.byType(RawText), findsOneComponent);
  });
}
