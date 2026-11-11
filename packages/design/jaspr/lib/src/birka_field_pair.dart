import 'package:design_jaspr/src/birka_split.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Two fields side by side, half the width each, such as a name and an
/// amount; one field alone keeps its half. With [stacksWhenNarrow] a narrow
/// page has them one under the other.
class BirkaFieldPair extends StatelessComponent {
  /// Creates a pair of [children].
  const BirkaFieldPair({
    required this.children,
    this.stacksWhenNarrow = false,
    super.key,
  });

  /// The fields, two at most.
  final List<Component> children;

  /// Whether a narrow page has the fields one under the other.
  final bool stacksWhenNarrow;

  @override
  Component build(BuildContext context) {
    return div(
      classes: stacksWhenNarrow
          ? 'birka-field-pair birka-field-pair--stacks'
          : 'birka-field-pair',
      children,
    );
  }

  /// The styles of the pair.
  @css
  static List<StyleRule> get styles => [
    css('.birka-field-pair').styles(
      raw: {
        'align-items': 'start',
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'repeat(2, minmax(0, 1fr))',
      },
    ),
    css.media(const MediaQuery.raw(narrowScreenQuery), [
      css('.birka-field-pair--stacks').styles(
        raw: {'grid-template-columns': 'minmax(0, 1fr)'},
      ),
    ]),
  ];
}
