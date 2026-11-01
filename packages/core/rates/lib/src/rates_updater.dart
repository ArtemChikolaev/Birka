import 'package:ledger/ledger.dart' show CivilDate;
import 'package:rates/src/rate_source.dart';
import 'package:rates/src/rates_repository.dart';

/// Brings new rates into the local database. It runs beside the screens and
/// never in their way.
final class RatesUpdater {
  /// Creates an updater. [now] tells the time in tests.
  RatesUpdater(this._rates, this._source, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final RatesRepository _rates;
  final RateSource _source;
  final DateTime Function() _now;

  /// Fetches the latest rates unless today already has them. Without a
  /// connection the last rates stay, and the next launch tries again.
  Future<void> refresh() async {
    final today = CivilDate.of(_now());
    final latest = await _rates.latestDay();
    if (latest != null && latest.compareTo(today) >= 0) return;
    try {
      await _rates.keep(await _source.latest());
    } on Exception {
      return;
    }
  }
}
