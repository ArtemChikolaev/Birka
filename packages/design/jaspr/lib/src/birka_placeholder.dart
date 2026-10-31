import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A quiet block that pulses while its content is on its way.
class BirkaPlaceholder extends StatelessComponent {
  /// Creates a placeholder.
  const BirkaPlaceholder({super.key});

  @override
  Component build(BuildContext context) {
    return const div(classes: 'birka-placeholder', []);
  }

  /// The styles of the placeholder.
  @css
  static List<StyleRule> get styles => [
    css('.birka-placeholder').styles(
      raw: {
        'animation': 'birka-placeholder 1.4s ease-in-out infinite',
        'background': 'var(--color-surface)',
        'border-radius': 'var(--radius-xl)',
        'height': '190px',
      },
    ),
    css.keyframes('birka-placeholder', {
      '50%': const Styles(raw: {'opacity': '0.5'}),
    }),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.birka-placeholder').styles(raw: {'animation': 'none'}),
    ]),
  ];
}
