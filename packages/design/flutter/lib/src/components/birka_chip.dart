import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/slide_switcher.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
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
    this.trailingGlyph,
    this.trailingTurns = 0,
    this.dashed = false,
    this.compact = false,
    this.order,
    this.count,
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

  /// What stands after the label, such as a chevron of a chip that opens a
  /// choice, or the cross of one that takes something off.
  final BirkaGlyph? trailingGlyph;

  /// How many quarter turns [trailingGlyph] takes: 1 points a chevron down.
  final int trailingTurns;

  /// Whether the chip offers something to add, with a dashed outline and no
  /// fill.
  final bool dashed;

  /// Whether the chip leaves less room around its label, for a row of many.
  final bool compact;

  /// Where the label stands among others, such as the month it names, so
  /// that a new label slides in from its side ([SlideSwitcher]) and the chip
  /// eases to its width. Without it a new label takes the place of the old
  /// one at once.
  final Comparable<Object?>? order;

  /// How many the chip stands for, beside its label, such as the operations
  /// of a filter.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final glyph = this.glyph;
    final trailingGlyph = this.trailingGlyph;
    final order = this.order;
    final count = this.count;
    final foreground = selected ? colors.background : colors.textSecondary;
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: BirkaTextStyles.of(
        context,
      ).bodyStrong.copyWith(color: foreground),
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: count == null ? label : '$label, $count',
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
            padding: EdgeInsets.symmetric(
              horizontal: compact ? BirkaTokens.spaceSm : BirkaTokens.spaceMd,
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
                    child: order == null
                        ? text
                        // The box of the label clips it as it slides.
                        : AnimatedSize(
                            duration: BirkaMotion.reduced(context)
                                ? Duration.zero
                                : BirkaMotion.base,
                            curve: BirkaMotion.standardCurve,
                            alignment: AlignmentDirectional.centerStart,
                            child: SlideSwitcher(
                              value: order,
                              distance: BirkaTokens.spaceMd,
                              child: text,
                            ),
                          ),
                  ),
                  if (trailingGlyph != null) ...[
                    const SizedBox(width: BirkaTokens.spaceXxs),
                    RotatedBox(
                      quarterTurns: trailingTurns,
                      child: BirkaIcon(
                        trailingGlyph,
                        size: 16,
                        color: foreground,
                      ),
                    ),
                  ],
                  // A count that comes or goes opens or closes its room.
                  AnimatedSize(
                    duration: BirkaMotion.reduced(context)
                        ? Duration.zero
                        : BirkaMotion.slow,
                    curve: BirkaMotion.standardCurve,
                    alignment: AlignmentDirectional.centerStart,
                    child: count == null
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: BirkaTokens.spaceXs),
                              AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: BirkaTokens.durationFastMs,
                                ),
                                constraints: const BoxConstraints(minWidth: 22),
                                height: 22,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? colors.background.withValues(
                                          alpha: 0.12,
                                        )
                                      : colors.surface,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(BirkaTokens.radiusPill),
                                  ),
                                ),
                                child: Text(
                                  '$count',
                                  style: BirkaTextStyles.of(
                                    context,
                                  ).caption.copyWith(color: foreground),
                                ),
                              ),
                            ],
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
