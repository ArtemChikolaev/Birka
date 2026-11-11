import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The way on at the end of a card: [label] in the accent at the start of a
/// line and a chevron at its end, such as «Все регулярные · 3» or «Отчёт за
/// октябрь».
class BirkaLinkRow extends StatelessComponent {
  /// Creates a line that leads to [href].
  const BirkaLinkRow({required this.label, required this.href, super.key});

  /// What the line says.
  final String label;

  /// Where it leads.
  final String href;

  @override
  Component build(BuildContext context) {
    return a(classes: 'text-body-strong birka-link-row', href: href, [
      span([.text(label)]),
      const BirkaIcon(BirkaGlyph.chevron),
    ]);
  }

  /// The styles of the line.
  @css
  static List<StyleRule> get styles => [
    css('.birka-link-row').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-accent)',
        'display': 'flex',
        'gap': 'var(--space-xs)',
        'justify-content': 'space-between',
        'min-height': 'var(--size-touch-target)',
        'text-decoration': 'none',
      },
    ),
    css('.birka-link-row .birka-icon').styles(
      raw: {'flex': 'none', 'height': '16px', 'width': '16px'},
    ),
  ];
}
