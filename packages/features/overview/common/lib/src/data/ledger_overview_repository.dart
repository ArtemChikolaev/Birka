import 'package:device_settings/device_settings.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:overview_common/src/domain/overview_repository.dart';
import 'package:rates/rates.dart';

/// Reads the first screen from the ledger.
final class LedgerOverviewRepository implements OverviewRepository {
  /// Creates a repository on [_ledger], [_rates], the choice of
  /// [_baseCurrency] and the day the months start on, [_monthStart].
  const LedgerOverviewRepository(
    this._ledger,
    this._rates,
    this._baseCurrency,
    this._monthStart,
  );

  final LedgerRepository _ledger;
  final RatesRepository _rates;
  final BaseCurrency _baseCurrency;
  final MonthStart _monthStart;

  @override
  Stream<List<AccountBalance>> watchAccounts() =>
      _ledger.watchAccountBalances();

  @override
  Stream<RateBook> watchRates() => _rates.watchRates();

  @override
  Stream<Currency?> watchBaseCurrency() => _baseCurrency.watch();

  @override
  int monthStart() => _monthStart.day;

  @override
  Stream<int> watchMonthStart() => _monthStart.watch();

  @override
  Stream<List<DayChange>> watchDayChanges({required CivilDate from}) =>
      _ledger.watchDayChanges(from: from);

  @override
  Stream<List<CategoryDayTotal>> watchSpending({
    required CivilDate from,
    required CivilDate to,
  }) => _ledger.watchCategoryDays(CategoryKind.expense, from: from, to: to);
}
