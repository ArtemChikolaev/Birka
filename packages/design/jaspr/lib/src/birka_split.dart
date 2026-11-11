import 'package:jaspr/dom.dart';
// The field `aside` of the component hides the element of the same name.
import 'package:jaspr/dom.dart' as dom show aside;
import 'package:jaspr/jaspr.dart';

/// The media query of a wide window, 901 px or more, where a page lays out
/// side by side.
const wideScreenQuery = '(min-width: 901px)';

/// The media query of a narrow window, 900 px or less, where a page is one
/// column.
const narrowScreenQuery = '(max-width: 900px)';

/// The wide layout of a page: [main] and, beside it, [aside], which stays in
/// sight as the page scrolls, such as the steps of an import and what they
/// mean. With [halves] the two take half the width each, as the parts of
/// the reports do. On a screen of 900 px or less the side goes under the
/// main column, or away when [asideWhenNarrow] is false.
///
/// It stands in a page of `PageFrame(wide: true)`, 1160 px across.
class BirkaSplit extends StatelessComponent {
  /// Creates the layout.
  const BirkaSplit({
    required this.main,
    required this.aside,
    this.asideWidth = 300,
    this.halves = false,
    this.asideWhenNarrow = true,
    super.key,
  });

  /// What the page is about.
  final List<Component> main;

  /// What stands beside it.
  final List<Component> aside;

  /// How wide the side is, in pixels; [halves] takes no width of its own.
  final int asideWidth;

  /// Whether both columns take half the width.
  final bool halves;

  /// Whether the side stays under the main column on a narrow screen. A side
  /// that only helps a wide page goes away there.
  final bool asideWhenNarrow;

  @override
  Component build(BuildContext context) {
    return div(
      classes: [
        'birka-split',
        if (halves) 'birka-split--halves',
        if (!asideWhenNarrow) 'birka-split--wide-aside',
      ].join(' '),
      styles: halves
          ? null
          : Styles(raw: {'--birka-split-aside': '${asideWidth}px'}),
      [
        div(classes: 'birka-split__main', main),
        if (halves)
          div(classes: 'birka-split__main', aside)
        else
          dom.aside(classes: 'birka-split__aside', aside),
      ],
    );
  }

  /// The styles of the layout.
  @css
  static List<StyleRule> get styles => [
    css('.birka-split').styles(
      raw: {
        'align-items': 'start',
        'display': 'grid',
        'gap': 'var(--space-xl)',
        'grid-template-columns':
            'minmax(0, 1fr) var(--birka-split-aside, 300px)',
      },
    ),
    css('.birka-split--halves').styles(
      raw: {'grid-template-columns': 'repeat(2, minmax(0, 1fr))'},
    ),
    css('.birka-split__main').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
        'min-width': '0',
      },
    ),
    // The side follows the page down, so that its buttons stay in reach.
    css('.birka-split__aside').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
        'min-width': '0',
        'position': 'sticky',
        'top': 'var(--space-lg)',
      },
    ),
    // What only a wide page or only a narrow one shows, such as the same card
    // that stands at the side of one and on top of the other.
    css.media(const MediaQuery.raw(wideScreenQuery), [
      css('.birka-narrow-only').styles(raw: {'display': 'none'}),
    ]),
    css.media(const MediaQuery.raw(narrowScreenQuery), [
      css('.birka-wide-only').styles(raw: {'display': 'none'}),
      css('.birka-split, .birka-split--halves').styles(
        raw: {'grid-template-columns': 'minmax(0, 1fr)'},
      ),
      css('.birka-split__aside').styles(raw: {'position': 'static'}),
      css('.birka-split--wide-aside > .birka-split__aside').styles(
        raw: {'display': 'none'},
      ),
    ]),
  ];
}
