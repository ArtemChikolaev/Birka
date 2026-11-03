import 'package:design_flutter/src/components/swipe_between.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
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
class SlideSwitcher extends StatefulWidget {
  /// Creates a switcher of [child].
  const SlideSwitcher({
    required this.value,
    required this.child,
    this.distance = 48,
    this.follow = false,
    super.key,
  });

  /// What [child] stands for, such as its month. The order of values tells
  /// where a new child comes from.
  final Comparable<Object?> value;

  /// What is shown.
  final Widget child;

  /// How far a child moves as it comes and goes.
  final double distance;

  /// Whether the child follows a swipe while the finger moves.
  final bool follow;

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
    final current = ValueKey<Object?>(widget.value);
    final switcher = AnimatedSwitcher(
      duration: _wait + BirkaMotion.slow,
      reverseDuration: BirkaMotion.base,
      layoutBuilder: (current, previous) =>
          Stack(children: [...previous, ?current]),
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final coming = child!.key == current;
          final (offset, opacity) = coming
              ? _coming(animation.value)
              : _going(animation.value);
          return IgnorePointer(
            ignoring: !coming,
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(reduced ? 0 : offset * end, 0),
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
      builder: (context, gone, child) => Transform.translate(
        offset: Offset((gone / 2).clamp(-most, most) * end, 0),
        child: child,
      ),
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
