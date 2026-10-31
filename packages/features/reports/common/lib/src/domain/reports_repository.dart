import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// Where the reports read what they show.
abstract interface class ReportsRepository {
  /// The currency of the first account that counts towards the totals.
  Stream<Currency?> watchMainCurrency();

  /// What went through the categories of [kind] from [from] to [to], the
  /// biggest of each currency first.
  Stream<List<CategoryTotal>> watchTotals(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  });

  /// What went through the categories of [kind] in each month from [from] to
  /// [to].
  Stream<List<MonthTotal>> watchMonthTotals(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  });

  /// The first days of the months with operations, the latest first.
  Future<List<CivilDate>> months();
}
