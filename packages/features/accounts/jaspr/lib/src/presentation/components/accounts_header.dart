import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';

/// The buttons over the list of accounts. The host also shows them alone,
/// while the database opens.
class AccountsHeader extends StatelessComponent {
  /// Creates the header.
  const AccountsHeader({
    required this.backHref,
    required this.addHref,
    super.key,
  });

  /// Where the button that goes back leads.
  final String backHref;

  /// Where the button that adds an account leads.
  final String addHref;

  @override
  Component build(BuildContext context) {
    return div(classes: 'accounts-header', [
      GlassIconButton(
        glyph: BirkaGlyph.back,
        label: t.accounts.back,
        href: backHref,
      ),
      GlassIconButton(
        glyph: BirkaGlyph.plus,
        label: t.accounts.add,
        href: addHref,
      ),
    ]);
  }

  /// The styles of the header.
  @css
  static List<StyleRule> get styles => [
    css('.accounts-header').styles(
      raw: {'display': 'flex', 'justify-content': 'space-between'},
    ),
  ];
}
