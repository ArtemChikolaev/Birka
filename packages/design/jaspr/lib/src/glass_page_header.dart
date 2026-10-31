import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The heading of a page, with what stands beside it, such as the button that
/// adds.
class GlassPageHeader extends StatelessComponent {
  /// Creates a header.
  const GlassPageHeader({required this.title, this.trailing, super.key});

  /// The heading.
  final String title;

  /// What stands at the other end of the line.
  final Component? trailing;

  @override
  Component build(BuildContext context) {
    return div(classes: 'glass-page-header', [
      h1(classes: 'text-title glass-page-header__title', [.text(title)]),
      ?trailing,
    ]);
  }

  /// The styles of the header.
  @css
  static List<StyleRule> get styles => [
    css('.glass-page-header').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-xs)',
        'justify-content': 'space-between',
        'min-height': 'var(--size-touch-target)',
      },
    ),
    css('.glass-page-header__title').styles(
      raw: {'margin': '0', 'min-width': '0'},
    ),
  ];
}
