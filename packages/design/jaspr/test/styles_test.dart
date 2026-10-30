import 'dart:io';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  test('every CSS variable of the kit is a design token', () {
    final tokens = File('../tokens/lib/css/tokens.css').readAsStringSync();
    final css = [
      ...birkaBaseStyles,
      ...AmbientBackground.styles,
      ...AmountText.styles,
      ...GlassSurface.styles,
      ...SectionLabel.styles,
    ].map((rule) => rule.toCss()).join();

    final variables = RegExp(r'var\((--[a-z-]+)\)').allMatches(css);
    expect(variables, isNotEmpty);
    for (final variable in variables) {
      expect(tokens, contains('  ${variable[1]}: '));
    }
  });
}
