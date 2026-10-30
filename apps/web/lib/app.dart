import 'package:birka_web/components/capital_preview.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The page of the site.
///
/// For now it shows what Birka is and one interactive island: features and
/// the router plug in here as they land (ADR 0006, ADR 0008).
class App extends StatelessComponent {
  /// Creates the page.
  const App({super.key});

  /// What Birka is, in one sentence.
  static const tagline =
      'A local-first expense tracker for money across currencies, banks and '
      'countries.';

  @override
  Component build(BuildContext context) {
    return const AmbientBackground(
      child: main_(classes: 'home', [
        GlassSurface(
          child: div(classes: 'home__panel', [
            h1(classes: 'text-display home__name', [.text('Birka')]),
            p(classes: 'home__tagline', [.text(tagline)]),
            CapitalPreview(),
            a(
              classes: 'text-body-strong home__link',
              href: 'https://github.com/ArtemChikolaev/Birka',
              [.text('Source on GitHub')],
            ),
          ]),
        ),
      ]),
    );
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.home').styles(
      raw: {
        'box-sizing': 'border-box',
        'display': 'grid',
        'min-height': '100vh',
        'padding': 'var(--space-md)',
        'place-items': 'center',
      },
    ),
    css('.home__panel').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
        'max-width': '360px',
        'padding': 'var(--space-xs)',
      },
    ),
    css('.home__name').styles(raw: {'margin': '0'}),
    css('.home__tagline').styles(
      raw: {'margin': '0', 'color': 'var(--color-text-secondary)'},
    ),
    css('.home__link').styles(
      raw: {'color': 'var(--color-accent)', 'text-decoration': 'none'},
    ),
  ];
}
