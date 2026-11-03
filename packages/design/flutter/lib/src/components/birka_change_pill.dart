import 'package:design_flutter/src/components/amount_text.dart';
import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A pill with the arrow and the amount of a change.
class BirkaChangePill extends StatelessWidget {
  /// Creates a pill that says [label].
  const BirkaChangePill({
    required this.label,
    required this.rise,
    this.value,
    super.key,
  });

  /// The formatted amount with its sign.
  final String label;

  /// Whether the amount went up.
  final bool rise;

  /// How big the change is, such as in minor units, so that it rolls to a
  /// new one ([AmountText.value]). Its color already tells the news, so it
  /// does not flash.
  final num? value;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final color = rise ? colors.positive : colors.negative;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BirkaTokens.spaceSm,
        vertical: BirkaTokens.spaceXxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusPill),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BirkaIcon(
            rise ? BirkaGlyph.rise : BirkaGlyph.fall,
            size: 14,
            color: color,
          ),
          const SizedBox(width: BirkaTokens.spaceXxs),
          Flexible(
            child: AmountText(
              label,
              value: value,
              tone: rise ? AmountTone.positive : AmountTone.negative,
              style: BirkaTextStyles.of(context).bodyStrong,
            ),
          ),
        ],
      ),
    );
  }
}
