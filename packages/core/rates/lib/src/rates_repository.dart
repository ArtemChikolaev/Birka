import 'package:database/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:money/money.dart';
import 'package:rates/src/rate_book.dart';
import 'package:rates/src/rate_source.dart';

/// Keeps the rates in the local database, which the screens read: without a
/// connection the last rates stay.
final class RatesRepository {
  /// Creates a repository on [_db].
  const RatesRepository(this._db);

  final BirkaDatabase _db;

  /// Every kept rate.
  Stream<RateBook> watchRates() =>
      _db.select(_db.exchangeRates).watch().map((rows) {
        final days = <String, Map<String, Decimal>>{};
        for (final row in rows) {
          (days[row.day] ??= {})[row.currency] = Decimal.parse(row.rubles);
        }
        return RateBook([
          for (final MapEntry(key: day, value: rubles) in days.entries)
            DayRates(CivilDate.parse(day), rubles),
        ]);
      });

  /// The day of the latest kept rates.
  Future<CivilDate?> latestDay() async {
    final latest = _db.exchangeRates.day.max();
    final row = await (_db.selectOnly(
      _db.exchangeRates,
    )..addColumns([latest])).getSingle();
    final day = row.read(latest);
    return day == null ? null : CivilDate.parse(day);
  }

  /// The days that have rates.
  Future<Set<CivilDate>> keptDays() async {
    final day = _db.exchangeRates.day;
    final rows = await (_db.selectOnly(
      _db.exchangeRates,
      distinct: true,
    )..addColumns([day])).get();
    return {for (final row in rows) CivilDate.parse(row.read(day)!)};
  }

  /// Keeps the rates of the currencies that Birka offers, over what the same
  /// day held. The others would only make every read longer.
  Future<void> keep(DayRates rates) {
    final offered = {for (final currency in offeredCurrencies) currency.code};
    return _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.exchangeRates, [
        for (final MapEntry(key: code, value: rubles) in rates.rubles.entries)
          if (offered.contains(code))
            ExchangeRatesCompanion.insert(
              day: rates.day.toString(),
              currency: code,
              rubles: rubles.toString(),
            ),
      ]);
    });
  }
}
