import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:design_flutter/src/components/in_sight.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:flutter/widgets.dart';

/// A part of a [BirkaRing].
@immutable
final class RingSlice {
  /// Creates a part of [value] in [color].
  const RingSlice(this.value, this.color, {this.id});

  /// How much the part is worth. Only its share of the ring matters.
  final double value;

  /// The color.
  final Color color;

  /// What the part stands for, such as the id of a category, so that it
  /// grows or shrinks to a new share in its place as the ring changes. Parts
  /// without one go by their place.
  final Object? id;
}

/// A ring cut into [slices] by their shares, with an optional [child] in the
/// middle.
///
/// When the shares change, the parts grow and shrink to their new ones over
/// `duration.roll`: a new part grows from nothing, and one that goes shrinks
/// to nothing. A change that comes while the ring is out of sight waits for
/// it to show again. The ring does not move the first time it shows, nor when
/// the system asks for less motion.
class BirkaRing extends StatefulWidget {
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
  State<BirkaRing> createState() => _BirkaRingState();
}

@immutable
final class _Part {
  const _Part(this.id, this.color, this.share);

  final Object id;
  final Color color;
  final double share;
}

class _BirkaRingState extends State<BirkaRing>
    with SingleTickerProviderStateMixin, InSight {
  // The parts the ring moves from, and those it shows once it settles.
  List<_Part> _from = const [];
  late List<_Part> _to = _partsOf(widget.slices);

  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: BirkaMotion.roll,
    value: 1,
  );

  @override
  void didUpdateWidget(BirkaRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _partsOf(widget.slices);
    if (_sameShares(next, _to)) {
      _to = next;
      return;
    }
    final from = _at(_moved);
    _to = next;
    forgetHeld();
    if (BirkaMotion.reduced(context)) {
      _move.value = 1;
      return;
    }
    _from = from;
    _move.value = 0;
    whenInSight(() => unawaited(_move.forward(from: 0)));
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  double get _moved => BirkaMotion.standardCurve.transform(_move.value);

  static List<_Part> _partsOf(List<RingSlice> slices) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    if (total <= 0) return const [];
    return [
      for (final (index, slice) in slices.indexed)
        _Part(slice.id ?? index, slice.color, slice.value / total),
    ];
  }

  static bool _sameShares(List<_Part> a, List<_Part> b) =>
      a.length == b.length &&
      [
        for (var i = 0; i < a.length; i++)
          a[i].id == b[i].id && (a[i].share - b[i].share).abs() < 1e-9,
      ].every((same) => same);

  /// The parts [moved] of the way from [_from] to [_to], in the new order,
  /// with each part that goes kept after the one it followed.
  List<_Part> _at(double moved) {
    final from = {for (final part in _from) part.id: part};
    final to = {for (final part in _to) part.id: part};
    final parts = [
      for (final part in _to)
        _Part(
          part.id,
          part.color,
          lerpDouble(from[part.id]?.share ?? 0, part.share, moved)!,
        ),
    ];
    for (final (index, part) in _from.indexed) {
      if (to.containsKey(part.id)) continue;
      final share = lerpDouble(part.share, 0, moved)!;
      final after = index == 0
          ? -1
          : parts.indexWhere((other) => other.id == _from[index - 1].id);
      parts.insert(after + 1, _Part(part.id, part.color, share));
    }
    return parts;
  }

  double _gapAt(double moved) => lerpDouble(_gapOf(_from), _gapOf(_to), moved)!;

  static double _gapOf(List<_Part> parts) =>
      parts.length > 1 ? _RingPainter.room : 0;

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final track = BirkaColors.of(context).surfaceRaised;
    final ring = Semantics(
      image: true,
      label: widget.label,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _move,
          builder: (context, _) {
            final moved = _moved;
            return CustomPaint(
              painter: _RingPainter(
                parts: _at(moved),
                gap: _gapAt(moved),
                thickness: widget.thickness,
                track: track,
              ),
            );
          },
        ),
      ),
    );
    if (child == null) return ring;
    return Stack(
      alignment: Alignment.center,
      children: [
        ring,
        SizedBox.square(
          dimension: widget.size - widget.thickness * 3,
          child: Center(child: child),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.parts,
    required this.gap,
    required this.thickness,
    required this.track,
  });

  /// The room between two parts, in radians.
  static const double room = 0.07;

  final List<_Part> parts;

  /// The room between the parts now, which grows from nothing as a second
  /// part comes and shrinks as the last but one goes.
  final double gap;
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

    var start = -pi / 2;
    for (final part in parts) {
      final sweep = 2 * pi * part.share;
      if (sweep > gap) {
        canvas.drawArc(
          ring,
          start + gap / 2,
          sweep - gap,
          false,
          paint..color = part.color,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => true;
}
