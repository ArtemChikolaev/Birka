import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Birka's [ThemeData], built from the design tokens.
///
/// Material widgets get a [ColorScheme] and a [TextTheme] from the tokens;
/// Birka's own widgets read [BirkaColors] and [BirkaTextStyles], which the
/// theme carries as extensions. The theme sets no `fontFamily`: Material
/// would apply it to every style and replace Manrope in the headings.
abstract final class BirkaTheme {
  /// See-through system bars with light icons, so the glow of the background
  /// reaches the edges of the screen.
  static const SystemUiOverlayStyle systemBars = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );

  /// The dark theme: a black base with emerald accents.
  static ThemeData dark() {
    const colors = BirkaColors.dark;
    final styles = BirkaTextStyles.standard;
    final textTheme = _textTheme(styles, colors);
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: colors.accent,
        onPrimary: colors.onAccent,
        secondary: colors.accent,
        onSecondary: colors.onAccent,
        error: colors.negative,
        onError: colors.background,
        surface: colors.surface,
        onSurface: colors.text,
        onSurfaceVariant: colors.textSecondary,
        outline: colors.glassBorder,
        outlineVariant: colors.hairline,
      ),
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.hairline,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [colors, styles],
    );
  }

  /// Maps Birka's styles onto the roles of Material's type scale.
  static TextTheme _textTheme(BirkaTextStyles styles, BirkaColors colors) {
    TextStyle paint(TextStyle style, [Color? color]) =>
        style.copyWith(color: color ?? colors.text);
    return TextTheme(
      displayLarge: paint(styles.display),
      displayMedium: paint(styles.display),
      displaySmall: paint(styles.display),
      headlineLarge: paint(styles.title),
      headlineMedium: paint(styles.title),
      headlineSmall: paint(styles.heading),
      titleLarge: paint(styles.heading),
      titleMedium: paint(styles.bodyStrong),
      titleSmall: paint(styles.bodyStrong),
      bodyLarge: paint(styles.body),
      bodyMedium: paint(styles.body),
      bodySmall: paint(styles.caption, colors.textSecondary),
      labelLarge: paint(styles.bodyStrong),
      labelMedium: paint(styles.label),
      labelSmall: paint(styles.tab),
    );
  }
}
