import 'dart:async';

import 'package:money/money.dart';

/// The currency that totals are shown in, if one was picked. It changes no
/// stored amount, so it lives with the settings of the device (ADR 0012).
final class BaseCurrency {
  /// Creates the choice with [_value].
  BaseCurrency(this._value);

  Currency? _value;
  final _changes = StreamController<Currency?>.broadcast();

  /// The picked currency, or `null` to follow the first account.
  Currency? get value => _value;

  /// Picks [currency], or follows the first account with `null`.
  void choose(Currency? currency) {
    _value = currency;
    _changes.add(currency);
  }

  /// The choice now and every later one.
  Stream<Currency?> watch() => Stream.multi((controller) {
    controller.add(_value);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });
}
