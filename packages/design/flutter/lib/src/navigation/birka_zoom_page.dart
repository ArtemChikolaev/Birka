import 'dart:async';
import 'dart:math' as math;

import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A page that grows out of a card, such as the page of an account out of its
/// card on a list.
///
/// The card on the list is a [BirkaZoomSource], and the place of the card on
/// the page is a [BirkaZoomTarget]. As the page opens, the card flies into
/// that place and grows, the page fades in and rises, and the screen below
/// fades and steps back, while [BirkaGiveWay] takes its bar out of the way.
/// A swipe from the edge on iOS and the predictive back of Android play all
/// of it backwards under the finger. When the system asks for less motion,
/// the two screens only fade.
class BirkaZoomPage<T> extends Page<T> {
  /// Creates the page of [child], which grows out of the card with [tag].
  const BirkaZoomPage({
    required this.tag,
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The tag of the [BirkaZoomSource] that the page grows out of.
  final Object tag;

  /// What the page shows.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _ZoomRoute<T>(this);
}

class _ZoomRoute<T> extends PageRoute<T> {
  _ZoomRoute(BirkaZoomPage<T> page) : super(settings: page);

  @override
  Duration get transitionDuration => BirkaMotion.zoom;

  @override
  Duration get reverseTransitionDuration => BirkaMotion.slow;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _stepBack;

  static Widget _stepBack(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) => _StepBack(animation: secondaryAnimation, child: child);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final page = settings as BirkaZoomPage<T>;
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: _ZoomScope(tag: page.tag, child: page.child),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _BackGesture(
      route: this,
      child: _Grow(animation: animation, child: child),
    );
  }

  // A swipe back plays the opening backwards under the finger. Once let go,
  // the page finishes the way a page of iOS does, with the same numbers.

  void _startBack() => navigator!.didStartUserGesture();

  void _backTo(double value) {
    if (isCurrent) controller!.value = value;
  }

  void _endBack({required bool pop}) {
    final controller = this.controller!;
    const curve = Curves.fastLinearToSlowEaseIn;
    if (isCurrent) {
      if (pop) {
        navigator!.pop();
        if (controller.isAnimating) {
          unawaited(
            controller.animateBack(
              0,
              duration: Duration(
                milliseconds: (800 * controller.value).floor(),
              ),
              curve: curve,
            ),
          );
        }
      } else {
        unawaited(
          controller.animateTo(
            1,
            duration: Duration(
              milliseconds: math.min(
                (800 * (1 - controller.value)).floor(),
                300,
              ),
            ),
            curve: curve,
          ),
        );
      }
    }
    if (controller.isAnimating) {
      // The flight of the card follows the gesture until the page settles.
      late final AnimationStatusListener settled;
      settled = (status) {
        navigator?.didStopUserGesture();
        controller.removeStatusListener(settled);
      };
      controller.addStatusListener(settled);
    } else {
      navigator?.didStopUserGesture();
    }
  }
}

class _ZoomScope extends InheritedWidget {
  const _ZoomScope({required this.tag, required super.child});

  final Object tag;

  @override
  bool updateShouldNotify(_ZoomScope oldWidget) => tag != oldWidget.tag;
}

/// The page itself: it fades in and rises once a third of the opening has
/// passed, and fades out and sinks over the first half of the closing.
class _Grow extends StatefulWidget {
  const _Grow({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_Grow> createState() => _GrowState();
}

class _GrowState extends State<_Grow> {
  late CurvedAnimation _fade;
  late CurvedAnimation _rise;

  @override
  void initState() {
    super.initState();
    _follow();
  }

  @override
  void didUpdateWidget(_Grow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      _dispose();
      _follow();
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _follow() {
    _fade = CurvedAnimation(
      parent: widget.animation,
      curve: Interval(0.35, 1, curve: BirkaMotion.fadeCurve),
      reverseCurve: Interval(0.5, 1, curve: BirkaMotion.fadeCurve),
    );
    _rise = CurvedAnimation(
      parent: widget.animation,
      curve: Interval(0.35, 1, curve: BirkaMotion.standardCurve),
      reverseCurve: Interval(0.5, 1, curve: BirkaMotion.standardCurve.flipped),
    );
  }

  void _dispose() {
    _fade.dispose();
    _rise.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = FadeTransition(opacity: _fade, child: widget.child);
    if (BirkaMotion.reduced(context)) return page;
    return AnimatedBuilder(
      animation: _rise,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, (1 - _rise.value) * BirkaTokens.spaceMd),
        child: child,
      ),
      child: page,
    );
  }
}

/// The screen below a zoom page: it fades and steps back by the first 60% of
/// the opening, and comes back over the last 75% of the closing.
class _StepBack extends StatefulWidget {
  const _StepBack({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget? child;

  @override
  State<_StepBack> createState() => _StepBackState();
}

class _StepBackState extends State<_StepBack> {
  // How far the screen has gone, from 0 to 1.
  late CurvedAnimation _fade;
  late CurvedAnimation _move;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _follow();
  }

  @override
  void didUpdateWidget(_StepBack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      _dispose();
      _follow();
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _follow() {
    _fade = CurvedAnimation(
      parent: widget.animation,
      curve: Interval(0, 0.6, curve: BirkaMotion.fadeCurve),
      reverseCurve: Interval(0, 0.75, curve: BirkaMotion.fadeCurve),
    );
    _move = CurvedAnimation(
      parent: widget.animation,
      curve: Interval(0, 0.6, curve: BirkaMotion.standardCurve),
      reverseCurve: Interval(0, 0.75, curve: BirkaMotion.standardCurve.flipped),
    );
    _opacity = ReverseAnimation(_fade);
    _scale = _move.drive(Tween(begin: 1, end: 0.96));
  }

  void _dispose() {
    _fade.dispose();
    _move.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = BirkaMotion.reduced(context);
    return _ZoomBelow(
      away: _move,
      reduced: reduced,
      child: FadeTransition(
        opacity: _opacity,
        child: reduced
            ? widget.child
            : ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

/// Marks the screen below a zoom page.
class _ZoomBelow extends InheritedWidget {
  const _ZoomBelow({
    required this.away,
    required this.reduced,
    required super.child,
  });

  /// How far the screen has stepped back, from 0 to 1.
  final Animation<double> away;

  /// Whether the system asks for less motion.
  final bool reduced;

  @override
  bool updateShouldNotify(_ZoomBelow oldWidget) =>
      away != oldWidget.away || reduced != oldWidget.reduced;
}

/// Moves [child] out of the way by [offset] while a [BirkaZoomPage] opens over
/// its screen, and back as the page closes, such as the bar of the tabs,
/// which goes down. Anywhere else it stays where it is.
class BirkaGiveWay extends StatelessWidget {
  /// Moves [child] by [offset].
  const BirkaGiveWay({
    required this.child,
    this.offset = const Offset(0, BirkaTokens.spaceXl),
    super.key,
  });

  /// What moves.
  final Widget child;

  /// Where the child goes.
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final below = context.dependOnInheritedWidgetOfExactType<_ZoomBelow>();
    if (below == null || below.reduced) return child;
    final away = below.away;
    return AnimatedBuilder(
      animation: away,
      builder: (context, child) =>
          Transform.translate(offset: offset * away.value, child: child),
      child: child,
    );
  }
}

/// A card that opens a [BirkaZoomPage] with the same [tag] and grows into the
/// [BirkaZoomTarget] of that page.
///
/// It flies only into a zoom page that opens over its own screen, so a screen
/// that slides in or out with a card of the same tag leaves it where it is.
class BirkaZoomSource extends StatelessWidget {
  /// Ties [child] to the page that grows out of it.
  const BirkaZoomSource({required this.tag, required this.child, super.key});

  /// The tag of the page.
  final Object tag;

  /// The card.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: context.dependOnInheritedWidgetOfExactType<_ZoomBelow>() != null,
      child: _zoomHero(tag, child),
    );
  }
}

/// The place of the card on a [BirkaZoomPage]: the card of the screen below
/// flies into it as the page opens and out of it as the page closes.
///
/// A page that is still loading keeps the place empty at the size of the
/// card, since the card has to land somewhere. Anywhere else, and when the
/// system asks for less motion, it is just [child].
class BirkaZoomTarget extends StatelessWidget {
  /// Puts [child] in the place of the card.
  const BirkaZoomTarget({required this.child, super.key});

  /// The card, or an empty box of its size while the page loads.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ZoomScope>();
    if (scope == null) return child;
    return HeroMode(
      enabled: !BirkaMotion.reduced(context),
      child: _zoomHero(scope.tag, child),
    );
  }
}

Widget _zoomHero(Object tag, Widget child) => Hero(
  tag: _ZoomTag(tag),
  createRectTween: _straight,
  flightShuttleBuilder: _sourceCard,
  transitionOnUserGestures: true,
  child: child,
);

RectTween _straight(Rect? begin, Rect? end) =>
    RectTween(begin: begin, end: end);

/// Flies the card of the screen below either way, since the place on the page
/// may still wait for its card. The card lays itself out by the size that the
/// flight gives it, and takes the themes of its screen along, the style of
/// its text among them.
Widget _sourceCard(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final source = direction == HeroFlightDirection.push
      ? fromHeroContext
      : toHeroContext;
  return InheritedTheme.captureAll(source, (source.widget as Hero).child);
}

/// Keeps the tags of cards apart from the tags of any other hero.
@immutable
class _ZoomTag {
  const _ZoomTag(this.tag);

  final Object tag;

  @override
  bool operator ==(Object other) => other is _ZoomTag && other.tag == tag;

  @override
  int get hashCode => tag.hashCode;
}

/// Lets a swipe from the edge on iOS, and the predictive back of Android,
/// play the opening of a zoom page backwards.
class _BackGesture extends StatefulWidget {
  const _BackGesture({required this.route, required this.child});

  final _ZoomRoute<Object?> route;
  final Widget child;

  @override
  State<_BackGesture> createState() => _BackGestureState();
}

class _BackGestureState extends State<_BackGesture>
    with WidgetsBindingObserver {
  // How wide the edge is that a swipe starts from, as on any page of iOS.
  static const double _edge = 20;

  late final HorizontalDragGestureRecognizer _drag =
      HorizontalDragGestureRecognizer(debugOwner: this)
        ..onStart = _dragStarted
        ..onUpdate = _dragged
        ..onEnd = _dragEnded
        ..onCancel = _dragCancelled;

  // Whether a swipe back is under way, which the navigator has been told of.
  bool _swiping = false;

  _ZoomRoute<Object?> get _route => widget.route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _drag.dispose();
    // A page that goes away under the finger still ends the swipe.
    if (_swiping) {
      final navigator = _route.navigator;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator?.mounted ?? false) navigator!.didStopUserGesture();
      });
    }
    super.dispose();
  }

  void _start() {
    _swiping = true;
    _route._startBack();
  }

  void _end({required bool pop}) {
    if (!_swiping) return;
    _swiping = false;
    _route._endBack(pop: pop);
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent ||
        !_route.isCurrent ||
        !_route.popGestureEnabled) {
      return false;
    }
    _start();
    _route._backTo(1 - backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) =>
      _route._backTo(1 - backEvent.progress);

  @override
  void handleCommitBackGesture() => _end(pop: true);

  @override
  void handleCancelBackGesture() => _end(pop: false);

  // A swipe to the right goes back, or to the left in a language read from
  // the right.
  double get _forward =>
      Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  void _pointerDown(PointerDownEvent event) {
    if (_route.popGestureEnabled) _drag.addPointer(event);
  }

  void _dragStarted(DragStartDetails details) => _start();

  void _dragged(DragUpdateDetails details) => _route._backTo(
    _route.animation!.value -
        details.primaryDelta! / context.size!.width * _forward,
  );

  void _dragEnded(DragEndDetails details) {
    final velocity =
        details.velocity.pixelsPerSecond.dx / context.size!.width * _forward;
    _end(
      pop: velocity.abs() >= 1 ? velocity > 0 : _route.animation!.value < 0.5,
    );
  }

  // A touch of the edge that never became a swipe.
  void _dragCancelled() => _end(pop: _route.animation!.value < 0.5);

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.iOS) return widget.child;
    final padding = MediaQuery.paddingOf(context);
    final inset = Directionality.of(context) == TextDirection.rtl
        ? padding.right
        : padding.left;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          width: math.max(inset, _edge),
          top: 0,
          bottom: 0,
          child: Listener(
            onPointerDown: _pointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}
