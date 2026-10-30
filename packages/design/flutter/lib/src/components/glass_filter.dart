import 'dart:ui' show ColorFilter, ImageFilter;

/// The backdrop filter of glass: a blur by [blur] logical pixels, then a
/// boost of the colors by [saturation], like CSS `blur() saturate()`.
ImageFilter glassFilter({required double blur, required double saturation}) {
  return ImageFilter.compose(
    outer: ColorFilter.matrix(saturationMatrix(saturation)),
    inner: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
  );
}

/// The color matrix of the CSS `saturate()` filter: 1 keeps the colors, 0
/// turns them gray and more than 1 makes them richer.
List<double> saturationMatrix(double amount) {
  // Luminance weights from the Filter Effects specification.
  const r = 0.213;
  const g = 0.715;
  const b = 0.072;
  final s = amount;
  // dart format off
  return [
    r + (1 - r) * s, g - g * s,       b - b * s,       0, 0,
    r - r * s,       g + (1 - g) * s, b - b * s,       0, 0,
    r - r * s,       g - g * s,       b + (1 - b) * s, 0, 0,
    0,               0,               0,               1, 0,
  ];
  // dart format on
}
