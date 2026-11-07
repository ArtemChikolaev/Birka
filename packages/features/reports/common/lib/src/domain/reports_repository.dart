import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Where the reports read what they show.
abstract interface class ReportsRepository {
  /// The currency of the first account that counts towards the totals.
  Stream<Currency?> watchMainCurrency();

  /// The currency picked for totals, if one was.
  Stream<Currency?> watchBaseCurrency();

  /// The day of the calendar that a month starts on now (ADR 0024).
  int monthStart();

  /// The day that a month starts on, now and after every change.
  Stream<int> watchMonthStart();

  /// The kept exchange rates.
  Stream<RateBook> watchRates();

  /// What went through the categories of [kind] on each day from [from] to
  /// [to]. Every day takes its own rate, so the sums have to wait for those.
  Stream<List<CategoryDayTotal>> watchDays(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  });

  /// The first days of the months with operations, the latest first, when
  /// months start on day [start].
  Future<List<CivilDate>> months({int start = 1});
}
