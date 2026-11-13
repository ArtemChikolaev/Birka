import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A part of a whole on a line: a dot of [color], [title], an optional
/// [note] such as a change or a share, what the part came to as [amount],
/// and under them a bar of the same color, [fraction] of the full width.
/// The lines of a list are parted by a thin line.
class ShareLine extends StatelessComponent {
  /// Creates a line.
  const ShareLine({
    required this.color,
    required this.title,
    required this.amount,
    required this.fraction,
    this.note,
    super.key,
  });

  /// The color of the dot and of the bar, as CSS.
  final String color;

  /// What the part is.
  final String title;

  /// What it came to, as the caller draws it.
  final Component amount;

  /// The length of the bar, from 0 to 1.
  final double fraction;

  /// What stands before the amount, as the caller draws it.
  final Component? note;

  @override
  Component build(BuildContext context) {
    final width = (fraction.clamp(0, 1) * 100).toStringAsFixed(1);
    return div(classes: 'share-line', [
      div(classes: 'share-line__head', [
        span(
          classes: 'share-line__dot',
          styles: Styles(raw: {'background': color}),
          const [],
        ),
        span(classes: 'text-body-strong share-line__name', [.text(title)]),
        ?note,
        span(classes: 'share-line__amount', [amount]),
      ]),
      div(classes: 'share-line__bar', [
        div(
          classes: 'share-line__fill',
          styles: Styles(raw: {'background': color, 'width': '$width%'}),
          const [],
        ),
      ]),
    ]);
  }

  /// The styles of the line.
  @css
  static List<StyleRule> get styles => [
    css('.share-line').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'padding': 'var(--space-md)',
        'position': 'relative',
      },
    ),
    // The thin line between lines, which stops short of the edges.
    css('.share-line + .share-line::before').styles(
      raw: {
        'background': 'var(--color-hairline)',
        'content': '""',
        'height': '1px',
        'left': 'var(--space-md)',
        'position': 'absolute',
        'right': 'var(--space-md)',
        'top': '0',
      },
    ),
    // An amount too long for the line takes its own.
    css('.share-line__head').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xxs) var(--space-xs)',
      },
    ),
    css('.share-line__dot').styles(
      raw: {
        'border-radius': '50%',
        'flex': 'none',
        'height': '10px',
        'width': '10px',
      },
    ),
    css('.share-line__name').styles(
      raw: {
        'flex': '1',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.share-line__amount').styles(
      raw: {'display': 'flex', 'margin-left': 'auto'},
    ),
    css('.share-line__bar').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'border-radius': 'var(--radius-xs)',
        'height': '4px',
        'overflow': 'hidden',
      },
    ),
    css('.share-line__fill').styles(
      raw: {
        'height': '100%',
        'transition': 'width var(--duration-roll) var(--easing-standard)',
      },
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.share-line__fill').styles(raw: {'transition': 'none'}),
    ]),
  ];
}
