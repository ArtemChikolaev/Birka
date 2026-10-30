import 'dart:ui' show ImageFilter;

import 'package:design_flutter/src/components/ambient_background.dart';
import 'package:design_flutter/src/components/glass_filter.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A panel of Liquid Glass. It blurs what lies behind it and makes its
/// colors richer, fills itself with a faint white gradient and draws a
/// hairline border with a light line along the top edge.
///
/// Glass needs something behind it to show, such as an [AmbientBackground].
/// Inside a [BackdropGroup], glass surfaces share one backdrop, which is
/// cheaper for a list of cards. A surface that floats over other glass, such
/// as a navigation bar, stays out of the group: grouped filters do not see
/// each other.
class GlassSurface extends StatelessWidget {
  /// Creates a glass panel around [child].
  const GlassSurface({
    required this.child,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(BirkaTokens.radiusLg),
    ),
    this.padding = const EdgeInsets.all(BirkaTokens.spaceMd),
    super.key,
  });

  /// The content of the panel.
  final Widget child;

  /// The corners of the panel.
  final BorderRadius borderRadius;

  /// The space between the border and [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter.grouped(
        filter: _filter,
        child: CustomPaint(
          painter: _GlassPainter(BirkaColors.of(context), borderRadius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

final ImageFilter _filter = glassFilter(
  blur: BirkaTokens.blurGlass,
  saturation: BirkaTokens.saturationGlass,
);

/// Paints the fill, the highlight and the border the way CSS paints the
/// glass of the mockups.
final class _GlassPainter extends CustomPainter {
  const _GlassPainter(this.colors, this.borderRadius);

  final BirkaColors colors;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final outer = borderRadius.toRRect(bounds);
    final inner = outer.deflate(1);
    // CSS `inset 0 1px 0`: the inside of the border without the same shape
    // one pixel lower, which leaves a line along the top that thins out
    // around the corners.
    final highlight = Path.combine(
      PathOperation.difference,
      Path()..addRRect(inner),
      Path()..addRRect(inner.shift(const Offset(0, 1))),
    );
    final fill = LinearGradient(
      begin: const Alignment(-0.35, -1),
      end: const Alignment(0.35, 1),
      colors: [colors.glassFillTop, colors.glassFillBottom],
    );
    canvas
      ..drawRRect(outer, Paint()..shader = fill.createShader(bounds))
      ..drawPath(highlight, Paint()..color = colors.glassHighlight)
      ..drawDRRect(outer, inner, Paint()..color = colors.glassBorder);
  }

  @override
  bool shouldRepaint(_GlassPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.borderRadius != borderRadius;
}
