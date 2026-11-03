import 'dart:ui' show lerpDouble;

import 'package:design_flutter/src/components/amount_text.dart';
import 'package:design_flutter/src/components/card_art.dart';
import 'package:design_flutter/src/components/fading_text.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// The card of an account, with its art behind the name and the amount.
class AccountCard extends StatelessWidget {
  /// Creates a card.
  const AccountCard({
    required this.art,
    required this.name,
    required this.subtitle,
    required this.amount,
    this.value,
    this.onTap,
    this.compact = false,
    super.key,
  });

  /// The art of the card.
  final CardArt art;

  /// The name of the account.
  final String name;

  /// The quiet line under the name.
  final String subtitle;

  /// The formatted amount.
  final String amount;

  /// How much the account holds, such as in minor units, so that the amount
  /// rolls to a new balance as good or bad news ([AmountText.value]).
  final num? value;

  /// Called on a tap.
  final VoidCallback? onTap;

  /// Whether the card is one of several in a row.
  final bool compact;

  /// The height of the card.
  static const double height = 190;

  /// The height of a compact card.
  static const double compactHeight = 146;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: compact ? compactHeight : height,
        // Lays itself out by the height it gets, so that a compact card grows
        // into a full one smoothly as it flies into its page.
        child: LayoutBuilder(
          builder: (context, constraints) =>
              _face(context, _fullness(constraints.maxHeight)),
        ),
      ),
    );
  }

  /// How full a card of [extent] is: 0 at the compact height, 1 at the full.
  static double _fullness(double extent) =>
      ((extent - compactHeight) / (height - compactHeight)).clamp(0, 1);

  Widget _face(BuildContext context, double fullness) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return CardArtSurface(
      art: art,
      child: Padding(
        padding: EdgeInsets.all(
          lerpDouble(BirkaTokens.spaceMd, BirkaTokens.spaceLg, fullness)!,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toUpperCase(),
                        semanticsLabel: name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: styles.label.copyWith(color: colors.text),
                      ),
                      const SizedBox(height: BirkaTokens.spaceXxs),
                      FadingText(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: styles.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BirkaTokens.spaceSm),
                const _Chip(),
              ],
            ),
            const Spacer(),
            AmountText(
              amount,
              value: value,
              rise: AmountRise.good,
              style: TextStyle.lerp(
                styles.title,
                styles.display,
                fullness,
              )!.copyWith(color: colors.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// The chip of a bank card, drawn in glass.
class _Chip extends StatelessWidget {
  const _Chip();

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return Container(
      width: 38,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusXs),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.textSubtle, colors.surfaceSelected],
        ),
        border: Border.all(color: colors.glassBorder),
      ),
    );
  }
}
