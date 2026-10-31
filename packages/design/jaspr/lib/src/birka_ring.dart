import 'dart:math';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A part of a [BirkaRing].
@immutable
final class RingSlice {
  /// Creates a part of [value] in [color].
  const RingSlice(this.value, this.color);

  /// How much the part is worth. Only its share of the ring matters.
  final double value;

  /// The color, as CSS.
  final String color;
}

/// A ring cut into [slices] by their shares, with an optional [child] in the
/// middle.
class BirkaRing extends StatelessComponent {
  /// Creates a ring. Screen readers read [label].
  const BirkaRing({
    required this.slices,
    required this.label,
    this.size = 96,
    this.thickness = 10,
    this.child,
    super.key,
  });

  /// The parts, clockwise from the top.
  final List<RingSlice> slices;

  /// What the ring shows, for screen readers.
  final String label;

  /// The width and the height in pixels.
  final int size;

  /// The width of the ring in pixels.
  final int thickness;

  /// What stands in the middle.
  final Component? child;

  /// The room between two parts, in radians.
  static const double _gap = 0.07;

  @override
  Component build(BuildContext context) {
    final child = this.child;
    return div(
      classes: 'birka-ring',
      styles: Styles(raw: {'height': '${size}px', 'width': '${size}px'}),
      [
        svg(
          classes: 'birka-ring__picture',
          viewBox: '0 0 $size $size',
          attributes: {'aria-label': label, 'role': 'img'},
          [
            _circle(classes: 'birka-ring__track'),
            ..._arcs(),
          ],
        ),
        if (child != null) div(classes: 'birka-ring__middle', [child]),
      ],
    );
  }

  double get _radius => (size - thickness) / 2;

  Component _circle({
    String? classes,
    Map<String, String> attributes = const {},
  }) {
    return circle(
      classes: classes,
      cx: '${size / 2}',
      cy: '${size / 2}',
      r: '$_radius',
      attributes: {
        'fill': 'none',
        'stroke-width': '$thickness',
        ...attributes,
      },
      const [],
    );
  }

  /// Every part as a dash along the circle, which also draws a whole ring.
  List<Component> _arcs() {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    if (total <= 0) return const [];
    final gap = slices.length > 1 ? _gap : 0.0;
    final radius = _radius;
    final middle = size / 2;
    final arcs = <Component>[];
    var start = 0.0;
    for (final slice in slices) {
      final sweep = 2 * pi * slice.value / total;
      if (sweep > gap) {
        arcs.add(
          _circle(
            attributes: {
              'stroke': slice.color,
              'stroke-dasharray':
                  '${(sweep - gap) * radius} ${2 * pi * radius}',
              'stroke-dashoffset': '${-(start + gap / 2) * radius}',
              'transform': 'rotate(-90 $middle $middle)',
            },
          ),
        );
      }
      start += sweep;
    }
    return arcs;
  }

  /// The styles of the ring.
  @css
  static List<StyleRule> get styles => [
    css('.birka-ring').styles(
      raw: {'flex': 'none', 'position': 'relative'},
    ),
    css('.birka-ring__picture').styles(
      raw: {'display': 'block', 'height': '100%', 'width': '100%'},
    ),
    css('.birka-ring__track').styles(
      raw: {'stroke': 'var(--color-surface-raised)'},
    ),
    css('.birka-ring__middle').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'inset': '0',
        'justify-content': 'center',
        'position': 'absolute',
      },
    ),
  ];
}
