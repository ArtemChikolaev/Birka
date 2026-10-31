import 'dart:math';

import 'package:design_jaspr/src/amount_text.dart';
import 'package:design_jaspr/src/hidden_amounts.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A bar of [BirkaBars].
@immutable
final class BirkaBar {
  /// Creates a bar of [value].
  const BirkaBar({
    required this.value,
    required this.amount,
    required this.label,
    this.highlighted = false,
  });

  /// How tall the bar is against the others.
  final double value;

  /// The figure over the bar. It is hidden along with other amounts.
  final String amount;

  /// What stands under the bar, such as a short name of a month.
  final String label;

  /// Whether this is the bar that matters, in emerald.
  final bool highlighted;
}

/// A row of bars with a figure over each and a name under it.
class BirkaBars extends StatelessComponent {
  /// Creates a row of [bars].
  const BirkaBars({required this.bars, super.key});

  /// The bars, from left to right.
  final List<BirkaBar> bars;

  /// The height of the tallest bar in pixels.
  static const double _height = 72;

  /// The height of a bar without a value, so that its place shows.
  static const double _lowest = 6;

  @override
  Component build(BuildContext context) {
    final tallest = bars.map((bar) => bar.value).fold<double>(0, max);
    return div(classes: 'birka-bars', [
      for (final bar in bars)
        div(
          classes: bar.highlighted
              ? 'birka-bars__item birka-bars__item--highlighted'
              : 'birka-bars__item',
          attributes: {
            'aria-label':
                '${bar.label}: ${HiddenAmounts.mask(context, bar.amount)}',
            'role': 'img',
          },
          [
            AmountText(
              bar.amount,
              tone: bar.highlighted ? AmountTone.positive : AmountTone.muted,
              textClass: 'text-caption',
            ),
            div(
              classes: 'birka-bars__bar',
              styles: Styles(raw: {'height': '${_heightOf(bar, tallest)}px'}),
              const [],
            ),
            span(classes: 'text-caption birka-bars__label', [.text(bar.label)]),
          ],
        ),
    ]);
  }

  static double _heightOf(BirkaBar bar, double tallest) {
    final share = tallest > 0 ? bar.value / tallest : 0.0;
    return max(_height * share, _lowest);
  }

  /// The styles of the bars.
  @css
  static List<StyleRule> get styles => [
    css('.birka-bars').styles(
      raw: {
        'align-items': 'flex-end',
        'display': 'flex',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.birka-bars__item').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'min-width': '0',
      },
    ),
    css('.birka-bars__item--highlighted').styles(
      raw: {'color': 'var(--color-text)'},
    ),
    css('.birka-bars__bar').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'border-radius': 'var(--radius-xs)',
        'margin': 'var(--space-xxs) 0 var(--space-xs)',
        'width': '100%',
      },
    ),
    css('.birka-bars__item--highlighted .birka-bars__bar').styles(
      raw: {'background': 'var(--color-accent)'},
    ),
    css('.birka-bars__label').styles(
      raw: {
        'max-width': '100%',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
  ];
}
