import 'package:design_flutter/src/fonts.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// Birka's text styles by name, from the design tokens.
///
/// The styles leave the color out: text takes it from the surrounding
/// [DefaultTextStyle] unless a widget sets one.
@immutable
final class BirkaTextStyles extends ThemeExtension<BirkaTextStyles> {
  /// Creates the text styles.
  const BirkaTextStyles({
    required this.display,
    required this.title,
    required this.heading,
    required this.amount,
    required this.body,
    required this.bodyStrong,
    required this.caption,
    required this.label,
    required this.tab,
  });

  /// The styles of the design tokens.
  static final BirkaTextStyles standard = BirkaTextStyles(
    display: textStyleOf(BirkaTokens.textDisplay),
    title: textStyleOf(BirkaTokens.textTitle),
    heading: textStyleOf(BirkaTokens.textHeading),
    amount: textStyleOf(BirkaTokens.textAmount),
    body: textStyleOf(BirkaTokens.textBody),
    bodyStrong: textStyleOf(BirkaTokens.textBodyStrong),
    caption: textStyleOf(BirkaTokens.textCaption),
    label: textStyleOf(BirkaTokens.textLabel),
    tab: textStyleOf(BirkaTokens.textTab),
  );

  /// The text styles of the nearest [Theme], or [standard] if it has none.
  static BirkaTextStyles of(BuildContext context) =>
      Theme.of(context).extension<BirkaTextStyles>() ?? standard;

  /// Headlines and large amounts, such as a total.
  final TextStyle display;

  /// Screen titles.
  final TextStyle title;

  /// Headings of sections and cards.
  final TextStyle heading;

  /// Amounts in cards and lists.
  final TextStyle amount;

  /// Running text.
  final TextStyle body;

  /// Running text with emphasis, such as the title of a list item.
  final TextStyle bodyStrong;

  /// Secondary lines and hints.
  final TextStyle caption;

  /// Short section labels, meant to be in capitals: the `SectionLabel`
  /// widget takes care of that.
  final TextStyle label;

  /// Labels in the navigation bar.
  final TextStyle tab;

  @override
  BirkaTextStyles copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? heading,
    TextStyle? amount,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? caption,
    TextStyle? label,
    TextStyle? tab,
  }) {
    return BirkaTextStyles(
      display: display ?? this.display,
      title: title ?? this.title,
      heading: heading ?? this.heading,
      amount: amount ?? this.amount,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      caption: caption ?? this.caption,
      label: label ?? this.label,
      tab: tab ?? this.tab,
    );
  }

  @override
  BirkaTextStyles lerp(BirkaTextStyles? other, double t) {
    if (other == null) return this;
    return BirkaTextStyles(
      display: TextStyle.lerp(display, other.display, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      heading: TextStyle.lerp(heading, other.heading, t)!,
      amount: TextStyle.lerp(amount, other.amount, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyStrong: TextStyle.lerp(bodyStrong, other.bodyStrong, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      tab: TextStyle.lerp(tab, other.tab, t)!,
    );
  }
}

/// Converts a text token into a [TextStyle] with the bundled fonts.
///
/// The weight goes both to [TextStyle.fontWeight] and to the `wght` axis of
/// the variable font. With the weight alone, Flutter keeps the default
/// instance of the font and thickens it artificially, and the default of
/// Manrope is ExtraLight. Inter also gets its optical size, which browsers
/// follow from the font size on their own. Leading is even, as in CSS.
TextStyle textStyleOf(TextToken token) {
  final families = [
    for (final family in token.families)
      if (bundledFonts.contains(family)) family,
  ];
  if (families.isEmpty) {
    throw ArgumentError.value(
      token.families,
      'token',
      'names none of the bundled fonts $bundledFonts',
    );
  }
  return TextStyle(
    fontFamily: families.first,
    fontFamilyFallback: families.length > 1 ? families.sublist(1) : null,
    package: fontPackage,
    fontSize: token.size,
    fontWeight: _fontWeight(token.weight),
    fontVariations: [
      FontVariation.weight(token.weight.toDouble()),
      // Inter's optical size axis runs from 14 to 32.
      if (families.first == 'Inter')
        FontVariation.opticalSize(token.size.clamp(14, 32).toDouble()),
    ],
    letterSpacing: token.letterSpacing,
    height: token.lineHeight,
    leadingDistribution: TextLeadingDistribution.even,
    fontFeatures: token.tabular ? const [FontFeature.tabularFigures()] : null,
  );
}

FontWeight _fontWeight(int weight) =>
    FontWeight.values[(weight / 100).round().clamp(1, 9) - 1];
