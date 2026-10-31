import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';

/// A figure with a line of its own, which takes a smaller style when it is too
/// long for the width of a phone.
class BigAmount extends StatelessComponent {
  /// Creates a figure.
  const BigAmount(this.text, {this.tone = AmountTone.neutral, super.key});

  /// The formatted figure.
  final String text;

  /// The color of the figure.
  final AmountTone tone;

  /// The most characters that the big style fits on the narrowest phone.
  static const _longest = 11;

  @override
  Component build(BuildContext context) {
    return AmountText(
      text,
      tone: tone,
      textClass: text.length > _longest ? 'text-title' : 'text-display',
    );
  }
}
