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

  /// The box the lines are drawn in; the chart stretches it to its width.
  static const double _width = 1000;
  static const double _height = 112;
  static const double _side = 8;
  static const double _top = 10;
  static const double _bottom = 16;

  @override
  Component build(BuildContext context) {
    final period = math.max(days, 1);
    final end = start - pace * period;
    final top = math.max(start, 0);
    final low = math.min(0, end);
    final range = math.max(top - low, 1);
    double x(num day) => _side + (_width - 2 * _side) * day / period;
    double y(num value) =>
        _top + (_height - _top - _bottom) * (top - value) / range;
    final short = end < 0;
    final cross = start <= 0 ? 0 : (short ? start / pace : period);
    double at(num day) => start - pace * day;
    String line(num a, num b, double from, double to) =>
        'M ${x(a).toStringAsFixed(1)} ${y(from).toStringAsFixed(1)} '
        'L ${x(b).toStringAsFixed(1)} ${y(to).toStringAsFixed(1)}';
    final zero = line(0, period, 0, 0);
    final plan = line(0, period, top.toDouble(), start > 0 ? 0 : start);
    final over = line(0, cross, start, at(cross));
    final under = line(cross, period, at(cross), end);
    return div(classes: 'forecast-chart', [
      div(
        classes: 'forecast-chart__plot',
        attributes: {'role': 'img', 'aria-label': label},
        [
          svg(
            viewBox: '0 0 $_width $_height',
            attributes: const {
              'preserveAspectRatio': 'none',
              'aria-hidden': 'true',
            },
            [
              _path(zero, 'forecast-chart__zero'),
              _path(plan, 'forecast-chart__plan'),
              _path(over, 'forecast-chart__usual'),
              if (short) _path(under, 'forecast-chart__under'),
            ],
          ),
          // The dot stays round however wide the chart is.
          if (short)
            span(
              classes: 'forecast-chart__dot',
              styles: Styles(
                raw: {
                  'left': '${(x(cross) / _width * 100).toStringAsFixed(2)}%',
                  'top':
                      '${(y(at(cross)) / _height * 100).toStringAsFixed(2)}%',
                },
              ),
              const [],
            ),
        ],
      ),
      div(classes: 'text-caption forecast-chart__ends', [
        span([.text(from)]),
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

  static Component _path(String d, String classes) => path(
    d: d,
    classes: classes,
    attributes: const {'vector-effect': 'non-scaling-stroke'},
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
    css('.forecast-chart__ends').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'display': 'flex',
        'justify-content': 'space-between',
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
      css('.forecast-chart__plot path, .forecast-chart__dot').styles(
        raw: {'transition': 'none'},
      ),
    ]),
  ];
}
