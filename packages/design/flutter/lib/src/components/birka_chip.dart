import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A pill to pick one option out of a few.
class BirkaChip extends StatelessWidget {
  /// Creates a chip.
  const BirkaChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.glyph,
    this.dashed = false,
    super.key,
  });

  /// What the chip says.
  final String label;

  /// Whether this option is picked.
  final bool selected;

  /// Called on a tap. Without it the chip cannot change.
  final VoidCallback? onTap;

  /// What stands before the label.
  final BirkaGlyph? glyph;

  /// Whether the chip offers something to add, with a dashed outline and no
  /// fill.
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final glyph = this.glyph;
    final foreground = selected ? colors.background : colors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: CustomPaint(
          foregroundPainter: dashed
              ? _DashedPillPainter(color: colors.textSubtle)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: BirkaTokens.durationFastMs),
            height: BirkaTokens.sizeTouchTarget,
            padding: const EdgeInsets.symmetric(
              horizontal: BirkaTokens.spaceMd,
            ),
            decoration: BoxDecoration(
              color: switch ((selected, dashed)) {
                (true, _) => colors.text,
                (false, true) => const Color(0x00000000),
                (false, false) => colors.surfaceRaised,
              },
              borderRadius: const BorderRadius.all(
                Radius.circular(BirkaTokens.radiusPill),
              ),
            ),
            child: Center(
              widthFactor: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (glyph != null) ...[
                    BirkaIcon(glyph, size: 20, color: foreground),
                    const SizedBox(width: BirkaTokens.spaceXs),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BirkaTextStyles.of(
                        context,
                      ).bodyStrong.copyWith(color: foreground),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A dashed outline along the edge of a pill.
class _DashedPillPainter extends CustomPainter {
  const _DashedPillPainter({required this.color});

  static const double _dash = 5;
  static const double _gap = 4;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          Radius.circular(size.height / 2),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillPainter oldDelegate) =>
      color != oldDelegate.color;
}
