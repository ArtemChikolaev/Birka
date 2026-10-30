import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every color in the order of the constructor.
List<Color> colorsOf(BirkaColors c) => [
  c.background,
  c.surface,
  c.surfaceRaised,
  c.surfaceSelected,
  c.text,
  c.textSecondary,
  c.textMuted,
  c.textSubtle,
  c.accent,
  c.onAccent,
  c.accentSoft,
  c.accentHighlight,
  c.ambient,
  c.positive,
  c.negative,
  c.hairline,
  c.glassFillTop,
  c.glassFillBottom,
  c.glassBorder,
  c.glassHighlight,
  c.navFill,
  c.navHighlight,
  c.navLowlight,
  c.navBubble,
  c.navBubbleHighlight,
  c.navLabel,
];

/// Colors that differ from each other, so that a field mixed up with another
/// one shows.
BirkaColors numbered() {
  var n = 0;
  Color next() => Color(0xFF000000 + ++n);
  return BirkaColors(
    background: next(),
    surface: next(),
    surfaceRaised: next(),
    surfaceSelected: next(),
    text: next(),
    textSecondary: next(),
    textMuted: next(),
    textSubtle: next(),
    accent: next(),
    onAccent: next(),
    accentSoft: next(),
    accentHighlight: next(),
    ambient: next(),
    positive: next(),
    negative: next(),
    hairline: next(),
    glassFillTop: next(),
    glassFillBottom: next(),
    glassBorder: next(),
    glassHighlight: next(),
    navFill: next(),
    navHighlight: next(),
    navLowlight: next(),
    navBubble: next(),
    navBubbleHighlight: next(),
    navLabel: next(),
  );
}

void main() {
  const dark = BirkaColors.dark;
  final other = numbered();

  test('the dark colors come from the tokens', () {
    expect(dark.accent, const Color(BirkaTokens.colorAccent));
    expect(dark.glassBorder, const Color(BirkaTokens.colorGlassBorder));
  });

  test('copyWith keeps every color it is not given', () {
    expect(colorsOf(other.copyWith()), colorsOf(other));
    expect(
      other.copyWith(accent: dark.accent).accent,
      dark.accent,
    );
  });

  test('lerp moves every color to its own counterpart', () {
    expect(colorsOf(dark.lerp(other, 0)), colorsOf(dark));
    expect(colorsOf(dark.lerp(other, 1)), colorsOf(other));
    expect(
      dark.lerp(other, 0.5).accent,
      Color.lerp(dark.accent, other.accent, 0.5),
    );
    expect(dark.lerp(null, 0.5), same(dark));
  });
}
