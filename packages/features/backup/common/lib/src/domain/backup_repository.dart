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

  /// Every operation, with the accounts and the categories that it names.
  Future<OperationsExport> operations();
}
