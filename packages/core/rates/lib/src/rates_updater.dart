import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/src/base_currency.dart';
import 'package:rates/src/rate_source.dart';
import 'package:rates/src/rates_repository.dart';

/// Brings rates into the local database. It runs beside the screens and never
/// in their way, and it stays well within the terms of the source (ADR 0012).
final class RatesUpdater {
  /// Creates an updater. [now] tells the time and [gap] the pause between two
  /// requests in tests.
  RatesUpdater(
    this._rates,
    this._source,
    this._ledger,
    this._baseCurrency, {
    DateTime Function()? now,
    Duration gap = const Duration(seconds: 2),
  }) : _now = now ?? DateTime.now,
       _gap = gap;

  final RatesRepository _rates;
  final RateSource _source;
  final LedgerRepository _ledger;
  final BaseCurrency _baseCurrency;
  final DateTime Function() _now;
  final Duration _gap;
  var _running = false;

  /// How many requests for old rates one run makes. What is left waits for the
  /// next launch.
  static const _requestsPerRun = 25;

  /// How far back a day without rates looks: the longest holidays of the Bank
  /// of Russia are shorter than this.
  static const _daysBack = 12;

  /// Fetches the latest rates unless today already has them, and then the rates
  /// of the days that a report needs. Without a connection what is kept stays,
  /// and the next run tries again.
  Future<void> refresh() async {
    if (_running) return;
    _running = true;
    try {
      await _fetchLatest();
      await _fetchHistory();
    } on Exception {
      return;
    } finally {
      _running = false;
    }
  }

  Future<void> _fetchLatest() async {
    final latest = await _rates.latestDay();
    if (latest != null && latest.compareTo(CivilDate.of(_now())) >= 0) return;
    await _rates.keep(await _source.latest());
  }

  /// Fetches what the operations outside the currency of the totals need, the
  /// latest days first. A day that the Bank of Russia skipped keeps the rates
  /// of the last day before it, so that it is never asked for again. A day with
  /// nothing that far back means that the source is out of reach or that its
  /// history ends there, and older days would fare no better.
  Future<void> _fetchHistory() async {
    final target = _baseCurrency.value ?? await _firstCurrency();
    if (target == null) return;
    final kept = await _rates.keptDays();
    final today = CivilDate.of(_now());
    var requests = 0;
    days:
    for (final day in await _ledger.daysOutside(target)) {
      if (kept.contains(day) || day.compareTo(today) > 0) continue;
      for (var back = 0; back <= _daysBack; back++) {
        if (requests == _requestsPerRun) return;
        requests++;
        await Future<void>.delayed(_gap);
        final rates = await _source.on(_before(day, back));
        if (rates == null) continue;
        await _rates.keep(DayRates(day, rates.rubles));
        continue days;
      }
      return;
    }
  }

  Future<Currency?> _firstCurrency() async {
    final accounts = await _ledger.watchAccounts().first;
    return accounts
        .where((account) => account.includeInTotals)
        .firstOrNull
        ?.currency;
  }

  static CivilDate _before(CivilDate day, int back) =>
      CivilDate.of(DateTime.utc(day.year, day.month, day.day - back));
}
