import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A part of a whole on a line: a dot of [color], [title], an optional
/// [note], what the part came to as [amount], and under them a bar of the
/// same color, [fraction] of the full width.
///
/// The bar grows into its length when it comes and moves to a new one over
/// `duration.roll`; with less motion it stands at its length.
class ShareLine extends StatelessWidget {
  /// Creates a line.
  const ShareLine({
    required this.color,
    required this.title,
    required this.amount,
    required this.fraction,
    this.note,
    this.noteColor,
    super.key,
  });

  /// The color of the dot and of the bar.
  final Color color;

  /// What the part is.
  final String title;

  /// What it came to, as the caller draws it.
  final Widget amount;

  /// The length of the bar, from 0 to 1.
  final double fraction;

  /// A short word before the amount, such as a change or a share.
  final String? note;

  /// The color of [note], muted unless told otherwise.
  final Color? noteColor;

  static const double _dot = 10;
  static const double _bar = 4;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final note = this.note;
    return Padding(
      padding: const EdgeInsets.all(BirkaTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: _dot,
                height: _dot,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: BirkaTokens.spaceXs),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.bodyStrong.copyWith(color: colors.text),
                ),
              ),
              if (note != null) ...[
                const SizedBox(width: BirkaTokens.spaceXs),
                Text(
                  note,
                  style: styles.caption.copyWith(
                    color: noteColor ?? colors.textMuted,
                  ),
                ),
              ],
              const SizedBox(width: BirkaTokens.spaceSm),
              Flexible(
                child: Align(alignment: Alignment.centerRight, child: amount),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(BirkaTokens.radiusXs),
            ),
            child: ColoredBox(
              color: colors.surfaceRaised,
              child: SizedBox(
                height: _bar,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
                  duration: BirkaMotion.reduced(context)
                      ? Duration.zero
                      : BirkaMotion.roll,
                  curve: BirkaMotion.standardCurve,
                  builder: (context, length, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: length,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
