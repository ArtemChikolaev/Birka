import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:flutter/widgets.dart';

/// A line of [text] that cross-fades into a new one over `duration.base`
/// when it changes, such as the period of a change, and changes at once when
/// the system asks for less motion.
class FadingText extends StatelessWidget {
  /// Creates a line of [text].
  const FadingText(this.text, {this.style, super.key});

  /// What the line says.
  final String text;

  /// How it looks.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: BirkaMotion.reduced(context) ? Duration.zero : BirkaMotion.base,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [...previous, ?current],
      ),
      child: Text(text, key: ValueKey(text), style: style),
    );
  }
}
