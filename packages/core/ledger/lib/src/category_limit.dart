import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// How much a category of expenses may take in a month (ADR 0033).
///
/// The limit has a currency of its own: the spending of the month in any
/// currency counts against it at the rate of the day of each operation.
@immutable
final class CategoryLimit {
  /// Creates a limit of [amount].
  const CategoryLimit(this.amount, {this.warnEarly = true});

  /// The most the category may take in a month, in the currency of the
  /// limit.
  final Money amount;

  /// Whether Birka says so once 80 % of the limit is gone.
  final bool warnEarly;

  @override
  bool operator ==(Object other) =>
      other is CategoryLimit &&
      other.amount == amount &&
      other.warnEarly == warnEarly;

  @override
  int get hashCode => Object.hash(amount, warnEarly);

  @override
  String toString() => 'CategoryLimit($amount, warnEarly: $warnEarly)';
}
