import 'package:design_flutter/src/components/in_sight.dart';
import 'package:flutter/widgets.dart';

/// Builds with [value] while it is in sight. Out of sight, such as under the
/// sheet of a form or on another tab, it keeps building with the value it
/// had, and the latest one comes in once it shows again ([InSight]): a
/// payment saved in a form opens its row in front of the person, once the
/// sheet has gone, instead of behind the sheet.
///
/// [onShown] hears each value that came in, with the one before it, after
/// the frame that shows it, so that a toast can say what happened.
class HeldOutOfSight<T> extends StatefulWidget {
  /// Creates the part of a page that shows [value].
  const HeldOutOfSight({
    required this.value,
    required this.builder,
    this.onShown,
    super.key,
  });

  /// What there is now.
  final T value;

  /// Builds the part of the page with what it shows.
  final Widget Function(BuildContext context, T value) builder;

  /// Hears what the part showed before and what it shows now.
  final void Function(T before, T now)? onShown;

  @override
  State<HeldOutOfSight<T>> createState() => _HeldOutOfSightState<T>();
}

class _HeldOutOfSightState<T> extends State<HeldOutOfSight<T>> with InSight {
  late T _shown = widget.value;

  @override
  void didUpdateWidget(HeldOutOfSight<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.value, _shown)) return forgetHeld();
    if (inSight) {
      forgetHeld();
      return _show(widget.value);
    }
    whenInSight(() => setState(() => _show(widget.value)));
  }

  // Takes [value] on, and tells [HeldOutOfSight.onShown] after the frame:
  // nothing comes into the overlay, as a toast does, while a page builds.
  void _show(T value) {
    final before = _shown;
    if (identical(before, value)) return;
    _shown = value;
    final onShown = widget.onShown;
    if (onShown == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) onShown(before, value);
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _shown);
}
