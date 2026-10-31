import 'dart:math';

import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:flutter/widgets.dart';

/// A line through [values] over a glow that fades out towards both sides, with
/// a dot on the last one.
class BirkaLineChart extends StatelessWidget {
  /// Creates a chart. Screen readers read [label].
  const BirkaLineChart({
    required this.values,
    required this.label,
    this.height = 96,
    super.key,
  });

  /// The values, the earliest first. A chart needs at least two.
  final List<double> values;

  /// What the chart shows, for screen readers.
  final String label;

  /// The height.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: label,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _LinePainter(
            values: values,
            color: BirkaColors.of(context).accent,
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.values, required this.color});

  /// More points than this add nothing at this size.
  static const _maxPoints = 60;

  static const double _thickness = 2.5;
  static const double _dot = 5;
  static const double _halo = 11;

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final points = _points(size);
    final line = _smooth(points);
    final bounds = Offset.zero & size;

    final glow = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas
      ..saveLayer(bounds, Paint())
      ..drawPath(
        glow,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ).createShader(bounds),
      )
      ..drawRect(
        bounds,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = const LinearGradient(
            colors: [Color(0x00000000), Color(0xFF000000), Color(0x00000000)],
            stops: [0, 0.7, 1],
          ).createShader(bounds),
      )
      ..restore()
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _thickness
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(
        points.last,
        _halo,
        Paint()..color = color.withValues(alpha: 0.2),
      )
      ..drawCircle(points.last, _dot, Paint()..color = color);
  }

  /// The values on the canvas, thinned out, with room for the dot on the last
  /// one. A line without any change runs through the middle.
  List<Offset> _points(Size size) {
    final step = (values.length / _maxPoints).ceil();
    final kept = [
      for (var i = 0; i < values.length - 1; i += step) values[i],
      values.last,
    ];
    final lowest = kept.reduce(min);
    final range = kept.reduce(max) - lowest;
    final height = size.height - _halo * 2;
    final width = size.width - _halo;
    return [
      for (final (index, value) in kept.indexed)
        Offset(
          width * index / (kept.length - 1),
          _halo +
              (range == 0
                  ? height / 2
                  : height * (1 - (value - lowest) / range)),
        ),
    ];
  }

  /// A curve through [points] that never swings past its neighbors.
  Path _smooth(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final before = points[max(i - 1, 0)];
      final from = points[i];
      final to = points[i + 1];
      final after = points[min(i + 2, points.length - 1)];
      final low = min(from.dy, to.dy);
      final high = max(from.dy, to.dy);
      path.cubicTo(
        from.dx + (to.dx - before.dx) / 6,
        (from.dy + (to.dy - before.dy) / 6).clamp(low, high),
        to.dx - (after.dx - from.dx) / 6,
        (to.dy - (after.dy - from.dy) / 6).clamp(low, high),
        to.dx,
        to.dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) =>
      color != oldDelegate.color || !_same(values, oldDelegate.values);

  static bool _same(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
