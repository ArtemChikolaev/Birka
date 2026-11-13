import 'package:design_jaspr/src/birka_icon.dart';
import 'package:design_jaspr/src/glass_icon_button.dart';
import 'package:design_jaspr/src/section_label.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The top line of a page that leads back: the way back, what the page is
/// about and what can be done to it. Beside a list on a wide page the way back
/// [closes] the card, a cross.
class BackHeader extends StatelessComponent {
  /// Creates a header that says [label].
  const BackHeader({
    required this.label,
    required this.backLabel,
    required this.onBack,
    this.trailing,
    this.closes = false,
    super.key,
  });

  /// What the page is about.
  final String label;

  /// What the way back does, for screen readers: back, or close for a cross.
  final String backLabel;

  /// Called by the way back.
  final VoidCallback onBack;

  /// What stands at the other end of the line.
  final Component? trailing;

  /// Whether the way back closes the card, a cross, rather than an arrow.
  final bool closes;

  @override
  Component build(BuildContext context) {
    return div(classes: 'back-header', [
      GlassIconButton(
        glyph: closes ? BirkaGlyph.close : BirkaGlyph.back,
        label: backLabel,
        onPressed: onBack,
      ),
      SectionLabel(label),
      div(classes: 'back-header__end', [?trailing]),
    ]);
  }

  /// The styles of the header.
  @css
  static List<StyleRule> get styles => [
    css('.back-header').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-muted)',
        'display': 'grid',
        'gap': 'var(--space-xs)',
        'grid-template-columns': '1fr auto 1fr',
      },
    ),
    css('.back-header__end').styles(
      raw: {'display': 'flex', 'justify-content': 'flex-end'},
    ),
  ];
}
