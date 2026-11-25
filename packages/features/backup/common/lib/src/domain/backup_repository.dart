import 'package:backup_common/src/domain/operations_csv.dart';
import 'package:ledger/ledger.dart';

/// Where the data feature reads the ledger and replaces it.
abstract interface class BackupRepository {
  /// How much the ledger holds, again after every change.
  Stream<LedgerCounts> watchCounts();

  /// A copy of everything the ledger holds now.
  Future<LedgerCopy> copy();

  /// Puts [copy] in place of everything the ledger holds.
  Future<void> restore(LedgerCopy copy);

  /// Removes everything the ledger holds.
  Future<void> wipe();

  /// Operations within the inclusive dates, with their accounts and categories.
  Future<OperationsExport> operations({CivilDate? from, CivilDate? to});
}
