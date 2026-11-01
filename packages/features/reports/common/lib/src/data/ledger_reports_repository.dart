import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:reports_common/src/domain/reports_repository.dart';

/// Reads the reports from the ledger.
final class LedgerReportsRepository implements ReportsRepository {
  /// Creates a repository on [_ledger], [_rates] and the choice of
  /// [_baseCurrency].
  const LedgerReportsRepository(this._ledger, this._rates, this._baseCurrency);

  final LedgerRepository _ledger;
  final RatesRepository _rates;
  final BaseCurrency _baseCurrency;

  @override
  Stream<Currency?> watchMainCurrency() => _ledger.watchAccounts().map(
    (accounts) => accounts
        .where((account) => account.includeInTotals)
        .firstOrNull
        ?.currency,
  );

  @override
  Stream<Currency?> watchBaseCurrency() => _baseCurrency.watch();

  @override
  Stream<RateBook> watchRates() => _rates.watchRates();

  @override
  Stream<List<CategoryDayTotal>> watchDays(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  }) => _ledger.watchCategoryDays(kind, from: from, to: to);

  @override
  Future<List<CivilDate>> months() => _ledger.months();
}
