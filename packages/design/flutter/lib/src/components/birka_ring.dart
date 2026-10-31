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

/// A ring cut into [slices] by their shares, with an optional [child] in the
/// middle.
class BirkaRing extends StatelessWidget {
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

  /// The width and the height.
  final double size;

  /// The width of the ring.
  final double thickness;

  /// What stands in the middle.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final child = this.child;
    final ring = Semantics(
      image: true,
      label: label,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            slices: slices,
            thickness: thickness,
            track: BirkaColors.of(context).surfaceRaised,
          ),
        ),
      ),
    );
    if (child == null) return ring;
    return Stack(
      alignment: Alignment.center,
      children: [
        ring,
        SizedBox.square(
          dimension: size - thickness * 3,
          child: Center(child: child),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.slices,
    required this.thickness,
    required this.track,
  });

  /// The room between two parts, in radians.
  static const double _gap = 0.07;

  final List<RingSlice> slices;
  final double thickness;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - thickness) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
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
      track != oldDelegate.track ||
      thickness != oldDelegate.thickness ||
      slices != oldDelegate.slices;
}
