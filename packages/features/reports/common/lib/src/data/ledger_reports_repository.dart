import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:reports_common/src/domain/reports_repository.dart';

/// Reads the reports from the ledger.
final class LedgerReportsRepository implements ReportsRepository {
  /// Creates a repository on [_ledger].
  const LedgerReportsRepository(this._ledger);

  final LedgerRepository _ledger;

  @override
  Stream<Currency?> watchMainCurrency() => _ledger.watchAccounts().map(
    (accounts) => accounts
        .where((account) => account.includeInTotals)
        .firstOrNull
        ?.currency,
  );

  @override
  Stream<List<CategoryTotal>> watchTotals(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  }) => _ledger.watchCategoryTotals(kind, from: from, to: to);

  @override
  Stream<List<MonthTotal>> watchMonthTotals(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  }) => _ledger.watchMonthTotals(kind, from: from, to: to);

  @override
  Future<List<CivilDate>> months() => _ledger.months();
}
