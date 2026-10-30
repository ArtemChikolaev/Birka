/// A text style from the design tokens, independent of any UI framework.
final class TextToken {
  /// Creates a text style token.
  const TextToken({
    required this.families,
    required this.size,
    required this.weight,
    required this.letterSpacing,
    required this.lineHeight,
    this.uppercase = false,
    this.tabular = false,
  });

  /// Font families in fallback order.
  final List<String> families;

  /// Font size in logical pixels.
  final double size;

  /// Font weight from 1 to 1000.
  final int weight;

  /// Letter spacing in logical pixels.
  final double letterSpacing;

  /// Line height as a multiple of the font size.
  final double lineHeight;

  /// Whether the text is shown in capitals.
  final bool uppercase;

  /// Whether digits use tabular figures, so columns of amounts line up.
  final bool tabular;
}
