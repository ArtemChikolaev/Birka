import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A thin line across a card that parts what stands above it from what
/// follows, such as what a month came to from the categories that took the
/// most.
class BirkaRule extends StatelessComponent {
  /// Creates the line.
  const BirkaRule({super.key});

  @override
  Component build(BuildContext context) {
    return const div(classes: 'birka-rule', []);
  }

  /// The styles of the line.
  @css
  static List<StyleRule> get styles => [
    css('.birka-rule').styles(
      raw: {
        'background': 'var(--color-hairline)',
        'flex': 'none',
        'height': '1px',
      },
    ),
  ];
}
