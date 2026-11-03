import 'dart:async';
import 'dart:math';

import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:flutter/widgets.dart';

/// A line through [values] over a glow that fades out towards both sides, with
/// a dot on the last one.
///
/// When its [series] changes, such as to another period, the old line fades,
/// the new one draws itself from the left over `duration.spring`, and its dot
/// comes last with a little bounce. When the system asks for less motion, the
/// two lines only cross-fade.
class BirkaLineChart extends StatefulWidget {
  /// Creates a chart. Screen readers read [label].
  const BirkaLineChart({
    required this.values,
    required this.label,
    this.series,
    this.height = 96,
    super.key,
  });

  /// The values, the earliest first. A chart needs at least two.
  final List<double> values;

  /// What the chart shows, for screen readers.
  final String label;

  /// What the line stands for, such as its period.
  final Object? series;

  /// The height.
  final double height;

  @override
  State<BirkaLineChart> createState() => _BirkaLineChartState();
}

class _BirkaLineChartState extends State<BirkaLineChart>
    with SingleTickerProviderStateMixin {
  // The old line fades over `duration.fast`, the new one draws over
  // `duration.spring`, and its dot comes over `duration.base`.
  static final int _fade = BirkaMotion.fast.inMilliseconds;
  static final int _drawing = BirkaMotion.spring.inMilliseconds;
  static final int _dot = BirkaMotion.base.inMilliseconds;

  late final AnimationController _draw = AnimationController(
    vsync: this,
    value: 1,
  );

  // The line that goes while a new one comes.
  List<double>? _old;

  @override
  void didUpdateWidget(BirkaLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.series == oldWidget.series) return;
    _old = oldWidget.values;
    _draw.duration = Duration(
      milliseconds: BirkaMotion.reduced(context)
          ? _dot
          : _fade + _drawing + _dot,
    );
    unawaited(_draw.forward(from: 0));
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = BirkaColors.of(context).accent;
    final reduced = BirkaMotion.reduced(context);
    return Semantics(
      image: true,
      label: widget.label,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _draw,
          builder: (context, _) {
            final old = _old;
            if (old == null || _draw.isCompleted) {
              return CustomPaint(
                painter: _LinePainter(values: widget.values, color: color),
              );
            }
            final ms = _draw.value * _draw.duration!.inMilliseconds;
            if (reduced) {
              final faded = BirkaMotion.fadeCurve.transform(_draw.value);
              return CustomPaint(
                painter: _LinePainter(
                  values: widget.values,
                  color: color,
                  opacity: faded,
                  old: old,
                  oldOpacity: 1 - faded,
                ),
              );
            }
            final dot = ((ms - _fade - _drawing) / _dot).clamp(0.0, 1.0);
            return CustomPaint(
              painter: _LinePainter(
                values: widget.values,
                color: color,
                old: old,
                oldOpacity:
                    1 -
                    BirkaMotion.fadeCurve.transform((ms / _fade).clamp(0, 1)),
                drawn: BirkaMotion.standardCurve.transform(
                  ((ms - _fade) / _drawing).clamp(0, 1),
                ),
                dotScale: 0.4 + 0.6 * BirkaMotion.springCurve.transform(dot),
                dotOpacity: BirkaMotion.fadeCurve.transform(
                  (dot * _dot / _fade).clamp(0, 1),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.values,
    required this.color,
    this.opacity = 1,
    this.old,
    this.oldOpacity = 0,
    this.drawn = 1,
    this.dotScale = 1,
    this.dotOpacity = 1,
  });

  /// More points than this add nothing at this size.
  static const _maxPoints = 60;

  static const double _thickness = 2.5;
  static const double _dot = 5;
  static const double _halo = 11;

  final List<double> values;
  final Color color;
  final double opacity;

  /// A line that fades as this one comes, and how much of it still shows.
  final List<double>? old;
  final double oldOpacity;

  /// How much of the line has drawn itself, from the left.
  final double drawn;

  /// How big and how strong the dot on the last value is.
  final double dotScale;
  final double dotOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final old = this.old;
    if (old != null && oldOpacity > 0) {
      _paintLine(canvas, size, old, opacity: oldOpacity);
    }
    if (opacity > 0) {
      _paintLine(
        canvas,
        size,
        values,
        opacity: opacity,
        drawn: drawn,
        dotScale: dotScale,
        dotOpacity: dotOpacity,
      );
    }
  }

  void _paintLine(
    Canvas canvas,
    Size size,
    List<double> values, {
    required double opacity,
    double drawn = 1,
    double dotScale = 1,
    double dotOpacity = 1,
  }) {
    if (values.length < 2 || drawn <= 0) return;
    final points = _points(size, values);
    var line = _smooth(points);
    final bounds = Offset.zero & size;
    var head = points.last;
    if (drawn < 1) {
      final metric = line.computeMetrics().first;
      final length = metric.length * drawn;
      head = metric.getTangentForOffset(length)?.position ?? head;
      line = metric.extractPath(0, length);
    }

    final glow = Path.from(_smooth(points))
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas
      ..saveLayer(
        bounds,
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
      )
      ..save()
      ..clipRect(Rect.fromLTRB(0, 0, head.dx + _halo, size.height))
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
      );
    if (drawn >= 1 && dotOpacity > 0) {
      canvas
        ..drawCircle(
          points.last,
          _halo * dotScale,
          Paint()..color = color.withValues(alpha: 0.2 * dotOpacity),
        )
        ..drawCircle(
          points.last,
          _dot * dotScale,
          Paint()..color = color.withValues(alpha: dotOpacity),
        );
    }
    canvas.restore();
  }

  /// The values on the canvas, thinned out, with room for the dot on the last
  /// one. A line without any change runs through the middle.
  List<Offset> _points(Size size, List<double> values) {
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
      color != oldDelegate.color ||
      opacity != oldDelegate.opacity ||
      oldOpacity != oldDelegate.oldOpacity ||
      drawn != oldDelegate.drawn ||
      dotScale != oldDelegate.dotScale ||
      dotOpacity != oldDelegate.dotOpacity ||
      !_same(values, oldDelegate.values) ||
      old != oldDelegate.old;

  static bool _same(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
