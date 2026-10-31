import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';

/// The pages that the navigation of the site leads to, in its order.
enum SitePage {
  /// The first screen with data.
  overview,

  /// The list of operations.
  operations,

  /// The list of accounts.
  accounts,

  /// The list of categories.
  categories,
}

/// The navigation of the site, with a new operation in the middle.
class SiteNav extends StatelessComponent {
  /// Creates the navigation of [page].
  const SiteNav({required this.page, super.key});

  /// The page that stands open.
  final SitePage page;

  @override
  Component build(BuildContext context) {
    return GlassNavBar(
      destinations: [
        GlassNavDestination(
          glyph: BirkaGlyph.home,
          label: t.app.overview,
          href: 'overview/',
        ),
        GlassNavDestination(
          glyph: BirkaGlyph.list,
          label: t.app.operations,
          href: 'operations/',
        ),
        GlassNavDestination(
          glyph: BirkaGlyph.wallet,
          label: t.accounts.title,
          href: 'accounts/',
        ),
        GlassNavDestination(
          glyph: BirkaGlyph.more,
          label: t.categories.title,
          href: 'categories/',
        ),
      ],
      selectedIndex: page.index,
      actionLabel: t.app.newOperation,
      actionHref: 'operations/#new',
    );
  }
}
