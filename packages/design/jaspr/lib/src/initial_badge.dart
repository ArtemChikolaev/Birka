import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The first letter of [name] in [color] on a faint tile of the same color,
/// such as the person of a debt (ADR 0029), as a `GlyphBadge` shows a glyph.
class InitialBadge extends StatelessComponent {
  /// Creates a badge.
  const InitialBadge({
    required this.name,
    required this.color,
    this.size = 36,
    super.key,
  });

  /// The name whose first letter the badge shows.
  final String name;

  /// The color of the letter and of its tile, as CSS.
  final String color;

  /// The width and the height in pixels.
  final int size;

  /// The first letter of [name], in capitals, or a question mark for a name
  /// with none.
  static String letterOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCodes(trimmed.runes.take(1)).toUpperCase();
  }

  @override
  Component build(BuildContext context) {
    return span(
      classes: 'initial-badge',
      attributes: const {'aria-hidden': 'true'},
      styles: Styles(
        raw: {
          'background': 'color-mix(in srgb, $color 16%, transparent)',
          'border-radius': '${(size * 0.3).round()}px',
          'color': color,
          'font-size': '${(size * 0.42).round()}px',
          'height': '${size}px',
          'width': '${size}px',
        },
      ),
      [.text(letterOf(name))],
    );
  }

  /// The styles of the badge.
  @css
  static List<StyleRule> get styles => [
    css('.initial-badge').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex': 'none',
        'font-family': 'var(--font-family-display)',
        'font-weight': '800',
        'justify-content': 'center',
        'line-height': '1',
        'transition':
            'color var(--duration-fast), background var(--duration-fast)',
      },
    ),
  ];
}
