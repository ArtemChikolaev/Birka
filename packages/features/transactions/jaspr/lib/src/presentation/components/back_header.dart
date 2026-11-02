import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';

/// The top line of a page that leads back: the way back, what the page is
/// about and what can be done to it.
class BackHeader extends StatelessComponent {
  /// Creates a header that says [label].
  const BackHeader({
    required this.label,
    required this.onBack,
    this.trailing,
    super.key,
  });

  /// What the page is about.
  final String label;

  /// Called by the way back.
  final VoidCallback onBack;

  /// What stands at the other end of the line.
  final Component? trailing;

  @override
  Component build(BuildContext context) {
    return div(classes: 'back-header', [
      GlassIconButton(
        glyph: BirkaGlyph.back,
        label: t.transactions.back,
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
