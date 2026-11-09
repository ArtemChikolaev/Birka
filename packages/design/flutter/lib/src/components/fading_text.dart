import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:flutter/widgets.dart';

/// A line of [text] that cross-fades into a new one over `duration.base`
/// when it changes, such as the period of a change, and changes at once when
/// the system asks for less motion.
class FadingText extends StatelessWidget {
  /// Creates a line of [text].
  const FadingText(
    this.text, {
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.semanticsLabel,
    super.key,
  });

  /// What the line says.
  final String text;

  /// How it looks.
  final TextStyle? style;

  /// How many lines it takes before it is cut.
  final int? maxLines;

  /// How it is cut.
  final TextOverflow? overflow;

  /// How its lines align.
  final TextAlign? textAlign;

  /// What screen readers say in place of [text].
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: BirkaMotion.reduced(context) ? Duration.zero : BirkaMotion.base,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [...previous, ?current],
      ),
      child: Text(
        text,
        key: ValueKey(text),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}
