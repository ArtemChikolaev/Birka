import 'dart:async';

/// The day of the calendar that a month of the overview and the reports
/// starts on, from 1 to 28, which the screens follow as it changes. It lives
/// with the settings of the device (ADR 0024).
final class MonthStart {
  /// Creates the choice of [_day].
  MonthStart(this._day);

  int _day;
  final _changes = StreamController<int>.broadcast();

  /// The day picked now.
  int get day => _day;

  /// Starts the months on [day].
  void choose(int day) {
    if (day == _day) return;
    _day = day;
    _changes.add(day);
  }

  /// The day now and every later one.
  Stream<int> watch() => Stream.multi((controller) {
    controller.add(_day);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });
}
