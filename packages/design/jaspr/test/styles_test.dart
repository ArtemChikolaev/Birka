import 'dart:io';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  test('every CSS variable of the kit is a token or set by the kit', () {
    final tokens = File('../tokens/lib/css/tokens.css').readAsStringSync();
    final css = [
      ...birkaBaseStyles,
      ...AmbientBackground.styles,
      ...AmountText.styles,
      ...BirkaButton.styles,
      ...BirkaChip.styles,
      ...BirkaIcon.styles,
      ...BirkaSwitch.styles,
      ...BirkaTextField.styles,
      ...CardArtSurface.styles,
      ...CardArtThumbnail.styles,
      ...GlassIconButton.styles,
      ...GlassListGroup.styles,
      ...GlassListRow.styles,
      ...GlassSurface.styles,
      ...SectionLabel.styles,
    ].map((rule) => rule.toCss()).join();

    final own = {
      for (final match in RegExp('(--[a-z-]+):').allMatches(css)) match[1],
    };
    final variables = RegExp(r'var\((--[a-z-]+)\)').allMatches(css);
    expect(variables, isNotEmpty);
    for (final variable in variables) {
      if (own.contains(variable[1])) continue;
      expect(tokens, contains('  ${variable[1]}: '));
    }
  });
}
