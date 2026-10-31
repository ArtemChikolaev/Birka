import 'package:ledger/ledger.dart';
import 'package:overview_common/src/domain/overview_repository.dart';

/// Reads the first screen from the ledger.
final class LedgerOverviewRepository implements OverviewRepository {
  /// Creates a repository on [_ledger].
  const LedgerOverviewRepository(this._ledger);

  final LedgerRepository _ledger;

  @override
  Stream<List<AccountBalance>> watchAccounts() =>
      _ledger.watchAccountBalances();

  @override
  Stream<List<DayChange>> watchDayChanges({required CivilDate from}) =>
      _ledger.watchDayChanges(from: from);

  @override
  Stream<List<CategoryTotal>> watchSpending({
    required CivilDate from,
    required CivilDate to,
  }) => _ledger.watchCategoryTotals(CategoryKind.expense, from: from, to: to);
}
