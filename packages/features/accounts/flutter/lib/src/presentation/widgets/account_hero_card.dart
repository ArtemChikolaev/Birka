import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';

/// The big card of an account, with its art behind the name and the amount.
class AccountHeroCard extends StatelessWidget {
  /// Creates a card.
  const AccountHeroCard({
    required this.art,
    required this.name,
    required this.subtitle,
    required this.amount,
    this.onTap,
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

  /// Called on a tap.
  final VoidCallback? onTap;

  /// The height of the card.
  static const double height = 190;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: CardArtSurface(
          art: art,
          child: Padding(
            padding: const EdgeInsets.all(BirkaTokens.spaceLg),
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
                          Text(
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
                  style: styles.display.copyWith(color: colors.text),
                ),
              ],
            ),
          ),
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
