import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// An icon in [color] on a faint tile of the same color.
class GlyphBadge extends StatelessComponent {
  /// Creates a badge.
  const GlyphBadge({
    required this.glyph,
    required this.color,
    this.size = 36,
    super.key,
  });

  /// What the badge shows.
  final BirkaGlyph glyph;

  /// The color of the icon and of its tile, as CSS.
  final String color;

  /// The width and the height in pixels.
  final int size;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'glyph-badge',
      styles: Styles(
        raw: {
          'background': 'color-mix(in srgb, $color 16%, transparent)',
          'color': color,
          'height': '${size}px',
          'width': '${size}px',
        },
      ),
      [BirkaIcon(glyph)],
    );
  }

  /// The styles of the badge.
  @css
  static List<StyleRule> get styles => [
    css('.glyph-badge').styles(
      raw: {
        'align-items': 'center',
        'border-radius': 'var(--radius-sm)',
        'display': 'flex',
        'flex': 'none',
        'justify-content': 'center',
      },
    ),
    css('.glyph-badge .birka-icon').styles(
      raw: {'height': '60%', 'width': '60%'},
    ),
  ];
}
