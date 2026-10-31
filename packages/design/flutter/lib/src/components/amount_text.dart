import 'package:design_flutter/src/components/hidden_amounts.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:flutter/widgets.dart';

/// The color of an [AmountText].
enum AmountTone {
  /// The color of the surrounding text.
  neutral,

  /// [BirkaColors.positive], for a rise.
  positive,

  /// [BirkaColors.negative], for a fall.
  negative,

  /// [BirkaColors.textMuted], for a figure that matters less.
  muted,
}

/// A figure in the amount style with tabular digits, which line up in
/// columns and keep their width when they change.
///
/// It shows [text] as it is: the caller formats the number and its sign. A
/// figure never wraps or loses digits; when it does not fit, it shrinks. Under
/// [HiddenAmounts] its digits are hidden, unless it is [alwaysShown].
class AmountText extends StatelessWidget {
  /// Creates a figure.
  const AmountText(
    this.text, {
    this.tone = AmountTone.neutral,
    this.style,
    this.alwaysShown = false,
    super.key,
  });

  /// The formatted figure, such as `−1 250 ₽`.
  final String text;

  /// The color of the figure.
  final AmountTone tone;

  /// A style in place of [BirkaTextStyles.amount], such as
  /// [BirkaTextStyles.display] for a total.
  final TextStyle? style;

  /// Whether the figure stays when amounts are hidden, such as one being typed.
  final bool alwaysShown;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final base = style ?? BirkaTextStyles.of(context).amount;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        alwaysShown ? text : HiddenAmounts.mask(context, text),
        maxLines: 1,
        softWrap: false,
        style: base.copyWith(
          color: switch (tone) {
            AmountTone.neutral => null,
            AmountTone.positive => colors.positive,
            AmountTone.negative => colors.negative,
            AmountTone.muted => colors.textMuted,
          },
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
