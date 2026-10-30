/// Thrown when a token document breaks the DTCG format or the part of it
/// that the generator supports.
final class TokenFormatException implements Exception {
  /// Creates an exception with a [message] that names the token.
  const TokenFormatException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'TokenFormatException: $message';
}

/// The resolved value of a DTCG `typography` token.
final class TypographyValue {
  /// Creates a typography value.
  const TypographyValue({
    required this.families,
    required this.size,
    required this.weight,
    required this.letterSpacing,
    required this.lineHeight,
  });

  /// Font families in fallback order.
  final List<String> families;

  /// Font size in pixels.
  final double size;

  /// Font weight from 1 to 1000.
  final int weight;

  /// Letter spacing in pixels.
  final double letterSpacing;

  /// Line height as a multiple of the font size.
  final double lineHeight;
}

/// A design token with its type and resolved value.
final class DesignToken {
  /// Creates a token.
  const DesignToken({
    required this.path,
    required this.type,
    required this.value,
    this.description,
    this.extensions = const {},
  });

  /// The path from the document root, for example `['color', 'accent']`.
  final List<String> path;

  /// The DTCG type, such as `color` or `dimension`.
  final String type;

  /// The resolved value. Its Dart type follows [type]: `color` is an ARGB
  /// [int], `dimension` and `number` are [double]s, `duration` is an [int]
  /// of milliseconds, `fontFamily` is a `List<String>`, `fontWeight` is an
  /// [int], `cubicBezier` is a `List<double>` and `typography` is a
  /// [TypographyValue].
  final Object value;

  /// The token's `$description`, if it has one.
  final String? description;

  /// Birka's own settings from `$extensions`, such as `uppercase`.
  final Map<String, Object?> extensions;

  /// The path joined with dots, the way aliases refer to the token.
  String get name => path.join('.');
}
