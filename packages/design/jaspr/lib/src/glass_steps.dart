import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A panel of glass that tells how something works: a [title] over its
/// [points], each with its number, such as the side of an import.
class GlassSteps extends StatelessComponent {
  /// Creates the panel.
  const GlassSteps({required this.title, required this.points, super.key});

  /// What the panel is about.
  final String title;

  /// The points, in their order.
  final List<String> points;

  @override
  Component build(BuildContext context) {
    return div(classes: 'glass glass-steps', [
      span(classes: 'text-label glass-steps__title', [.text(title)]),
      ol(classes: 'glass-steps__list', [
        for (final (index, point) in points.indexed)
          li(classes: 'glass-steps__point', [
            span(classes: 'text-caption glass-steps__number', [
              .text('${index + 1}'),
            ]),
            span(classes: 'text-body glass-steps__text', [.text(point)]),
          ]),
      ]),
    ]);
  }

  /// The styles of the panel.
  @css
  static List<StyleRule> get styles => [
    css('.glass-steps').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
      },
    ),
    css('.glass-steps__title').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.glass-steps__list').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
        'list-style': 'none',
        'margin': '0',
        'padding': '0',
      },
    ),
    css('.glass-steps__point').styles(
      raw: {
        'align-items': 'flex-start',
        'display': 'flex',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.glass-steps__number').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-accent-soft)',
        'border-radius': '50%',
        'color': 'var(--color-accent)',
        'display': 'flex',
        'flex': 'none',
        'font-weight': 'var(--font-weight-bold)',
        'height': '24px',
        'justify-content': 'center',
        'width': '24px',
      },
    ),
    css('.glass-steps__text').styles(raw: {'color': 'var(--color-text)'}),
  ];
}
