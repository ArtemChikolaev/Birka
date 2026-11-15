import 'dart:async';

import 'package:home_screen/src/home_screen.dart';
import 'package:home_screen/src/widget_snapshot.dart';
import 'package:home_screen/src/widget_sums.dart';

/// The figures that the widgets show, kept for the page of the widgets and
/// handed to the [HomeScreen] when they change (ADR 0031). While [_sums]
/// hides the amounts, only dots leave the app, and a turn of the switch
/// hands the figures over again. A demo keeps them to itself, with
/// [forwards] off: its money is not the person's.
final class HomeWidgets {
  /// Creates the figures of [_screen], whose amounts [_sums] shows or hides.
  HomeWidgets(this._screen, this._sums, {this.forwards = true}) {
    _turns = _sums.watch().skip(1).listen((_) => unawaited(_forward()));
  }

  final HomeScreen _screen;
  final WidgetSums _sums;
  late final StreamSubscription<bool> _turns;

  /// Whether the widgets of the phone get the figures.
  final bool forwards;

  WidgetSnapshot? _last;
  final _changes = StreamController<WidgetSnapshot>.broadcast();

  /// The figures shown last, the amounts as they are, or `null` before the
  /// first.
  WidgetSnapshot? get last => _last;

  /// Shows [snapshot], unless the widgets show it already.
  Future<void> show(WidgetSnapshot snapshot) async {
    if (snapshot == _last) return;
    _last = snapshot;
    _changes.add(snapshot);
    await _forward();
  }

  Future<void> _forward() async {
    final last = _last;
    if (!forwards || last == null) return;
    await _screen.show(_sums.shown ? last : last.masked());
  }

  /// The figures now, once there are any, and every later change.
  Stream<WidgetSnapshot> watch() => Stream.multi((controller) {
    if (_last case final last?) controller.add(last);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = () => unawaited(subscription.cancel());
  });

  /// Lets the watchers go.
  Future<void> close() async {
    await _turns.cancel();
    await _changes.close();
  }
}
