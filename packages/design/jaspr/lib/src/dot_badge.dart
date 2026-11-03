import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A glowing dot of [color] on a faint tile of the same color: the mark of a
/// place to go, such as a tile of Ещё or a way to write to the developer.
class DotBadge extends StatelessComponent {
  /// Creates a badge in [color], a CSS color such as
  /// `var(--color-palette-green)`.
  const DotBadge({required this.color, super.key});

  /// The color of the dot and of its tile.
  final String color;

  @override
  Component build(BuildContext context) {
    return span(
      classes: 'dot-badge',
      styles: Styles(raw: {'--dot-badge-color': color}),
      attributes: const {'aria-hidden': 'true'},
      const [span(classes: 'dot-badge__dot', [])],
    );
  }

  /// The styles of the badge.
  @css
  static List<StyleRule> get styles => [
    // The component sets the color; the accent stands in for a missing one.
    css('.dot-badge').styles(
      raw: {
        '--dot-badge-color': 'var(--color-accent)',
        'align-items': 'center',
        'background':
            'color-mix(in srgb, var(--dot-badge-color) 18%, transparent)',
        'border-radius': 'var(--radius-sm)',
        'display': 'flex',
        'flex': 'none',
        'height': '36px',
        'justify-content': 'center',
        'width': '36px',
      },
    ),
    css('.dot-badge__dot').styles(
      raw: {
        'background': 'var(--dot-badge-color)',
        'border-radius': '50%',
        'box-shadow': '0 0 var(--space-sm) var(--dot-badge-color)',
        'height': 'var(--space-sm)',
        'width': 'var(--space-sm)',
      },
    ),
  ];
}
