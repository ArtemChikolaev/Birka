import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:flutter/widgets.dart';

/// A bar of how much of something is gone: it grows to [value] over
/// `duration.roll` and takes its [color] over `duration.slow`, such as the
/// money of today (ADR 0023) or a monthly limit (ADR 0033).
class BirkaMeter extends StatelessWidget {
  /// Creates a bar filled to [value], from 0 to 1.
  const BirkaMeter({
    required this.value,
    required this.color,
    required this.label,
    this.height = 8,
    this.fromEmpty = false,
    super.key,
  });

  /// How much is gone, from 0 to 1; more stays full.
  final double value;

  /// The color of what is gone.
  final Color color;

  /// What screen readers say of the bar.
  final String label;

  /// How tall the bar is.
  final double height;

  /// Whether the bar fills from empty as it first shows.
  final bool fromEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final reduced = BirkaMotion.reduced(context);
    final share = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final radius = BorderRadius.all(Radius.circular(height / 2));
    return Semantics(
      label: label,
      value: '${(share * 100).round()}%',
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: colors.surfaceRaised,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: fromEmpty ? 0 : null, end: share),
              duration: reduced ? Duration.zero : BirkaMotion.roll,
              curve: BirkaMotion.standardCurve,
              builder: (context, value, _) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: value,
                  heightFactor: 1,
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: color),
                    duration: BirkaMotion.slow,
                    curve: BirkaMotion.fadeCurve,
                    builder: (context, ink, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: radius,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
