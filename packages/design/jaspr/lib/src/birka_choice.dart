import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A row of options with a label over it.
class BirkaChoice extends StatelessComponent {
  /// Creates a choice between [children].
  const BirkaChoice({required this.label, required this.children, super.key});

  /// What the choice is about.
  final String label;

  /// The options, which wrap to new lines.
  final List<Component> children;

  @override
  Component build(BuildContext context) {
    return div(classes: 'birka-choice', [
      span(classes: 'text-caption birka-choice__label', [.text(label)]),
      div(classes: 'birka-choice__options', children),
    ]);
  }

  /// The styles of the choice.
  @css
  static List<StyleRule> get styles => [
    css('.birka-choice').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.birka-choice__label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.birka-choice__options').styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': 'var(--space-xs)'},
    ),
  ];
}
