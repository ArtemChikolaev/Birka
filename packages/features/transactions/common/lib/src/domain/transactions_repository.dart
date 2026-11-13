import 'package:ledger/ledger.dart';
import 'package:transactions_common/src/domain/operation.dart';

/// Where the feature reads operations and the choices of quick add, and writes
/// what it records.
abstract interface class TransactionsRepository {
  /// The accounts in everyday use.
  Future<List<Account>> accounts();

  /// The categories of [kind] in everyday use, the frequent ones first.
  Future<List<Category>> categories(CategoryKind kind);

  /// The account of the latest transaction.
  Future<String?> lastAccountId();

  /// Puts [draft] into the ledger.
  Future<void> record(TransactionDraft draft);

  /// Every operation of the month that starts on [month], the latest first.
  Stream<List<Operation>> watchOperations(CivilDate month);

  /// The operations from [first] to [last], with both ends included, the
  /// latest first.
  Stream<List<Operation>> watchOperationsBetween(
    CivilDate first,
    CivilDate last,
  );

  /// Operation [id], and `null` while it does not exist.
  Stream<Operation?> watchOperation(String id);

  /// Account [id] with what it holds, and `null` while it does not exist.
  Stream<AccountBalance?> watchAccount(String id);

  /// What each day since [from] changed account [id].
  Stream<List<DayChange>> watchAccountChanges(
    String id, {
    required CivilDate from,
  });

  /// The latest operations of account [id], the latest first.
  Stream<List<Operation>> watchAccountOperations(String id);

  /// The operations that wear метка [id], the latest first (ADR 0027).
  Stream<List<Operation>> watchTagOperations(String id);

  /// The метки there are, which an operation can wear (ADR 0027).
  Future<List<Tag>> tags();

  /// The first days of the months with operations, the latest first.
  Future<List<CivilDate>> months();

  /// Replaces operation [id] with [draft].
  Future<void> amend(String id, TransactionDraft draft);

  /// Deletes operation [id].
  Future<void> delete(String id);
}
