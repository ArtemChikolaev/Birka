import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A tab of a [GlassNavBar].
final class GlassNavDestination {
  /// Creates a tab.
  const GlassNavDestination({
    required this.glyph,
    required this.label,
    required this.href,
  });

  /// The icon.
  final BirkaGlyph glyph;

  /// The label.
  final String label;

  /// Where the tab leads.
  final String href;
}

/// A floating pill of glass with tabs and the main action in the middle.
///
/// It keeps its own room at the end of the page, so that the last line can
/// come out from under it. Every tab is a link: a site has pages, not tabs.
class GlassNavBar extends StatelessComponent {
  /// Creates a bar with [destinations] around the action.
  const GlassNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.actionLabel,
    required this.actionHref,
    super.key,
  });

  /// The tabs, half of them on each side of the action.
  final List<GlassNavDestination> destinations;

  /// The selected tab.
  final int selectedIndex;

  /// What the action does, for screen readers.
  final String actionLabel;

  /// Where the action leads.
  final String actionHref;

  @override
  Component build(BuildContext context) {
    final actionSlot = destinations.length ~/ 2;
    return div(classes: 'glass-nav-room', [
      nav(classes: 'glass-nav', [
        for (final (index, destination) in destinations.indexed) ...[
          if (index == actionSlot)
            a(
              classes: 'glass-nav__action',
              href: actionHref,
              attributes: {'aria-label': actionLabel},
              const [BirkaIcon(BirkaGlyph.plus)],
            ),
          a(
            classes: index == selectedIndex
                ? 'glass-nav__tab glass-nav__tab--selected'
                : 'glass-nav__tab',
            href: destination.href,
            attributes: {if (index == selectedIndex) 'aria-current': 'page'},
            [
              BirkaIcon(destination.glyph),
              span(classes: 'text-tab glass-nav__label', [
                .text(destination.label),
              ]),
            ],
          ),
        ],
      ]),
    ]);
  }

  /// The styles of the bar.
  @css
  static List<StyleRule> get styles => [
    css('.glass-nav-room').styles(
      raw: {'height': 'calc(var(--size-nav-bar) + var(--space-xl))'},
    ),
    css('.glass-nav').styles(
      raw: {
        '-webkit-backdrop-filter':
            'blur(var(--blur-nav)) saturate(var(--saturation-nav))',
        'backdrop-filter':
            'blur(var(--blur-nav)) saturate(var(--saturation-nav))',
        'background': 'var(--color-nav-fill)',
        'border': '1px solid var(--color-glass-border)',
        'border-radius': 'calc(var(--size-nav-bar) / 2)',
        'bottom': 'max(var(--space-xl), env(safe-area-inset-bottom))',
        'box-shadow':
            'inset 0 1px 0 var(--color-nav-highlight), '
            'inset 0 -1px 0 var(--color-nav-lowlight), var(--shadow-nav)',
        'box-sizing': 'border-box',
        'display': 'grid',
        'grid-auto-columns': 'minmax(0, 1fr)',
        'grid-auto-flow': 'column',
        'height': 'var(--size-nav-bar)',
        'left': '50%',
        'max-width': '456px',
        'padding': '6px',
        'position': 'fixed',
        'transform': 'translateX(-50%)',
        'width': 'calc(100% - 2 * var(--space-xxl))',
        'z-index': '1',
      },
    ),
    // The narrowest phones need the room for the labels.
    css.media(const MediaQuery.raw('(max-width: 360px)'), [
      css('.glass-nav').styles(
        raw: {'width': 'calc(100% - 2 * var(--space-md))'},
      ),
    ]),
    css('.glass-nav__tab').styles(
      raw: {
        'align-items': 'center',
        'border-radius': 'calc((var(--size-nav-bar) - 12px) / 2)',
        'color': 'var(--color-nav-label)',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': '3px',
        'justify-content': 'center',
        'min-width': '0',
        'text-decoration': 'none',
        'transition': 'color var(--duration-fast)',
      },
    ),
    css('.glass-nav__tab--selected').styles(
      raw: {
        'background': 'var(--color-nav-bubble)',
        'box-shadow':
            'inset 0 1px 0 var(--color-nav-bubble-highlight), '
            'var(--shadow-nav-bubble)',
        'color': 'var(--color-accent)',
      },
    ),
    css('.glass-nav__label').styles(
      raw: {'max-width': '100%', 'overflow': 'hidden', 'white-space': 'nowrap'},
    ),
    css('.glass-nav__action').styles(
      raw: {
        'align-items': 'center',
        'align-self': 'center',
        'background': 'var(--color-accent)',
        'border-radius': '50%',
        'box-shadow':
            'inset 0 1px 0 var(--color-accent-highlight), '
            'var(--shadow-accent-glow)',
        'color': 'var(--color-on-accent)',
        'display': 'flex',
        'height': '50px',
        'justify-content': 'center',
        'justify-self': 'center',
        'width': '50px',
      },
    ),
    css('.glass-nav__action .birka-icon').styles(
      raw: {'height': '24px', 'width': '24px'},
    ),
  ];
}
