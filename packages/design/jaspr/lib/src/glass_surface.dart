import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A panel of Liquid Glass. It blurs what lies behind it and makes its
/// colors richer, fills itself with a faint white gradient and has a hairline
/// border with a light line along the top edge.
///
/// Glass needs something behind it to show, such as an `AmbientBackground`.
class GlassSurface extends StatelessComponent {
  /// Creates a glass panel around [child].
  const GlassSurface({required this.child, super.key});

  /// The content of the panel.
  final Component child;

  @override
  Component build(BuildContext context) {
    return div(classes: 'glass', [child]);
  }

  /// The styles of the panel.
  @css
  static List<StyleRule> get styles => [
    css('.glass').styles(
      raw: {
        'box-sizing': 'border-box',
        'padding': 'var(--space-md)',
        'border': '1px solid var(--color-glass-border)',
        'border-radius': 'var(--radius-lg)',
        'background':
            'linear-gradient(160deg, var(--color-glass-fill-top) 0%, '
            'var(--color-glass-fill-bottom) 100%)',
        'box-shadow':
            'inset 0 1px 0 var(--color-glass-highlight), var(--shadow-glass)',
        '-webkit-backdrop-filter':
            'blur(var(--blur-glass)) saturate(var(--saturation-glass))',
        'backdrop-filter':
            'blur(var(--blur-glass)) saturate(var(--saturation-glass))',
      },
    ),
  ];
}
