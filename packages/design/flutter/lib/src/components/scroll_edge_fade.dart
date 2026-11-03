import 'dart:math' as math;

import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// Fades the scroll view in [child] out at its top and bottom while more of
/// it lies past them, so that a list goes softly under a header or a button
/// that stays in place instead of breaking off at it.
///
/// An edge fades in over the first `size.scrollEdge` of scrolling towards it
/// and away as the end comes into view, so the first and the last rows show
/// in full.
class ScrollEdgeFade extends StatefulWidget {
  /// Fades the edges of the scroll view in [child].
  const ScrollEdgeFade({required this.child, super.key});

  /// The scroll view, or a widget around it.
  final Widget child;

  @override
  State<ScrollEdgeFade> createState() => _ScrollEdgeFadeState();
}

class _ScrollEdgeFadeState extends State<ScrollEdgeFade> {
  // How deep each edge fades, from 0 to 1.
  double _top = 0;
  double _bottom = 0;

  bool _onNotification(Notification notification) {
    final metrics = switch (notification) {
      ScrollUpdateNotification(depth: 0, :final metrics) ||
      ScrollMetricsNotification(depth: 0, :final metrics) => metrics,
      _ => null,
    };
    if (metrics == null || metrics.axis != Axis.vertical) return false;
    final top = _depthOf(metrics.extentBefore);
    final bottom = _depthOf(metrics.extentAfter);
    if (top != _top || bottom != _bottom) {
      setState(() {
        _top = top;
        _bottom = bottom;
      });
    }
    return false;
  }

  static double _depthOf(double extent) =>
      (extent / BirkaTokens.sizeScrollEdge).clamp(0, 1);

  static Shader _mask(
    Rect bounds, {
    required double top,
    required double bottom,
  }) {
    final edge = math.min(BirkaTokens.sizeScrollEdge / bounds.height, 0.5);
    const opaque = Color(0xFF000000);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        opaque.withValues(alpha: 1 - top),
        opaque,
        opaque,
        opaque.withValues(alpha: 1 - bottom),
      ],
      stops: [0, edge, 1 - edge, 1],
    ).createShader(bounds);
  }

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = (_top, _bottom);
    return NotificationListener<Notification>(
      onNotification: _onNotification,
      child: ShaderMask(
        // A new callback each time, so that the mask repaints.
        shaderCallback: (bounds) => _mask(bounds, top: top, bottom: bottom),
        blendMode: BlendMode.dstIn,
        child: widget.child,
      ),
    );
  }
}
