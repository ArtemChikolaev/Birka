import 'dart:async';
import 'dart:math' as math;

import 'package:design_flutter/src/components/fading_text.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// Where money goes from today to the last of [days] days: at the usual
/// [pace] a day, a line in the color of the text that turns into the color
/// of a loss below zero, with a dot where it crosses it, and by the plan, a
/// dashed line of the accent that spends [start] by the last day. Zero is a
/// dotted line. Under the chart [from] and [to] name its first and last days,
/// and a legend names its two lines, [usual] and [planned].
///
/// When the numbers change, such as when an account counts no more, the
/// lines move to their new places over `duration.roll`, and the words
/// cross-fade; when the system asks for less motion, the lines move at once.
/// Screen readers read [label].
class ForecastChart extends StatefulWidget {
  /// Creates the chart.
  const ForecastChart({
    required this.start,
    required this.pace,
    required this.days,
    required this.label,
    required this.from,
    required this.to,
    required this.usual,
    required this.planned,
    super.key,
  });

  /// What the days may spend together at the start.
  final double start;

  /// What a day takes as usual.
  final double pace;

  /// How many days the chart spans.
  final int days;

  /// What the chart says, for screen readers.
  final String label;

  /// The name of its first day, such as «сегодня».
  final String from;

  /// The name of its last day, such as «5 дек · зарплата».
  final String to;

  /// What the line of the usual pace stands for.
  final String usual;

  /// What the line of the plan stands for.
  final String planned;

  @override
  State<ForecastChart> createState() => _ForecastChartState();
}

/// The numbers that the lines are drawn from.
typedef _Shape = ({double start, double pace, double days});

class _ForecastChartState extends State<ForecastChart>
    with SingleTickerProviderStateMixin {
  /// The height of the lines.
  static const double _height = 112;

  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: BirkaMotion.roll,
    value: 1,
  );
  late _Shape _from = _shapeOf(widget);
  late _Shape _to = _from;

  static _Shape _shapeOf(ForecastChart chart) => (
    start: chart.start,
    pace: chart.pace,
    days: chart.days.toDouble(),
  );

  _Shape get _now {
    final t = BirkaMotion.standardCurve.transform(_move.value);
    double lerp(double a, double b) => a + (b - a) * t;
    return (
      start: lerp(_from.start, _to.start),
      pace: lerp(_from.pace, _to.pace),
      days: lerp(_from.days, _to.days),
    );
  }

  @override
  void didUpdateWidget(ForecastChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _shapeOf(widget);
    if (next == _to) return;
    _from = _now;
    _to = next;
    if (BirkaMotion.reduced(context)) {
      _move.value = 1;
    } else {
      unawaited(_move.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final small = styles.caption.copyWith(color: colors.textSubtle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          image: true,
          label: widget.label,
          excludeSemantics: true,
          child: SizedBox(
            height: _height,
            child: AnimatedBuilder(
              animation: _move,
              builder: (context, _) => CustomPaint(
                size: Size.infinite,
                painter: _ForecastPainter(
                  _now,
                  line: colors.text,
                  loss: colors.negative,
                  plan: colors.accent,
                  ground: colors.background,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceXxs),
        ExcludeSemantics(
          child: Row(
            children: [
              Expanded(child: FadingText(widget.from, style: small)),
              FadingText(widget.to, style: small),
            ],
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        ExcludeSemantics(
          child: Wrap(
            spacing: BirkaTokens.spaceMd,
            runSpacing: BirkaTokens.spaceXxs,
            children: [
              _Key(
                sample: _Sample(color: colors.text),
                label: widget.usual,
              ),
              _Key(
                sample: _Sample(color: colors.accent, dashed: true),
                label: widget.planned,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A line of the legend: a sample of a line and what it stands for.
class _Key extends StatelessWidget {
  const _Key({required this.sample, required this.label});

  final Widget sample;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        sample,
        const SizedBox(width: BirkaTokens.spaceXxs + 2),
        // A long label on a narrow screen goes on to a second line.
        Flexible(
          child: FadingText(
            label,
            style: BirkaTextStyles.of(
              context,
            ).caption.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// A short line in the legend, as the chart draws its own.
class _Sample extends StatelessWidget {
  const _Sample({required this.color, this.dashed = false});

  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 4),
      painter: _SamplePainter(color, dashed: dashed),
    );
  }
}

class _SamplePainter extends CustomPainter {
  _SamplePainter(this.color, {required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = _stroke(
      dashed ? color.withValues(alpha: 0.7) : color,
      dashed ? 2 : 2.5,
    );
    final a = Offset(1, size.height / 2);
    final b = Offset(size.width - 1, size.height / 2);
    if (dashed) {
      _dash(canvas, a, b, paint, dash: 5, gap: 6);
    } else {
      canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(_SamplePainter old) =>
      old.color != color || old.dashed != dashed;
}

class _ForecastPainter extends CustomPainter {
  _ForecastPainter(
    this.shape, {
    required this.line,
    required this.loss,
    required this.plan,
    required this.ground,
  });

  final _Shape shape;
  final Color line;
  final Color loss;
  final Color plan;
  final Color ground;

  /// How far the lines keep from the sides, the top and the bottom.
  static const double _side = 8;
  static const double _top = 10;
  static const double _bottom = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final days = math.max(shape.days, 1);
    final start = shape.start;
    final pace = shape.pace;
    final end = start - pace * days;
    final top = math.max(start, 0);
    final low = math.min(0, end);
    final span = math.max(top - low, 1);
    double x(num day) => _side + (size.width - 2 * _side) * day / days;
    double y(num value) =>
        _top + (size.height - _top - _bottom) * (top - value) / span;
    Offset at(num day) => Offset(x(day), y(start - pace * day));

    // Where the usual pace crosses zero, if it does.
    final short = end < 0;
    final cross = start <= 0 ? 0 : (short ? start / pace : days);

    _dash(
      canvas,
      Offset(_side, y(0)),
      Offset(size.width - _side, y(0)),
      _stroke(line.withValues(alpha: 0.22), 1),
      dash: 2,
      gap: 4,
    );
    _dash(
      canvas,
      Offset(x(0), y(top)),
      Offset(x(days), y(start > 0 ? 0 : start)),
      _stroke(plan.withValues(alpha: 0.7), 2),
      dash: 5,
      gap: 6,
    );
    canvas.drawLine(at(0), at(cross), _stroke(line, 2.5));
    if (short) {
      canvas
        ..drawLine(at(cross), at(days), _stroke(loss, 2.5))
        ..drawCircle(at(cross), 5, Paint()..color = ground)
        ..drawCircle(at(cross), 5, _stroke(loss, 2.5));
    }
  }

  @override
  bool shouldRepaint(_ForecastPainter old) =>
      old.shape != shape ||
      old.line != line ||
      old.loss != loss ||
      old.plan != plan ||
      old.ground != ground;
}

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

/// Draws a dashed line from [a] to [b].
void _dash(
  Canvas canvas,
  Offset a,
  Offset b,
  Paint paint, {
  required double dash,
  required double gap,
}) {
  final length = (b - a).distance;
  if (length == 0) return;
  final step = (b - a) / length;
  for (var at = 0.0; at < length; at += dash + gap) {
    canvas.drawLine(
      a + step * at,
      a + step * math.min(at + dash, length),
      paint,
    );
  }
}
