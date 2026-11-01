import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:meta/meta.dart';

/// The rates of one day: how many rubles one unit of each currency cost.
@immutable
final class DayRates {
  /// Creates the rates of [day].
  const DayRates(this.day, this.rubles);

  /// The day the rates are set for.
  final CivilDate day;

  /// Rubles for one unit, by the code of the currency.
  final Map<String, Decimal> rubles;
}

/// Where the rates come from.
abstract interface class RateSource {
  /// The latest rates there are.
  Future<DayRates> latest();

  /// The rates set for [day], or `null` when that day has none, such as a
  /// Sunday.
  Future<DayRates?> on(CivilDate day);
}
