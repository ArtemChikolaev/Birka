import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Birka's backdrop: the background color with a faint glow of the ambient
/// color in the top left and bottom right corners and on the left edge.
///
/// It goes behind a whole page, and glass on top of it picks up the glow.
class AmbientBackground extends StatelessComponent {
  /// Creates the backdrop behind [child].
  const AmbientBackground({required this.child, super.key});

  /// The content in front of the backdrop.
  final Component child;

  @override
  Component build(BuildContext context) {
    return div(classes: 'ambient text-body', [child]);
  }

  /// The styles of the backdrop.
  @css
  static List<StyleRule> get styles => [
    css('.ambient').styles(
      raw: {
        'min-height': '100vh',
        'background':
            'radial-gradient(62% 34% at 0% 0%, '
            'var(--color-ambient) 0%, transparent 74%), '
            'radial-gradient(66% 38% at 100% 100%, '
            'var(--color-ambient) 0%, transparent 74%), '
            'radial-gradient(64% 20% at 0% 72%, '
            'var(--color-ambient) 0%, transparent 72%), '
            'var(--color-background)',
      },
    ),
  ];
}
