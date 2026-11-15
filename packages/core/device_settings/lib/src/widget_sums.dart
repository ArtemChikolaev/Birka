import 'dart:async';

/// Whether the widgets of the home screen show amounts, which the widgets
/// follow as it changes. It lives with the settings of the device
/// (ADR 0031).
final class WidgetSums {
  /// Creates the choice, [shown] or not.
  WidgetSums({required bool shown}) : _shown = shown;

  bool _shown;
  final _changes = StreamController<bool>.broadcast();

  /// Whether the amounts are shown now.
  bool get shown => _shown;

  /// Shows the amounts, or hides them behind dots.
  void show({required bool shown}) {
    if (shown == _shown) return;
    _shown = shown;
    _changes.add(shown);
  }

  /// The choice now and every later one.
  Stream<bool> watch() => Stream.multi((controller) {
    controller.add(_shown);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = () => unawaited(subscription.cancel());
  });
}
