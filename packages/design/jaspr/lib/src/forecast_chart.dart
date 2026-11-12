import 'dart:math' as math;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Where money goes from today to the last of [days] days, as the app draws
/// it: at the usual [pace] a day, a line in the color of the text that turns
/// into the color of a loss below zero, with a dot where it crosses it, and
/// by the plan, a dashed line of the accent that spends [start] by the last
/// day. Zero is a dotted line. Under the chart [from] and [to] name its first
/// and last days, and a legend names its two lines, [usual] and [planned].
///
/// On [stepDay], such as the day of an advance of the salary, both lines
/// rise by [stepAmount], a faint line marks the day, and [stepLabel] names it
/// under the chart. Until then the plan spends [planPace] a day, and after it
/// what is left by the last day. The usual line can then cross zero twice:
/// before the step and after it, with a dot at each crossing. The page shows
/// one such chart, whose clips have fixed ids.
///
/// When the numbers change, the lines move to their new places over
/// `duration.roll` where the browser can move a path; when the system asks
/// for less motion, they move at once. Screen readers read [label].
class ForecastChart extends StatelessComponent {
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

  /// The box the lines are drawn in; the chart stretches it to its width.
  static const double _width = 1000;
  static const double _height = 112;
  static const double _side = 8;
  static const double _top = 10;
  static const double _bottom = 16;

  @override
  Component build(BuildContext context) {
    final period = math.max(days, 1);
    // Every line has four points, with the step on day 0 and of nothing when
    // there is none, so that a change moves them rather than redraws them.
    final step = math.min(stepDay ?? 0, period).toDouble();
    final lift = stepDay == null ? 0.0 : stepAmount;
    final dip = start - pace * step;
    final back = dip + lift;
    final end = back - pace * (period - step);
    final first = math.max(start, 0).toDouble();
    final spend = planPace ?? 0;
    final planDip = stepDay == null ? first : first - spend * step;
    final planEnd = start > 0 ? 0.0 : start + lift;
    final top = [start, back, planDip + lift, 0.0].reduce(math.max);
    final low = [0.0, dip, end].reduce(math.min);
    final range = math.max(top - low, 1);
    double x(num day) => _side + (_width - 2 * _side) * day / period;
    double y(num value) =>
        _top + (_height - _top - _bottom) * (top - value) / range;
    String line(List<(num, double)> points) =>
        'M ${points.map((it) => '${x(it.$1).toStringAsFixed(1)} '
            '${y(it.$2).toStringAsFixed(1)}').join(' L ')}';
    final usualLine = line([
      (0, start),
      (step, dip),
      (step, back),
      (period, end),
    ]);
    final crossings = [
      if (start <= 0) 0.0 else if (dip < 0) start / pace,
      if (back > 0 && end < 0) (start + lift) / pace,
    ];
    final zero = y(0);
    String percent(double value, double whole) =>
        '${(value / whole * 100).toStringAsFixed(2)}%';
    final label = stepLabel;
    return div(classes: 'forecast-chart', [
      div(
        classes: 'forecast-chart__plot',
        attributes: {'role': 'img', 'aria-label': this.label},
        [
          svg(
            viewBox: '0 0 $_width $_height',
            attributes: const {
              'preserveAspectRatio': 'none',
              'aria-hidden': 'true',
            },
            [
              // The usual line is drawn twice: above zero in the color of the
              // text, and below it in the color of a loss.
              Component.element(
                tag: 'defs',
                children: [
                  _clip('forecast-chart-above', -20, zero + 20),
                  _clip('forecast-chart-below', zero, _height + 20 - zero),
                ],
              ),
              if (stepDay != null)
                _path(
                  'M ${x(step).toStringAsFixed(1)} 2 '
                      'L ${x(step).toStringAsFixed(1)} ${_height - 2}',
                  'forecast-chart__step',
                ),
              _path(line([(0, 0), (period, 0)]), 'forecast-chart__zero'),
              _path(
                line([
                  (0, first),
                  (step, planDip),
                  (step, planDip + lift),
                  (period, planEnd),
                ]),
                'forecast-chart__plan',
              ),
              _path(
                usualLine,
                'forecast-chart__usual',
                clip: 'forecast-chart-above',
              ),
              _path(
                usualLine,
                'forecast-chart__under',
                clip: 'forecast-chart-below',
              ),
            ],
          ),
          // The dots stay round however wide the chart is.
          for (final day in crossings)
            span(
              classes: 'forecast-chart__dot',
              styles: Styles(
                raw: {
                  'left': percent(x(day), _width),
                  'top': percent(zero, _height),
                },
              ),
              const [],
            ),
        ],
      ),
      div(classes: 'text-caption forecast-chart__ends', [
        span([.text(from)]),
        if (label != null)
          span(
            classes: 'forecast-chart__step-label',
            styles: Styles(
              // It keeps clear of the first and the last day.
              raw: {
                'left':
                    'clamp(calc(${from.length}ch + ${label.length / 2}ch), '
                    '${percent(x(step), _width)}, '
                    'calc(100% - ${to.length}ch - ${label.length / 2}ch))',
              },
            ),
            [.text(label)],
          ),
        span([.text(to)]),
      ]),
      div(classes: 'text-caption forecast-chart__legend', [
        span(classes: 'forecast-chart__key forecast-chart__key--usual', [
          .text(usual),
        ]),
        span(classes: 'forecast-chart__key forecast-chart__key--plan', [
          .text(planned),
        ]),
      ]),
    ]);
  }

  /// A clip of the plot from [top] down by [height], in the box of the lines.
  static Component _clip(String id, double top, double height) {
    return Component.element(
      tag: 'clipPath',
      id: id,
      children: [
        Component.element(
          tag: 'rect',
          attributes: {
            'x': '-20',
            'y': top.toStringAsFixed(1),
            'width': '${_width + 40}',
            'height': height.toStringAsFixed(1),
          },
          styles: Styles(
            raw: {
              'y': '${top.toStringAsFixed(1)}px',
              'height': '${height.toStringAsFixed(1)}px',
            },
          ),
        ),
      ],
    );
  }

  static Component _path(String d, String classes, {String? clip}) => path(
    d: d,
    classes: classes,
    attributes: {
      'vector-effect': 'non-scaling-stroke',
      if (clip != null) 'clip-path': 'url(#$clip)',
    },
    styles: Styles(raw: {'d': "path('$d')"}),
    const [],
  );

  /// The styles of the chart.
  @css
  static List<StyleRule> get styles => [
    css('.forecast-chart').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
      },
    ),
    css('.forecast-chart__plot').styles(
      raw: {'height': '${_height.toInt()}px', 'position': 'relative'},
    ),
    css('.forecast-chart__plot svg').styles(
      raw: {
        'display': 'block',
        'height': '100%',
        'overflow': 'visible',
        'width': '100%',
      },
    ),
    css('.forecast-chart__plot path').styles(
      raw: {
        'fill': 'none',
        'stroke-linecap': 'round',
        'transition': 'd var(--duration-roll) var(--easing-standard)',
      },
    ),
    css('.forecast-chart__zero').styles(
      raw: {
        'stroke': 'color-mix(in srgb, var(--color-text) 22%, transparent)',
        'stroke-dasharray': '2 4',
        'stroke-width': '1',
      },
    ),
    css('.forecast-chart__plan').styles(
      raw: {
        'opacity': '0.7',
        'stroke': 'var(--color-accent)',
        'stroke-dasharray': '5 6',
        'stroke-width': '2',
      },
    ),
    css('.forecast-chart__usual').styles(
      raw: {'stroke': 'var(--color-text)', 'stroke-width': '2.5'},
    ),
    css('.forecast-chart__under').styles(
      raw: {'stroke': 'var(--color-negative)', 'stroke-width': '2.5'},
    ),
    css('.forecast-chart__dot').styles(
      raw: {
        'background': 'var(--color-background)',
        'border': '2.5px solid var(--color-negative)',
        'border-radius': '50%',
        'box-sizing': 'border-box',
        'height': '10px',
        'position': 'absolute',
        'transform': 'translate(-50%, -50%)',
        'transition':
            'left var(--duration-roll) var(--easing-standard), '
            'top var(--duration-roll) var(--easing-standard)',
        'width': '10px',
      },
    ),
    css('.forecast-chart__step').styles(
      raw: {
        'stroke': 'color-mix(in srgb, var(--color-text) 16%, transparent)',
        'stroke-dasharray': '2 4',
        'stroke-width': '1',
      },
    ),
    css('.forecast-chart__plot rect').styles(
      raw: {
        'transition':
            'y var(--duration-roll) var(--easing-standard), '
            'height var(--duration-roll) var(--easing-standard)',
      },
    ),
    css('.forecast-chart__ends').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'display': 'flex',
        'justify-content': 'space-between',
        'position': 'relative',
      },
    ),
    css('.forecast-chart__step-label').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'position': 'absolute',
        'top': '0',
        'transform': 'translateX(-50%)',
        'transition': 'left var(--duration-roll) var(--easing-standard)',
        'white-space': 'nowrap',
      },
    ),
    css('.forecast-chart__legend').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xxs) var(--space-md)',
        'margin-top': 'var(--space-xxs)',
      },
    ),
    css('.forecast-chart__key').styles(
      raw: {'align-items': 'center', 'display': 'flex', 'gap': '6px'},
    ),
    css('.forecast-chart__key::before').styles(
      raw: {'content': '""', 'flex': 'none', 'height': '0', 'width': '18px'},
    ),
    css('.forecast-chart__key--usual::before').styles(
      raw: {'border-top': '2.5px solid var(--color-text)'},
    ),
    css('.forecast-chart__key--plan::before').styles(
      raw: {'border-top': '2px dashed var(--color-accent)', 'opacity': '0.7'},
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css(
        '.forecast-chart__plot path, .forecast-chart__plot rect, '
        '.forecast-chart__dot, .forecast-chart__step-label',
      ).styles(raw: {'transition': 'none'}),
    ]),
  ];
}
