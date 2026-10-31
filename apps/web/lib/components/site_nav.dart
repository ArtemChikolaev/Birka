import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';

/// The tabs of the site, as in the app.
enum SitePage {
  /// The first screen with data.
  overview,

  /// The list of operations.
  operations,

  /// What a month took or brought.
  reports,

  /// Everything else, with the accounts and the categories.
  more,
}

/// The navigation of the site, with a new operation in the middle.
class SiteNav extends StatelessComponent {
  /// Creates the navigation with the tab of [page] selected.
  const SiteNav({required this.page, super.key});

  /// The tab that the open page belongs to.
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
          glyph: BirkaGlyph.reports,
          label: t.app.reports,
          href: 'reports/',
        ),
        GlassNavDestination(
          glyph: BirkaGlyph.more,
          label: t.app.more,
          href: 'more/',
        ),
      ],
      selectedIndex: page.index,
      actionLabel: t.app.newOperation,
      actionHref: 'operations/#new',
    );
  }
}
