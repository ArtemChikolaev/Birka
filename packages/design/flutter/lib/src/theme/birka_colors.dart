import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// The colors of Birka's theme by role, from the design tokens.
@immutable
final class BirkaColors extends ThemeExtension<BirkaColors> {
  /// Creates a set of colors.
  const BirkaColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSelected,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.textSubtle,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.ambient,
    required this.positive,
    required this.negative,
    required this.hairline,
    required this.glassFillTop,
    required this.glassFillBottom,
    required this.glassBorder,
    required this.glassHighlight,
    required this.navFill,
    required this.navHighlight,
    required this.navBubble,
  });

  /// The dark theme: a black base with emerald accents.
  static const BirkaColors dark = BirkaColors(
    background: Color(BirkaTokens.colorBackground),
    surface: Color(BirkaTokens.colorSurface),
    surfaceRaised: Color(BirkaTokens.colorSurfaceRaised),
    surfaceSelected: Color(BirkaTokens.colorSurfaceSelected),
    text: Color(BirkaTokens.colorText),
    textSecondary: Color(BirkaTokens.colorTextSecondary),
    textMuted: Color(BirkaTokens.colorTextMuted),
    textSubtle: Color(BirkaTokens.colorTextSubtle),
    accent: Color(BirkaTokens.colorAccent),
    onAccent: Color(BirkaTokens.colorOnAccent),
    accentSoft: Color(BirkaTokens.colorAccentSoft),
    ambient: Color(BirkaTokens.colorAmbient),
    positive: Color(BirkaTokens.colorPositive),
    negative: Color(BirkaTokens.colorNegative),
    hairline: Color(BirkaTokens.colorHairline),
    glassFillTop: Color(BirkaTokens.colorGlassFillTop),
    glassFillBottom: Color(BirkaTokens.colorGlassFillBottom),
    glassBorder: Color(BirkaTokens.colorGlassBorder),
    glassHighlight: Color(BirkaTokens.colorGlassHighlight),
    navFill: Color(BirkaTokens.colorNavFill),
    navHighlight: Color(BirkaTokens.colorNavHighlight),
    navBubble: Color(BirkaTokens.colorNavBubble),
  );

  /// The colors of the nearest [Theme], or [dark] if it has none.
  static BirkaColors of(BuildContext context) =>
      Theme.of(context).extension<BirkaColors>() ?? dark;

  /// Behind everything on a screen.
  final Color background;

  /// Opaque cards and sheets.
  final Color surface;

  /// A surface on top of another one, such as a menu over a card.
  final Color surfaceRaised;

  /// A selected row or chip.
  final Color surfaceSelected;

  /// Primary text and icons.
  final Color text;

  /// Secondary text, such as a subtitle.
  final Color textSecondary;

  /// Less important text, such as a caption or a hint.
  final Color textMuted;

  /// The quietest text, such as a placeholder.
  final Color textSubtle;

  /// Actions: buttons, links and the selected tab.
  final Color accent;

  /// Text and icons on [accent].
  final Color onAccent;

  /// A light tint of [accent] behind selected items.
  final Color accentSoft;

  /// The glow in the corners of the screen.
  final Color ambient;

  /// A rise or another good change.
  final Color positive;

  /// A fall, an error or another bad change.
  final Color negative;

  /// Thin dividers.
  final Color hairline;

  /// The top of the glass fill, which fades to [glassFillBottom].
  final Color glassFillTop;

  /// The bottom of the glass fill.
  final Color glassFillBottom;

  /// The border of glass.
  final Color glassBorder;

  /// The light line along the top edge of glass.
  final Color glassHighlight;

  /// The fill of the floating navigation bar.
  final Color navFill;

  /// The light line along the top edge of the navigation bar.
  final Color navHighlight;

  /// The bubble behind the selected tab.
  final Color navBubble;

  @override
  BirkaColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSelected,
    Color? text,
    Color? textSecondary,
    Color? textMuted,
    Color? textSubtle,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? ambient,
    Color? positive,
    Color? negative,
    Color? hairline,
    Color? glassFillTop,
    Color? glassFillBottom,
    Color? glassBorder,
    Color? glassHighlight,
    Color? navFill,
    Color? navHighlight,
    Color? navBubble,
  }) {
    return BirkaColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSelected: surfaceSelected ?? this.surfaceSelected,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textSubtle: textSubtle ?? this.textSubtle,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      ambient: ambient ?? this.ambient,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      hairline: hairline ?? this.hairline,
      glassFillTop: glassFillTop ?? this.glassFillTop,
      glassFillBottom: glassFillBottom ?? this.glassFillBottom,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      navFill: navFill ?? this.navFill,
      navHighlight: navHighlight ?? this.navHighlight,
      navBubble: navBubble ?? this.navBubble,
    );
  }

  @override
  BirkaColors lerp(BirkaColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return BirkaColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      surfaceSelected: mix(surfaceSelected, other.surfaceSelected),
      text: mix(text, other.text),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      textSubtle: mix(textSubtle, other.textSubtle),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentSoft: mix(accentSoft, other.accentSoft),
      ambient: mix(ambient, other.ambient),
      positive: mix(positive, other.positive),
      negative: mix(negative, other.negative),
      hairline: mix(hairline, other.hairline),
      glassFillTop: mix(glassFillTop, other.glassFillTop),
      glassFillBottom: mix(glassFillBottom, other.glassFillBottom),
      glassBorder: mix(glassBorder, other.glassBorder),
      glassHighlight: mix(glassHighlight, other.glassHighlight),
      navFill: mix(navFill, other.navFill),
      navHighlight: mix(navHighlight, other.navHighlight),
      navBubble: mix(navBubble, other.navBubble),
    );
  }
}
