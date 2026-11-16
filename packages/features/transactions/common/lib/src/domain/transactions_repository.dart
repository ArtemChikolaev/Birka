import 'package:ledger/ledger.dart';
import 'package:transactions_common/src/domain/month_spending.dart';
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

  /// The operation that the ledger made from [receipt], if it did, so that a
  /// receipt goes in once (ADR 0032).
  Future<Operation?> operationOfReceipt(Receipt receipt);

  /// The latest transaction made from a receipt of the till whose fiscal
  /// drive is [drive], whose category its next receipt takes (ADR 0032).
  Future<Transaction?> lastOfTill(String drive);

  /// The expenses of the month that [day] falls in, as the month start sets
  /// it, with the rates that count them in the currency of a limit
  /// (ADR 0033).
  Future<MonthSpending> monthSpending(CivilDate day);
}
