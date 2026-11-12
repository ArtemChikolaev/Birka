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
/// On [stepDay], such as the day of an advance of the salary, both lines
/// rise by [stepAmount], a faint line marks the day, and [stepLabel] names it
/// under the chart, clear of the first and the last day. Until then the plan
/// spends [planPace] a day, and after it what is left by the last day. The
/// usual line can then cross zero twice, before the step and after it, with
/// a dot at each crossing.
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
    this.stepDay,
    this.stepAmount = 0,
    this.planPace,
    this.stepLabel,
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

  /// The day, counted from the first, on which both lines rise.
  final int? stepDay;

  /// What the lines rise by on [stepDay].
  final double stepAmount;

  /// What the plan spends a day until [stepDay].
  final double? planPace;

  /// The name of [stepDay] under the chart, such as «20 ноя · аванс».
  final String? stepLabel;

  @override
  State<ForecastChart> createState() => _ForecastChartState();
}

/// The numbers that the lines are drawn from: without a step, it stands on
/// day 0 and lifts nothing, so that a change moves the lines rather than
/// redraws them.
typedef _Shape = ({
  double start,
  double pace,
  double days,
  double step,
  double lift,
  double spend,
});

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
    step: math.min(chart.stepDay ?? 0, math.max(chart.days, 1)).toDouble(),
    lift: chart.stepDay == null ? 0 : chart.stepAmount,
    spend: chart.stepDay == null ? 0 : chart.planPace ?? 0,
  );

  _Shape get _now {
    final t = BirkaMotion.standardCurve.transform(_move.value);
    double lerp(double a, double b) => a + (b - a) * t;
    return (
      start: lerp(_from.start, _to.start),
      pace: lerp(_from.pace, _to.pace),
      days: lerp(_from.days, _to.days),
      step: lerp(_from.step, _to.step),
      lift: lerp(_from.lift, _to.lift),
      spend: lerp(_from.spend, _to.spend),
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
                  marked: widget.stepDay != null,
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
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    Expanded(child: FadingText(widget.from, style: small)),
                    FadingText(widget.to, style: small),
                  ],
                ),
                if (widget.stepLabel case final label?)
                  AnimatedBuilder(
                    animation: _move,
                    builder: (context, _) =>
                        _stepLabel(context, label, box.maxWidth),
                  ),
              ],
            ),
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

/// Where the name of the step stands under the chart: under the step, but
/// clear of the first and the last day, or nowhere when there is no room
/// between them.
extension on _ForecastChartState {
  Widget _stepLabel(BuildContext context, String label, double width) {
    final colors = BirkaColors.of(context);
    final small = BirkaTextStyles.of(
      context,
    ).caption.copyWith(color: colors.textSubtle);
    final muted = small.copyWith(color: colors.textMuted);
    final scaler = MediaQuery.textScalerOf(context);
    double widthOf(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final shape = _now;
    final half = widthOf(label, muted) / 2;
    const gap = BirkaTokens.spaceXs;
    final lowest = widthOf(widget.from, small) + gap + half;
    final highest = width - widthOf(widget.to, small) - gap - half;
    if (lowest > highest) return const SizedBox.shrink();
    final days = math.max(shape.days, 1);
    final x =
        _ForecastPainter.side +
        (width - 2 * _ForecastPainter.side) * shape.step / days;
    return Positioned(
      left: x.clamp(lowest, highest) - half,
      top: 0,
      child: Text(label, style: muted),
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
    required this.marked,
    required this.line,
    required this.loss,
    required this.plan,
    required this.ground,
  });

  final _Shape shape;

  /// Whether the day of the step is marked with a faint line.
  final bool marked;
  final Color line;
  final Color loss;
  final Color plan;
  final Color ground;

  /// How far the lines keep from the sides, the top and the bottom.
  static const double side = 8;
  static const double _side = side;
  static const double _top = 10;
  static const double _bottom = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final days = math.max(shape.days, 1);
    final start = shape.start;
    final pace = shape.pace;
    final step = shape.step;
    final lift = shape.lift;
    final dip = start - pace * step;
    final back = dip + lift;
    final end = back - pace * (days - step);
    final first = math.max(start, 0).toDouble();
    final planDip = first - shape.spend * step;
    final planEnd = start > 0 ? 0.0 : start + lift;
    final top = [start, back, planDip + lift, 0.0].reduce(math.max);
    final low = [0.0, dip, end].reduce(math.min);
    final span = math.max(top - low, 1);
    double x(num day) => _side + (size.width - 2 * _side) * day / days;
    double y(num value) =>
        _top + (size.height - _top - _bottom) * (top - value) / span;
    final zero = y(0);

    if (marked) {
      _dash(
        canvas,
        Offset(x(step), 2),
        Offset(x(step), size.height - 2),
        _stroke(line.withValues(alpha: 0.16), 1),
        dash: 2,
        gap: 4,
      );
    }
    _dash(
      canvas,
      Offset(_side, zero),
      Offset(size.width - _side, zero),
      _stroke(line.withValues(alpha: 0.22), 1),
      dash: 2,
      gap: 4,
    );
    final plan = [
      Offset(x(0), y(first)),
      Offset(x(step), y(planDip)),
      Offset(x(step), y(planDip + lift)),
      Offset(x(days), y(planEnd)),
    ];
    final dashes = _stroke(this.plan.withValues(alpha: 0.7), 2);
    for (var i = 1; i < plan.length; i++) {
      _dash(canvas, plan[i - 1], plan[i], dashes, dash: 5, gap: 6);
    }

    // The usual pace: one line, in the color of the text above zero and in
    // the color of a loss below it.
    final usual = Path()
      ..moveTo(x(0), y(start))
      ..lineTo(x(step), y(dip))
      ..lineTo(x(step), y(back))
      ..lineTo(x(days), y(end));
    final strokes = _stroke(line, 2.5)..strokeJoin = StrokeJoin.round;
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(-20, -20, size.width + 20, zero))
      ..drawPath(usual, strokes)
      ..restore()
      ..save()
      ..clipRect(Rect.fromLTRB(-20, zero, size.width + 20, size.height + 20))
      ..drawPath(usual, strokes..color = loss)
      ..restore();
    final crossings = [
      if (start <= 0) 0.0 else if (dip < 0) start / pace,
      if (back > 0 && end < 0) (start + lift) / pace,
    ];
    for (final day in crossings) {
      canvas
        ..drawCircle(Offset(x(day), zero), 5, Paint()..color = ground)
        ..drawCircle(Offset(x(day), zero), 5, _stroke(loss, 2.5));
    }
  }

  @override
  bool shouldRepaint(_ForecastPainter old) =>
      old.shape != shape ||
      old.marked != marked ||
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
