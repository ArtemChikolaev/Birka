import 'dart:io';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  test('every CSS variable of the kit is a token or set by the kit', () {
    final tokens = File('../tokens/lib/css/tokens.css').readAsStringSync();
    final css = [
      ...birkaBaseStyles,
      ...AccountCard.styles,
      ...AmbientBackground.styles,
      ...AmountText.styles,
      ...BirkaArrowButton.styles,
      ...BirkaBars.styles,
      ...BirkaButton.styles,
      ...BirkaCheckbox.styles,
      ...BirkaChip.styles,
      ...BirkaChipField.styles,
      ...BirkaChoice.styles,
      ...BirkaColumn.styles,
      ...BirkaDateChip.styles,
      ...BirkaForm.styles,
      ...BirkaIcon.styles,
      ...BirkaLineChart.styles,
      ...BirkaPlaceholder.styles,
      ...BirkaRing.styles,
      ...BirkaSelect.styles,
      ...BirkaSplit.styles,
      ...BirkaStepBars.styles,
      ...BirkaSwitch.styles,
      ...BirkaTextField.styles,
      ...CardArtSurface.styles,
      ...CardArtThumbnail.styles,
      ...DotBadge.styles,
      ...FileDropZone.styles,
      ...GlassIconButton.styles,
      ...GlassKeypad.styles,
      ...GlassListGroup.styles,
      ...GlassListRow.styles,
      ...GlassNavBar.styles,
      ...GlassNotice.styles,
      ...GlassOption.styles,
      ...GlassPageHeader.styles,
      ...GlassSearchField.styles,
      ...GlassSegmented.styles,
      ...GlassSteps.styles,
      ...GlassStepPills.styles,
      ...GlassSurface.styles,
      ...GlassToast.styles,
      ...GlyphBadge.styles,
      ...SectionLabel.styles,
      ...TintedBox.styles,
      ...TintedNotice.styles,
      ...WelcomeArt.styles,
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
