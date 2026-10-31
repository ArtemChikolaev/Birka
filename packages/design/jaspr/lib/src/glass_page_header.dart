import 'package:design_jaspr/src/birka_icon.dart';
import 'package:design_jaspr/src/glass_icon_button.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The two round buttons over a list: the way back and a new item.
class GlassPageHeader extends StatelessComponent {
  /// Creates a header. Screen readers read the labels.
  const GlassPageHeader({
    required this.backHref,
    required this.backLabel,
    required this.addHref,
    required this.addLabel,
    super.key,
  });

  /// Where the button that goes back leads.
  final String backHref;

  /// What the button that goes back does.
  final String backLabel;

  /// Where the button that adds leads.
  final String addHref;

  /// What the button that adds does.
  final String addLabel;

  @override
  Component build(BuildContext context) {
    return div(classes: 'glass-page-header', [
      GlassIconButton(
        glyph: BirkaGlyph.back,
        label: backLabel,
        href: backHref,
      ),
      GlassIconButton(glyph: BirkaGlyph.plus, label: addLabel, href: addHref),
    ]);
  }

  /// The styles of the header.
  @css
  static List<StyleRule> get styles => [
    css('.glass-page-header').styles(
      raw: {'display': 'flex', 'justify-content': 'space-between'},
    ),
  ];
}
