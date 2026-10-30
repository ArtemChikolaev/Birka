import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every style in the order of the constructor.
List<TextStyle> stylesOf(BirkaTextStyles s) => [
  s.display,
  s.title,
  s.heading,
  s.amount,
  s.body,
  s.bodyStrong,
  s.caption,
  s.label,
  s.tab,
];

void main() {
  final standard = BirkaTextStyles.standard;

  test('every style puts its weight on the wght axis too', () {
    // Without the axis Flutter thickens the default instance of the font
    // artificially, which is ExtraLight in Manrope.
    for (final style in stylesOf(standard)) {
      final weight = style.fontVariations!.singleWhere((v) => v.axis == 'wght');
      expect(weight.value, style.fontWeight!.value);
    }
  });

  test('a token becomes a style with the bundled fonts', () {
    const token = BirkaTokens.textDisplay;
    final style = textStyleOf(token);

    expect(style.fontFamily, 'packages/design_flutter/Manrope');
    expect(style.fontFamilyFallback, ['packages/design_flutter/Inter']);
    expect(style.fontSize, token.size);
    expect(style.fontWeight, FontWeight.w800);
    expect(style.letterSpacing, token.letterSpacing);
    expect(style.height, token.lineHeight);
    expect(style.leadingDistribution, TextLeadingDistribution.even);
    expect(style.fontFeatures, const [FontFeature.tabularFigures()]);
    expect(style.color, isNull);
  });

  test('Inter follows the font size on its optical size axis', () {
    expect(
      textStyleOf(BirkaTokens.textBody).fontVariations,
      contains(const FontVariation.opticalSize(15)),
    );
    // The axis starts at 14.
    expect(
      textStyleOf(BirkaTokens.textCaption).fontVariations,
      contains(const FontVariation.opticalSize(14)),
    );
  });

  test('a token without a bundled font is rejected', () {
    const token = TextToken(
      families: ['system-ui'],
      size: 12,
      weight: 400,
      letterSpacing: 0,
      lineHeight: 1,
    );

    expect(() => textStyleOf(token), throwsArgumentError);
  });

  test('copyWith and lerp keep every style in its place', () {
    const other = BirkaTextStyles(
      display: TextStyle(fontSize: 1),
      title: TextStyle(fontSize: 2),
      heading: TextStyle(fontSize: 3),
      amount: TextStyle(fontSize: 4),
      body: TextStyle(fontSize: 5),
      bodyStrong: TextStyle(fontSize: 6),
      caption: TextStyle(fontSize: 7),
      label: TextStyle(fontSize: 8),
      tab: TextStyle(fontSize: 9),
    );
    List<double?> sizes(BirkaTextStyles s) => [
      for (final style in stylesOf(s)) style.fontSize,
    ];

    expect(sizes(other.copyWith()), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    expect(sizes(standard.lerp(other, 1)), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    expect(standard.lerp(null, 0.5), same(standard));
  });
}
