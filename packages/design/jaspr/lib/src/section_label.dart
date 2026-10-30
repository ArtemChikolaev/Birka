import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The heading of a group of content in the label style, such as ACCOUNTS
/// above a list of accounts.
///
/// CSS sets the capitals, so screen readers get the text as written.
class SectionLabel extends StatelessComponent {
  /// Creates a label that shows [text] in capitals.
  const SectionLabel(this.text, {super.key});

  /// The label as written, not in capitals.
  final String text;

  @override
  Component build(BuildContext context) {
    return h2(classes: 'text-label section-label', [.text(text)]);
  }

  /// The styles of the label.
  @css
  static List<StyleRule> get styles => [
    css('.section-label').styles(raw: {'margin': '0'}),
  ];
}
