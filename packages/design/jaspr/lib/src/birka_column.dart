import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The blocks of a page, one under the other.
class BirkaColumn extends StatelessComponent {
  /// Creates a column of [children].
  const BirkaColumn({required this.children, super.key});

  /// The blocks.
  final List<Component> children;

  @override
  Component build(BuildContext context) {
    return div(classes: 'birka-column', children);
  }

  /// The styles of the column.
  @css
  static List<StyleRule> get styles => [
    css('.birka-column').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
  ];
}
