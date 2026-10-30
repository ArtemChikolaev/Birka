import 'package:birka_web/pages/accounts_island.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The static frame of the accounts page. All that lives is in the island.
class AccountsRoute extends StatelessComponent {
  /// Creates the page.
  const AccountsRoute({super.key});

  @override
  Component build(BuildContext context) {
    return const AmbientBackground(
      child: main_(classes: 'page', [AccountsIsland()]),
    );
  }

  /// The styles of the page.
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
  ];
}
