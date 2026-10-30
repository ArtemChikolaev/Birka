/// One layer of a shadow from the design tokens, in terms a kit can use on
/// any platform.
final class ShadowToken {
  /// Creates a layer.
  const ShadowToken({
    required this.color,
    required this.offsetX,
    required this.offsetY,
    required this.blur,
    required this.spread,
  });

  /// The color as ARGB.
  final int color;

  /// The horizontal offset in logical pixels.
  final double offsetX;

  /// The vertical offset in logical pixels.
  final double offsetY;

  /// The blur radius in logical pixels, as in CSS.
  final double blur;

  /// How far the shadow grows beyond the box, in logical pixels.
  final double spread;
}
