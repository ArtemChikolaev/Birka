import 'dart:math';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A line through [values] over a glow that fades out towards both sides, with
/// a dot on the last one. It takes the width of the page.
class BirkaLineChart extends StatelessComponent {
  /// Creates a chart. Screen readers read [label].
  const BirkaLineChart({required this.values, required this.label, super.key});

  /// The values, the earliest first. A chart needs at least two.
  final List<double> values;

  /// What the chart shows, for screen readers.
  final String label;

  /// The size of the drawing, which scales with the page.
  static const double _width = 360;
  static const double _height = 96;

  /// More points than this add nothing at this size.
  static const _maxPoints = 60;

  static const double _dot = 5;
  static const double _halo = 11;

  @override
  Component build(BuildContext context) {
    final points = values.length < 2 ? const <Point<double>>[] : _points();
    final line = _smooth(points);
    final last = points.lastOrNull;
    return svg(
      classes: 'birka-line-chart',
      viewBox: '0 0 ${_width.toInt()} ${_height.toInt()}',
      attributes: {'aria-label': label, 'role': 'img'},
      [
        if (last != null) ...[
          _gradients,
          path(
            classes: 'birka-line-chart__glow',
            d:
                '$line L${_number(last.x)} ${_height.toInt()} '
                'L${_number(points.first.x)} ${_height.toInt()} Z',
            attributes: const {'mask': 'url(#birka-line-fade)'},
            const [],
          ),
          path(classes: 'birka-line-chart__line', d: line, const []),
          circle(
            classes: 'birka-line-chart__halo',
            cx: _number(last.x),
            cy: _number(last.y),
            r: '${_halo.toInt()}',
            const [],
          ),
          circle(
            classes: 'birka-line-chart__dot',
            cx: _number(last.x),
            cy: _number(last.y),
            r: '${_dot.toInt()}',
            const [],
          ),
        ],
      ],
    );
  }

  /// The glow under the line, and what fades it out towards both sides.
  static Component get _gradients => const Component.element(
    tag: 'defs',
    children: [
      Component.element(
        tag: 'linearGradient',
        id: 'birka-line-glow',
        attributes: {'x1': '0', 'x2': '0', 'y1': '0', 'y2': '1'},
        children: [
          Component.element(
            tag: 'stop',
            classes: 'birka-line-chart__stop',
            attributes: {'offset': '0', 'stop-opacity': '0.28'},
          ),
          Component.element(
            tag: 'stop',
            classes: 'birka-line-chart__stop',
            attributes: {'offset': '1', 'stop-opacity': '0'},
          ),
        ],
      ),
      Component.element(
        tag: 'linearGradient',
        id: 'birka-line-sides',
        children: [
          Component.element(
            tag: 'stop',
            attributes: {
              'offset': '0',
              'stop-color': 'white',
              'stop-opacity': '0',
            },
          ),
          Component.element(
            tag: 'stop',
            attributes: {'offset': '0.7', 'stop-color': 'white'},
          ),
          Component.element(
            tag: 'stop',
            attributes: {
              'offset': '1',
              'stop-color': 'white',
              'stop-opacity': '0',
            },
          ),
        ],
      ),
      Component.element(
        tag: 'mask',
        id: 'birka-line-fade',
        children: [
          Component.element(
            tag: 'rect',
            attributes: {
              'fill': 'url(#birka-line-sides)',
              'height': '100%',
              'width': '100%',
            },
          ),
        ],
      ),
    ],
  );

  /// The values on the drawing, thinned out, with room for the dot on the last
  /// one. A line without any change runs through the middle.
  List<Point<double>> _points() {
    final step = (values.length / _maxPoints).ceil();
    final kept = [
      for (var i = 0; i < values.length - 1; i += step) values[i],
      values.last,
    ];
    final lowest = kept.reduce(min);
    final range = kept.reduce(max) - lowest;
    const height = _height - _halo * 2;
    const width = _width - _halo;
    return [
      for (final (index, value) in kept.indexed)
        Point(
          width * index / (kept.length - 1),
          _halo +
              (range == 0
                  ? height / 2
                  : height * (1 - (value - lowest) / range)),
        ),
    ];
  }

  /// A curve through [points] that never swings past its neighbors.
  String _smooth(List<Point<double>> points) {
    if (points.isEmpty) return '';
    final path = StringBuffer(
      'M${_number(points.first.x)} ${_number(points.first.y)}',
    );
    for (var i = 0; i < points.length - 1; i++) {
      final before = points[max(i - 1, 0)];
      final from = points[i];
      final to = points[i + 1];
      final after = points[min(i + 2, points.length - 1)];
      final low = min(from.y, to.y);
      final high = max(from.y, to.y);
      path
        ..write(' C${_number(from.x + (to.x - before.x) / 6)} ')
        ..write(_number((from.y + (to.y - before.y) / 6).clamp(low, high)))
        ..write(' ${_number(to.x - (after.x - from.x) / 6)} ')
        ..write(_number((to.y - (after.y - from.y) / 6).clamp(low, high)))
        ..write(' ${_number(to.x)} ${_number(to.y)}');
    }
    return path.toString();
  }

  static String _number(double value) => value.toStringAsFixed(1);

  /// The styles of the chart.
  @css
  static List<StyleRule> get styles => [
    css('.birka-line-chart').styles(
      raw: {'display': 'block', 'height': 'auto', 'width': '100%'},
    ),
    css('.birka-line-chart__stop').styles(
      raw: {'stop-color': 'var(--color-accent)'},
    ),
    css('.birka-line-chart__glow').styles(
      raw: {'fill': 'url(#birka-line-glow)'},
    ),
    css('.birka-line-chart__line').styles(
      raw: {
        'fill': 'none',
        'stroke': 'var(--color-accent)',
        'stroke-linecap': 'round',
        'stroke-linejoin': 'round',
        'stroke-width': '2.5',
      },
    ),
    css('.birka-line-chart__halo').styles(
      raw: {'fill': 'var(--color-accent)', 'fill-opacity': '0.2'},
    ),
    css('.birka-line-chart__dot').styles(raw: {'fill': 'var(--color-accent)'}),
  ];
}
