import 'dart:async';

import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A page for something new, such as an account or an operation.
///
/// On iOS it is the sheet of the system: the screen below steps back a little,
/// and a swipe down closes the sheet, as does a pull of its list past the top.
/// Elsewhere it is a full screen dialog.
class BirkaSheetPage<T> extends MaterialPage<T> {
  /// Creates the page of [child].
  const BirkaSheetPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(fullscreenDialog: true);

  @override
  Route<T> createRoute(BuildContext context) {
    return switch (Theme.of(context).platform) {
      TargetPlatform.iOS => CupertinoSheetRoute<T>(
        settings: this,
        builder: _childOfRoute,
      ),
      _ => super.createRoute(context),
    };
  }

  // Reads the page anew, so that a new page with the same key shows up.
  static Widget _childOfRoute(BuildContext context) => _PullToClose(
    child: (ModalRoute.of(context)!.settings as MaterialPage<Object?>).child,
  );
}

/// Closes the sheet when its list is pulled down past the top: the sheet of
/// Flutter 3.38 follows a swipe only where nothing scrolls.
class _PullToClose extends StatefulWidget {
  const _PullToClose({required this.child});

  final Widget child;

  @override
  State<_PullToClose> createState() => _PullToCloseState();
}

class _PullToCloseState extends State<_PullToClose> {
  // How far past its top the list has to go.
  static const double _distance = 80;

  bool _armed = false;
  bool _closing = false;

  bool _onScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (_closing || notification.depth != 0 || metrics.axis != Axis.vertical) {
      return false;
    }
    final dragging =
        notification is ScrollUpdateNotification &&
        notification.dragDetails != null;
    if (dragging) {
      _armed = metrics.minScrollExtent - metrics.pixels > _distance;
    } else if (_armed &&
        (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification)) {
      _armed = false;
      unawaited(_close());
    }
    return false;
  }

  Future<void> _close() async {
    _closing = true;
    final closed = await Navigator.of(context).maybePop();
    if (!closed && mounted) _closing = false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: widget.child,
    );
  }
}

/// A page for a change of what the screen below shows, such as the form of
/// an account over its page.
///
/// It fades in over the screen below, so whatever sits in the same place on
/// both, such as the card of the account, stays still, and [BirkaRise] lifts
/// the rest into place.
class BirkaFadePage<T> extends Page<T> {
  /// Creates the page of [child].
  const BirkaFadePage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// What the page shows.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _FadeRoute<T>(this);
}

class _FadeRoute<T> extends PageRoute<T> {
  _FadeRoute(BirkaFadePage<T> page) : super(settings: page);

  @override
  Duration get transitionDuration => BirkaMotion.slow;

  @override
  Duration get reverseTransitionDuration => BirkaMotion.base;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: (settings as BirkaFadePage<T>).child,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _RiseScope(
      animation: animation,
      child: FadeTransition(
        opacity: animation.drive(CurveTween(curve: BirkaMotion.fadeCurve)),
        child: child,
      ),
    );
  }
}

/// Lifts [child] into place as a [BirkaFadePage] opens and lowers it as the
/// page closes. Anywhere else, and when the system asks for less motion, the
/// child stays where it is.
class BirkaRise extends StatelessWidget {
  /// Lifts [child] by [offset], once [start] of the opening has passed.
  const BirkaRise({
    required this.child,
    this.offset = BirkaTokens.spaceXl,
    this.start = 0,
    super.key,
  });

  /// What rises.
  final Widget child;

  /// How far below its place the child starts.
  final double offset;

  /// The share of the opening, from 0 to 1, that passes before the rise.
  final double start;

  @override
  Widget build(BuildContext context) {
    final animation = context
        .dependOnInheritedWidgetOfExactType<_RiseScope>()
        ?.animation;
    if (animation == null || BirkaMotion.reduced(context)) return child;
    final rise = animation.drive(
      CurveTween(curve: Interval(start, 1, curve: BirkaMotion.standardCurve)),
    );
    return AnimatedBuilder(
      animation: rise,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, (1 - rise.value) * offset),
        child: child,
      ),
      child: child,
    );
  }
}

class _RiseScope extends InheritedWidget {
  const _RiseScope({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_RiseScope oldWidget) =>
      animation != oldWidget.animation;
}
