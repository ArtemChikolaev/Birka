import 'dart:async';

import 'package:design_flutter/src/components/slide_switcher.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Lets a sideways swipe over [child] turn to the previous or the next of
/// something, such as a month: a swipe toward the end of the line, as when
/// turning back a page, calls [onPrevious], and one toward its start calls
/// [onNext].
///
/// While the finger moves, a [SlideSwitcher] below that follows the swipe
/// moves a little with it, and it goes back once the finger lets go.
class SwipeBetween extends StatefulWidget {
  /// Creates a place to swipe over [child].
  const SwipeBetween({
    required this.child,
    this.onPrevious,
    this.onNext,
    super.key,
  });

  /// What can be swiped over.
  final Widget child;

  /// Called by a swipe toward the end of the line.
  final VoidCallback? onPrevious;

  /// Called by a swipe toward the start of the line.
  final VoidCallback? onNext;

  /// How far the finger has gone toward the end of the line over the nearest
  /// [SwipeBetween] above [context], or `null` without one.
  static ValueListenable<double>? dragOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_Dragged>()?.drag;

  @override
  State<SwipeBetween> createState() => _SwipeBetweenState();
}

class _SwipeBetweenState extends State<SwipeBetween>
    with SingleTickerProviderStateMixin {
  /// How far the finger goes, or how fast, to turn.
  static const double _far = 48;
  static const double _fast = 500;

  final _drag = ValueNotifier<double>(0);

  /// Where the finger let go, which the drag goes back from.
  double _letGo = 0;

  late final AnimationController _back;

  @override
  void initState() {
    super.initState();
    _back = AnimationController(vsync: this, duration: BirkaMotion.base)
      ..addListener(_goBack);
  }

  void _goBack() => _drag.value =
      _letGo * (1 - BirkaMotion.standardCurve.transform(_back.value));

  /// 1 when the line runs to the right, -1 when it runs to the left.
  double get _end => Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  void _moved(DragUpdateDetails details) {
    _back.stop();
    _drag.value += (details.primaryDelta ?? 0) * _end;
  }

  void _ended(DragEndDetails details) {
    final speed = (details.primaryVelocity ?? 0) * _end;
    final gone = _drag.value;
    if (gone >= _far || speed >= _fast) {
      widget.onPrevious?.call();
    } else if (gone <= -_far || speed <= -_fast) {
      widget.onNext?.call();
    }
    _letGo = gone;
    unawaited(_back.forward(from: 0));
  }

  /// Goes back without turning, such as when another gesture takes over.
  void _cancelled() {
    _letGo = _drag.value;
    unawaited(_back.forward(from: 0));
  }

  @override
  void dispose() {
    _back.dispose();
    _drag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _moved,
      onHorizontalDragEnd: _ended,
      onHorizontalDragCancel: _cancelled,
      child: _Dragged(drag: _drag, child: widget.child),
    );
  }
}

class _Dragged extends InheritedWidget {
  const _Dragged({required this.drag, required super.child});

  final ValueListenable<double> drag;

  @override
  bool updateShouldNotify(_Dragged oldWidget) => drag != oldWidget.drag;
}
