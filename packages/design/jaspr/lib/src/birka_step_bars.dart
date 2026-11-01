import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// How far a few steps have come: a bar for each, lit up to the current one.
class BirkaStepBars extends StatelessComponent {
  /// Creates the bars. [current] counts from zero.
  const BirkaStepBars({required this.count, required this.current, super.key});

  /// How many steps there are.
  final int count;

  /// The step on the screen.
  final int current;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'birka-steps',
      attributes: {'role': 'img', 'aria-label': '${current + 1} / $count'},
      [
        for (var step = 0; step < count; step++)
          div(
            classes: step <= current
                ? 'birka-steps__bar birka-steps__bar--lit'
                : 'birka-steps__bar',
            const [],
          ),
      ],
    );
  }

  /// The styles of the bars.
  @css
  static List<StyleRule> get styles => [
    css('.birka-steps').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'gap': 'var(--space-xs)',
        'min-width': '0',
      },
    ),
    css('.birka-steps__bar').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'border-radius': 'var(--radius-pill)',
        'flex': '1',
        'height': '4px',
        'transition': 'background var(--duration-base)',
      },
    ),
    css('.birka-steps__bar--lit').styles(
      raw: {'background': 'var(--color-accent)'},
    ),
  ];
}
