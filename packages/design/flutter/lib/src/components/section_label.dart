import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:flutter/widgets.dart';

/// The heading of a group of content in the label style and in capitals,
/// such as ACCOUNTS above a list of accounts.
///
/// Screen readers get the text as written, since some of them spell a word
/// in capitals letter by letter, and announce it as a heading.
class SectionLabel extends StatelessWidget {
  /// Creates a label that shows [text] in capitals.
  const SectionLabel(this.text, {this.color, super.key});

  /// The label as written, not in capitals.
  final String text;

  /// The color of the label; by default, the color of the surrounding text.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        semanticsLabel: text,
        style: BirkaTextStyles.of(context).label.copyWith(color: color),
      ),
    );
  }
}
