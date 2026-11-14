import 'package:design_flutter/src/components/glyph_badge.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:flutter/widgets.dart';

/// The first letter of [name] in [color] on a faint tile of the same color,
/// such as the person of a debt (ADR 0029). It eases into a new color over
/// `duration.fast`, as a [GlyphBadge] does.
class InitialBadge extends StatelessWidget {
  /// Creates a badge.
  const InitialBadge({
    required this.name,
    required this.color,
    this.size = 36,
    super.key,
  });

  /// The name whose first letter the badge shows.
  final String name;

  /// The color of the letter and of its tile.
  final Color color;

  /// The width and the height.
  final double size;

  /// The first letter of [name], in capitals, or a question mark for a name
  /// with none.
  static String letterOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCodes(trimmed.runes.take(1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: BirkaMotion.reduced(context) ? Duration.zero : BirkaMotion.fast,
      builder: (context, color, _) {
        final shown = color ?? this.color;
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: shown.withValues(alpha: 0.16),
            // A tile of 36 takes the small radius, one of 72 the large.
            borderRadius: BorderRadius.all(Radius.circular(size * 0.3)),
          ),
          child: Text(
            letterOf(name),
            style: styles.heading.copyWith(
              color: shown,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        );
      },
    );
  }
}
