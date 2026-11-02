import 'package:backup_common/src/domain/backup_repository.dart';
import 'package:backup_common/src/domain/operations_csv.dart';
import 'package:ledger/ledger.dart';

/// Reads and replaces the ledger through its repository, which keeps the
/// rules.
final class LedgerBackupRepository implements BackupRepository {
  /// Creates a repository on [_ledger].
  const LedgerBackupRepository(this._ledger);

  final LedgerRepository _ledger;

  @override
  Stream<LedgerCounts> watchCounts() => _ledger.watchCounts();

  @override
  Future<LedgerCopy> copy() => _ledger.copy();

  @override
  Future<void> restore(LedgerCopy copy) => _ledger.restore(copy);

  @override
  Future<void> wipe() => _ledger.wipe();

  @override
  Future<OperationsExport> operations() async => OperationsExport(
    transactions: await _ledger.watchTransactions(limit: null).first,
    accounts: await _ledger.watchAccounts(includeArchived: true).first,
    categories: [
      for (final kind in CategoryKind.values)
        ...await _ledger.watchCategories(kind, includeArchived: true).first,
    ],
  );
}
