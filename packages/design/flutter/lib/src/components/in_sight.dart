import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Holds a change back while the widget is out of sight, such as under a
/// sheet, on another tab or under another page, and plays it once the widget
/// shows again.
///
/// The widget is out of sight while its tickers stand still, and while a page
/// lies over its own page or over a page around it, such as the one that
/// holds the tabs, until that page has gone: a sheet leaves the page below
/// showing at its top, and keeps it ticking.
mixin InSight<T extends StatefulWidget> on State<T> {
  ValueListenable<bool>? _ticking;
  List<Animation<double>> _covers = const [];
  VoidCallback? _held;

  /// Whether the widget is in sight.
  bool get inSight =>
      (_ticking?.value ?? true) && _covers.every((cover) => cover.isDismissed);

  /// Plays [change] now if the widget is in sight, or once it shows again.
  /// A later change takes the place of one held back.
  void whenInSight(VoidCallback change) {
    if (inSight) {
      _held = null;
      change();
    } else {
      _held = change;
    }
  }

  /// Drops the change held back, if any.
  void forgetHeld() => _held = null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ticking = TickerMode.getNotifier(context);
    if (ticking != _ticking) {
      _ticking?.removeListener(_cameIntoSight);
      _ticking = ticking..addListener(_cameIntoSight);
    }
    final covers = _coversOf(context);
    if (!listEquals(covers, _covers)) {
      for (final cover in _covers) {
        cover.removeStatusListener(_coverMoved);
      }
      _covers = covers;
      for (final cover in covers) {
        cover.addStatusListener(_coverMoved);
      }
    }
  }

  /// How far the pages above cover the page of [context] and each page
  /// around it.
  static List<Animation<double>> _coversOf(BuildContext context) {
    final covers = <Animation<double>>[];
    for (var route = ModalRoute.of(context); route != null;) {
      if (route.secondaryAnimation case final cover?) covers.add(cover);
      final navigator = route.navigator;
      route = navigator == null ? null : ModalRoute.of(navigator.context);
    }
    return covers;
  }

  void _coverMoved(AnimationStatus status) {
    if (status.isDismissed) _cameIntoSight();
  }

  void _cameIntoSight() {
    final held = _held;
    if (held == null || !inSight || !mounted) return;
    _held = null;
    held();
  }

  @override
  void dispose() {
    _ticking?.removeListener(_cameIntoSight);
    for (final cover in _covers) {
      cover.removeStatusListener(_coverMoved);
    }
    super.dispose();
  }
}
