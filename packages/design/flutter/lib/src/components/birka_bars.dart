import 'dart:math';

import 'package:design_flutter/src/components/amount_text.dart';
import 'package:design_flutter/src/components/hidden_amounts.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A bar of [BirkaBars].
@immutable
final class BirkaBar {
  /// Creates a bar of [value].
  const BirkaBar({
    required this.value,
    required this.amount,
    required this.label,
    this.highlighted = false,
  });

  /// How tall the bar is against the others.
  final double value;

  /// The figure over the bar. It is hidden along with other amounts.
  final String amount;

  /// What stands under the bar, such as a short name of a month.
  final String label;

  /// Whether this is the bar that matters, in emerald.
  final bool highlighted;
}

/// A row of bars with a figure over each and a name under it.
class BirkaBars extends StatelessWidget {
  /// Creates a row of [bars].
  const BirkaBars({required this.bars, super.key});

  /// The bars, from left to right.
  final List<BirkaBar> bars;

  /// The height of the tallest bar.
  static const double _height = 72;

  /// The height of a bar without a value, so that its place shows.
  static const double _lowest = 6;

  @override
  Widget build(BuildContext context) {
    final tallest = bars.map((bar) => bar.value).fold<double>(0, max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: BirkaTokens.spaceXs,
      children: [
        for (final bar in bars)
          Expanded(
            child: _Bar(bar: bar, tallest: tallest),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bar, required this.tallest});

  final BirkaBar bar;
  final double tallest;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final share = tallest > 0 ? bar.value / tallest : 0.0;
    return Semantics(
      container: true,
      label: '${bar.label}: ${HiddenAmounts.mask(context, bar.amount)}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: AmountText(
              bar.amount,
              tone: bar.highlighted ? AmountTone.positive : AmountTone.muted,
              style: styles.caption,
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceXxs),
          Container(
            height: max(BirkaBars._height * share, BirkaBars._lowest),
            decoration: BoxDecoration(
              color: bar.highlighted ? colors.accent : colors.surfaceRaised,
              borderRadius: const BorderRadius.all(
                Radius.circular(BirkaTokens.radiusXs),
              ),
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            bar.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: styles.caption.copyWith(
              color: bar.highlighted ? colors.text : colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
