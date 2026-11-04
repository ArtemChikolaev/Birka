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
  /// wide screen, as the import has.
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
    css('.page--wide').styles(raw: {'max-width': '1160px'}),
  ];
}
