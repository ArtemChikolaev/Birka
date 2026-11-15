import 'dart:async';

import 'package:home_screen/src/home_screen.dart';
import 'package:home_screen/src/widget_snapshot.dart';

/// The figures that the widgets show, kept for the page of the widgets and
/// handed to the [HomeScreen] when they change (ADR 0031). A demo keeps them
/// to itself, with [forwards] off: its money is not the person's.
final class HomeWidgets {
  /// Creates the figures of [_screen].
  HomeWidgets(this._screen, {this.forwards = true});

  final HomeScreen _screen;

  /// Whether the widgets of the phone get the figures.
  final bool forwards;

  WidgetSnapshot? _last;
  final _changes = StreamController<WidgetSnapshot>.broadcast();

  /// The figures shown last, or `null` before the first.
  WidgetSnapshot? get last => _last;

  /// Shows [snapshot], unless the widgets show it already.
  Future<void> show(WidgetSnapshot snapshot) async {
    if (snapshot == _last) return;
    _last = snapshot;
    _changes.add(snapshot);
    if (forwards) await _screen.show(snapshot);
  }

  /// The figures now, once there are any, and every later change.
  Stream<WidgetSnapshot> watch() => Stream.multi((controller) {
    if (_last case final last?) controller.add(last);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = () => unawaited(subscription.cancel());
  });

  /// Lets the watchers go.
  Future<void> close() => _changes.close();
}
