import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The static frame of a page of the app, around its island.
class PageFrame extends StatelessComponent {
  /// Creates a frame around [child].
  const PageFrame({required this.child, this.wide = false, super.key});

  /// All that lives on the page.
  final Component child;

  /// Whether the page has a side of its own beside its main column on a
  /// wide screen, as the import has. On a narrow one it keeps the column of
  /// the other pages.
  final bool wide;

  @override
  Component build(BuildContext context) {
    return AmbientBackground(
      child: main_(classes: wide ? 'page page--wide' : 'page', [child]),
    );
  }

  /// The styles of the frame.
  @css
  static List<StyleRule> get styles => [
    css('.page').styles(
      raw: {
        'box-sizing': 'border-box',
        'margin': '0 auto',
        'max-width': '520px',
        // The page runs under the bars of a phone, as the glow does.
        'padding':
            'max(var(--space-md), env(safe-area-inset-top)) var(--space-lg) '
            'max(var(--space-xxl), env(safe-area-inset-bottom))',
      },
    ),
    css.media(const MediaQuery.raw(wideScreenQuery), [
      css('.page--wide').styles(raw: {'max-width': '1160px'}),
    ]),
    css('.page__column').styles(
      raw: {
        'margin': '0 auto',
        'max-width': 'calc(520px - 2 * var(--space-lg))',
      },
    ),
  ];
}

/// A view without a wide layout of its own on a wide page, such as the card
/// of an operation over the page of an account: it keeps the column of a
/// narrow page in the middle.
class PageColumn extends StatelessComponent {
  /// Creates the column around [child].
  const PageColumn({required this.child, super.key});

  /// The view.
  final Component child;

  @override
  Component build(BuildContext context) {
    return div(classes: 'page__column', [child]);
  }
}
