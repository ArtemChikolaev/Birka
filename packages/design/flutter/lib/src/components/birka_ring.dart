import 'dart:math';

import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:flutter/widgets.dart';

/// A part of a [BirkaRing].
@immutable
final class RingSlice {
  /// Creates a part of [value] in [color].
  const RingSlice(this.value, this.color);

  /// How much the part is worth. Only its share of the ring matters.
  final double value;

  /// The color.
  final Color color;
}

/// A ring cut into [slices] by their shares.
class BirkaRing extends StatelessWidget {
  /// Creates a ring. Screen readers read [label].
  const BirkaRing({
    required this.slices,
    required this.label,
    this.size = 96,
    super.key,
  });

  /// The parts, clockwise from the top.
  final List<RingSlice> slices;

  /// What the ring shows, for screen readers.
  final String label;

  /// The width and the height.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: label,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            slices: slices,
            track: BirkaColors.of(context).surfaceRaised,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.slices, required this.track});

  static const double _thickness = 10;

  /// The room between two parts, in radians.
  static const double _gap = 0.07;

  final List<RingSlice> slices;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - _thickness) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _thickness;
    canvas.drawOval(ring, paint..color = track);

    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    if (total <= 0) return;
    final gap = slices.length > 1 ? _gap : 0.0;
    var start = -pi / 2;
    for (final slice in slices) {
      final sweep = 2 * pi * slice.value / total;
      if (sweep > gap) {
        canvas.drawArc(
          ring,
          start + gap / 2,
          sweep - gap,
          false,
          paint..color = slice.color,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      track != oldDelegate.track || slices != oldDelegate.slices;
}
