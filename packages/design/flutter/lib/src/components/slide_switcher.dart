import 'dart:math';

import 'package:design_flutter/src/components/swipe_between.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Shows [child], which stands for [value], and slides it out for a new one
/// when [value] changes, as a swipe between months does.
///
/// A value before the old one comes in from the start of the line and pushes
/// the old child toward the end; a value after it comes in from the end. The
/// old child moves [distance] as it fades over `duration.base`, and the new
/// one comes from [distance] away over `duration.slow`, a moment later. When
/// the system asks for less motion, they only cross-fade. With [follow], the
/// child also follows a swipe of a [SwipeBetween] above it by half the way,
/// up to half of [distance].
///
/// [SlideSwitcher.sliver] does the same with a sliver of a scroll view, such
/// as the days of a month, which goes on building its children as they
/// scroll into sight.
class SlideSwitcher extends StatefulWidget {
  /// Creates a switcher of [child].
  const SlideSwitcher({
    required this.value,
    required this.child,
    this.distance = 48,
    this.follow = false,
    super.key,
  }) : _sliver = false;

  /// Creates a switcher of [sliver], which stands in a scroll view.
  const SlideSwitcher.sliver({
    required this.value,
    required Widget sliver,
    this.distance = 48,
    this.follow = false,
    super.key,
  }) : child = sliver,
       _sliver = true;

  /// What [child] stands for, such as its month. The order of values tells
  /// where a new child comes from.
  final Comparable<Object?> value;

  /// What is shown.
  final Widget child;

  /// How far a child moves as it comes and goes.
  final double distance;

  /// Whether the child follows a swipe while the finger moves.
  final bool follow;

  /// Whether [child] is a sliver.
  final bool _sliver;

  @override
  State<SlideSwitcher> createState() => _SlideSwitcherState();
}

class _SlideSwitcherState extends State<SlideSwitcher> {
  /// A moment for the old child to make room before the new one comes.
  static final Duration _wait = BirkaMotion.fast ~/ 2;

  /// Which way the old child goes: 1 toward the end of the line, -1 toward
  /// its start.
  double _way = 1;

  @override
  void didUpdateWidget(SlideSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    final order = widget.value.compareTo(oldWidget.value);
    if (order != 0) _way = order < 0 ? 1 : -1;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = BirkaMotion.reduced(context);
    final end = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final sliver = widget._sliver;
    final current = ValueKey<Object?>(widget.value);
    final switcher = AnimatedSwitcher(
      duration: _wait + BirkaMotion.slow,
      reverseDuration: BirkaMotion.base,
      layoutBuilder: (current, previous) => sliver
          ? _SliverLayers(children: [...previous, ?current])
          : Stack(children: [...previous, ?current]),
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final coming = child!.key == current;
          final (offset, opacity) = coming
              ? _coming(animation.value)
              : _going(animation.value);
          final shift = reduced ? 0.0 : offset * end;
          if (sliver) {
            return SliverIgnorePointer(
              ignoring: !coming,
              sliver: SliverOpacity(
                opacity: opacity,
                sliver: _SliverShift(dx: shift, sliver: child),
              ),
            );
          }
          return IgnorePointer(
            ignoring: !coming,
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(shift, 0),
                child: child,
              ),
            ),
          );
        },
      ),
      child: KeyedSubtree(key: current, child: widget.child),
    );
    final drag = widget.follow ? SwipeBetween.dragOf(context) : null;
    if (drag == null || reduced) return switcher;
    final most = widget.distance / 2;
    return ValueListenableBuilder(
      valueListenable: drag,
      child: switcher,
      builder: (context, gone, child) {
        final shift = (gone / 2).clamp(-most, most) * end;
        return sliver
            ? _SliverShift(dx: shift, sliver: child!)
            : Transform.translate(offset: Offset(shift, 0), child: child);
      },
    );
  }

  /// Where the new child stands and how much it shows, [shown] of the way in.
  (double, double) _coming(double shown) {
    final whole = (_wait + BirkaMotion.slow).inMicroseconds;
    final start = _wait.inMicroseconds / whole;
    final moved = Interval(
      start,
      1,
      curve: BirkaMotion.standardCurve,
    ).transform(shown);
    final opacity = Interval(
      start,
      (_wait + BirkaMotion.base).inMicroseconds / whole,
      curve: BirkaMotion.fadeCurve,
    ).transform(shown);
    return (-_way * widget.distance * (1 - moved), opacity);
  }

  /// Where the old child stands and how much it shows, [shown] of the way
  /// still in.
  (double, double) _going(double shown) {
    final gone = 1 - shown;
    final faded = Interval(
      0,
      BirkaMotion.fast.inMicroseconds / BirkaMotion.base.inMicroseconds,
      curve: BirkaMotion.fadeCurve,
    ).transform(gone);
    return (
      _way * widget.distance * BirkaMotion.standardCurve.transform(gone),
      1 - faded,
    );
  }
}

/// Slivers in one place, each later one over the ones before, such as the
/// month that comes over the month that goes.
class _SliverLayers extends MultiChildRenderObjectWidget {
  const _SliverLayers({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSliverLayers();
}

class _LayerData extends SliverPhysicalParentData
    with ContainerParentDataMixin<RenderSliver> {}

class _RenderSliverLayers extends RenderSliver
    with ContainerRenderObjectMixin<RenderSliver, _LayerData> {
  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _LayerData) child.parentData = _LayerData();
  }

  @override
  void performLayout() {
    var scrollExtent = 0.0;
    var paintExtent = 0.0;
    var layoutExtent = 0.0;
    var maxPaintExtent = 0.0;
    var hitTestExtent = 0.0;
    var cacheExtent = 0.0;
    var overflows = false;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      child.layout(constraints, parentUsesSize: true);
      final layer = child.geometry!;
      if (layer.scrollOffsetCorrection case final correction?) {
        geometry = SliverGeometry(scrollOffsetCorrection: correction);
        return;
      }
      scrollExtent = max(scrollExtent, layer.scrollExtent);
      paintExtent = max(paintExtent, layer.paintExtent);
      layoutExtent = max(layoutExtent, layer.layoutExtent);
      maxPaintExtent = max(maxPaintExtent, layer.maxPaintExtent);
      hitTestExtent = max(hitTestExtent, layer.hitTestExtent);
      cacheExtent = max(cacheExtent, layer.cacheExtent);
      overflows = overflows || layer.hasVisualOverflow;
    }
    geometry = SliverGeometry(
      scrollExtent: scrollExtent,
      paintExtent: paintExtent,
      layoutExtent: layoutExtent,
      maxPaintExtent: maxPaintExtent,
      hitTestExtent: hitTestExtent,
      cacheExtent: cacheExtent,
      hasVisualOverflow: overflows,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (child.geometry!.visible) context.paintChild(child, offset);
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    for (var child = lastChild; child != null; child = childBefore(child)) {
      if (child.geometry!.hitTestExtent > 0 &&
          child.hitTest(
            result,
            mainAxisPosition: mainAxisPosition,
            crossAxisPosition: crossAxisPosition,
          )) {
        return true;
      }
    }
    return false;
  }

  @override
  double childMainAxisPosition(RenderSliver child) => 0;

  // Every layer stands where the layers do.
  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}
}

/// Moves [sliver] [dx] across its scroll view as it paints.
class _SliverShift extends SingleChildRenderObjectWidget {
  const _SliverShift({required this.dx, required Widget sliver})
    : super(child: sliver);

  final double dx;

  @override
  _RenderSliverShift createRenderObject(BuildContext context) =>
      _RenderSliverShift(dx);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSliverShift renderObject,
  ) => renderObject.dx = dx;
}

class _RenderSliverShift extends RenderProxySliver {
  _RenderSliverShift(this._dx);

  /// How far the sliver moves to the right, or down in a scroll view that
  /// runs sideways.
  double get dx => _dx;
  double _dx;
  set dx(double value) {
    if (value == _dx) return;
    _dx = value;
    markNeedsPaint();
    // Screen readers find the moved layer where it paints.
    markNeedsSemanticsUpdate();
  }

  /// The shift on the screen.
  Offset get _shift => switch (constraints.axis) {
    Axis.vertical => Offset(_dx, 0),
    Axis.horizontal => Offset(0, _dx),
  };

  /// The shift along the cross axis, which runs to the left in a right to
  /// left list.
  double get _across =>
      axisDirectionIsReversed(constraints.crossAxisDirection) ? -_dx : _dx;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null && child.geometry!.visible) {
      context.paintChild(child, offset + _shift);
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) => super.hitTestChildren(
    result,
    mainAxisPosition: mainAxisPosition,
    crossAxisPosition: crossAxisPosition - _across,
  );

  @override
  double childCrossAxisPosition(RenderSliver child) => _across;

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    super.applyPaintTransform(child, transform);
    transform.translateByDouble(_shift.dx, _shift.dy, 0, 1);
  }
}
