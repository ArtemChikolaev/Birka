import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Holds a change back while the widget is out of sight, such as under a
/// sheet, on another tab or under another page, where its tickers stand
/// still, and plays it once the widget shows again.
mixin InSight<T extends StatefulWidget> on State<T> {
  ValueListenable<bool>? _inSight;
  VoidCallback? _held;

  /// Whether the widget is in sight.
  bool get inSight => _inSight?.value ?? true;

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
    final inSight = TickerMode.getNotifier(context);
    if (inSight != _inSight) {
      _inSight?.removeListener(_cameIntoSight);
      _inSight = inSight..addListener(_cameIntoSight);
    }
  }

  void _cameIntoSight() {
    final held = _held;
    if (held == null || !inSight || !mounted) return;
    _held = null;
    held();
  }

  @override
  void dispose() {
    _inSight?.removeListener(_cameIntoSight);
    super.dispose();
  }
}
