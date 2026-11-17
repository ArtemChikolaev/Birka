import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A bar of how much of a whole is gone, such as the money of a day or the
/// limit of a category (ADR 0033). It fills up to its end and no further, in
/// [color], and grows from nought as it shows.
class BirkaMeter extends StatelessComponent {
  /// Creates the bar of [value], where 1 is the whole.
  const BirkaMeter({
    required this.value,
    required this.label,
    this.color = 'var(--color-accent)',
    this.height = 8,
    super.key,
  });

  /// How much of the whole is gone: 1 fills the bar, and more stays full.
  final double value;

  /// What the bar says to a screen reader.
  final String label;

  /// The color of what is gone, as a CSS value.
  final String color;

  /// The height in pixels.
  final int height;

  @override
  Component build(BuildContext context) {
    final percent = (value.clamp(0, 1) * 100).toStringAsFixed(1);
    return span(
      classes: 'birka-meter',
      attributes: {
        'role': 'meter',
        'aria-label': label,
        'aria-valuemin': '0',
        'aria-valuemax': '100',
        'aria-valuenow': '${(value * 100).round()}',
      },
      styles: Styles(raw: {'--birka-meter-height': '${height}px'}),
      [
        span(
          classes: 'birka-meter__fill',
          styles: Styles(
            raw: {'width': '$percent%', '--birka-meter-color': color},
          ),
          const [],
        ),
      ],
    );
  }

  /// The styles of the bar.
  @css
  static List<StyleRule> get styles => [
    css('.birka-meter').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'border-radius': 'var(--radius-pill)',
        'display': 'block',
        'height': 'var(--birka-meter-height, 8px)',
        'overflow': 'hidden',
      },
    ),
    css('.birka-meter__fill').styles(
      raw: {
        'animation':
            'birka-meter-grow var(--duration-roll) var(--easing-standard) '
            'both',
        'background': 'var(--birka-meter-color, var(--color-accent))',
        'border-radius': 'inherit',
        'display': 'block',
        'height': '100%',
        'transform-origin': 'left center',
        'transition':
            'width var(--duration-roll) var(--easing-standard), '
            'background var(--duration-slow) var(--easing-fade)',
      },
    ),
    css.keyframes('birka-meter-grow', {
      'from': const Styles(raw: {'transform': 'scaleX(0)'}),
      'to': const Styles(raw: {'transform': 'scaleX(1)'}),
    }),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.birka-meter__fill').styles(
        raw: {'animation': 'none', 'transition': 'none'},
      ),
    ]),
  ];
}
