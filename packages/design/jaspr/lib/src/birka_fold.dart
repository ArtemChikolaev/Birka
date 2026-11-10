import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// What opens to its height and closes again as [open] changes, as the
/// answers of the help do: over `duration.base`, fading in once it starts to
/// open and out before it closes; when the system asks for less motion, it
/// only fades. Closed, it stays in the page, out of reach of the keyboard and
/// of screen readers.
///
/// It stands in a column whose rows keep [gap] apart, and takes that gap
/// with it when it closes.
class BirkaFold extends StatelessComponent {
  /// Creates a fold of [children].
  const BirkaFold({
    required this.open,
    required this.children,
    this.gap = 'var(--space-lg)',
    super.key,
  });

  /// Whether the fold is open.
  final bool open;

  /// What opens.
  final List<Component> children;

  /// The gap of the column it stands in, as CSS.
  final String gap;

  @override
  Component build(BuildContext context) {
    return div(
      classes: open ? 'birka-fold birka-fold--open' : 'birka-fold',
      styles: Styles(raw: {'--birka-fold-gap': gap}),
      attributes: open ? null : const {'inert': '', 'aria-hidden': 'true'},
      [
        div(classes: 'birka-fold__inner', [
          div(classes: 'birka-fold__body', children),
        ]),
      ],
    );
  }

  /// The styles of the fold.
  @css
  static List<StyleRule> get styles => [
    css('.birka-fold').styles(
      raw: {
        '--birka-fold-gap': 'var(--space-lg)',
        'display': 'grid',
        'grid-template-rows': '0fr',
        'margin-top': 'calc(-1 * var(--birka-fold-gap))',
        'opacity': '0',
        'transition':
            'grid-template-rows var(--duration-base) var(--easing-standard), '
            'opacity var(--duration-fast) var(--easing-standard)',
      },
    ),
    css('.birka-fold--open').styles(
      raw: {
        'grid-template-rows': '1fr',
        'opacity': '1',
        'transition':
            'grid-template-rows var(--duration-base) var(--easing-standard), '
            'opacity var(--duration-base) var(--easing-fade) 60ms',
      },
    ),
    // The gap lies in the body, which the closed fold hides whole: padding
    // of the fold itself would stay when it closes.
    css('.birka-fold__inner').styles(
      raw: {'min-height': '0', 'overflow': 'hidden'},
    ),
    css('.birka-fold__body').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'padding-top': 'var(--birka-fold-gap)',
      },
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.birka-fold, .birka-fold--open').styles(
        raw: {'transition': 'opacity var(--duration-base) var(--easing-fade)'},
      ),
    ]),
  ];
}
