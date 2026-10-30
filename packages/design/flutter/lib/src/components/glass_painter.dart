import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// Paints a glass shape the way CSS paints the glass of the mockups: a fill,
/// a light line along the top edge, a dim one along the bottom if it is
/// given, and a hairline border.
final class GlassPainter extends CustomPainter {
  /// Creates a painter of a shape with [borderRadius].
  const GlassPainter({
    required this.borderRadius,
    required this.fillTop,
    required this.fillBottom,
    required this.highlight,
    this.lowlight,
    this.border,
  });

  /// The corners of the shape.
  final BorderRadius borderRadius;

  /// The fill at the top, which fades to [fillBottom].
  final Color fillTop;

  /// The fill at the bottom.
  final Color fillBottom;

  /// The light line along the top edge.
  final Color highlight;

  /// The dim line along the bottom edge.
  final Color? lowlight;

  /// The hairline border.
  final Color? border;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final outer = borderRadius.toRRect(bounds);
    final border = this.border;
    final inner = border == null ? outer : outer.deflate(1);
    final fill = LinearGradient(
      begin: const Alignment(-0.35, -1),
      end: const Alignment(0.35, 1),
      colors: [fillTop, fillBottom],
    );
    canvas
      ..drawRRect(outer, Paint()..shader = fill.createShader(bounds))
      ..drawPath(_edgeLine(inner, 1), Paint()..color = highlight);
    final lowlight = this.lowlight;
    if (lowlight != null) {
      canvas.drawPath(_edgeLine(inner, -1), Paint()..color = lowlight);
    }
    if (border != null) {
      canvas.drawDRRect(outer, inner, Paint()..color = border);
    }
  }

  /// CSS `inset 0 1px 0`: the shape without itself moved by [dy], which
  /// leaves a line along one edge that thins out around the corners.
  Path _edgeLine(RRect shape, double dy) => Path.combine(
    PathOperation.difference,
    Path()..addRRect(shape),
    Path()..addRRect(shape.shift(Offset(0, dy))),
  );

  @override
  bool shouldRepaint(GlassPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.fillTop != fillTop ||
      oldDelegate.fillBottom != fillBottom ||
      oldDelegate.highlight != highlight ||
      oldDelegate.lowlight != lowlight ||
      oldDelegate.border != border;
}

/// Paints [shadows] around a shape and not under it, as a CSS `box-shadow`
/// does, so that glass stays see-through.
final class OuterShadowPainter extends CustomPainter {
  /// Creates a painter of the shadows of a shape with [borderRadius].
  const OuterShadowPainter({required this.borderRadius, required this.shadows});

  /// The corners of the shape.
  final BorderRadius borderRadius;

  /// The layers from the design tokens.
  final List<ShadowToken> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final shape = borderRadius.toRRect(bounds);
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds.inflate(size.longestSide + 200))
      ..addRRect(shape);
    canvas
      ..save()
      ..clipPath(outside);
    for (final shadow in shadows) {
      canvas.drawRRect(
        shape
            .shift(Offset(shadow.offsetX, shadow.offsetY))
            .inflate(shadow.spread),
        Paint()
          ..color = Color(shadow.color)
          // The blur radius of CSS is twice the standard deviation.
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blur / 2),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(OuterShadowPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.shadows != shadows;
}
