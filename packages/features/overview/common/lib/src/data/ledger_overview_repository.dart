import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:overview_common/src/domain/overview_repository.dart';
import 'package:rates/rates.dart';

/// Reads the first screen from the ledger.
final class LedgerOverviewRepository implements OverviewRepository {
  /// Creates a repository on [_ledger], [_rates] and the choice of
  /// [_baseCurrency].
  const LedgerOverviewRepository(this._ledger, this._rates, this._baseCurrency);

  final LedgerRepository _ledger;
  final RatesRepository _rates;
  final BaseCurrency _baseCurrency;

  @override
  Stream<List<AccountBalance>> watchAccounts() =>
      _ledger.watchAccountBalances();

  @override
  Stream<RateBook> watchRates() => _rates.watchRates();

  @override
  Stream<Currency?> watchBaseCurrency() => _baseCurrency.watch();

  @override
  Stream<List<DayChange>> watchDayChanges({required CivilDate from}) =>
      _ledger.watchDayChanges(from: from);

  @override
  Stream<List<CategoryTotal>> watchSpending({
    required CivilDate from,
    required CivilDate to,
  }) => _ledger.watchCategoryTotals(CategoryKind.expense, from: from, to: to);
}
