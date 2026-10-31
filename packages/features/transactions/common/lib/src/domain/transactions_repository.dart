import 'package:ledger/ledger.dart';

/// Where quick add reads its choices and writes what it records.
abstract interface class TransactionsRepository {
  /// The accounts in everyday use.
  Future<List<Account>> accounts();

  /// The categories of [kind] in everyday use, the frequent ones first.
  Future<List<Category>> categories(CategoryKind kind);

  /// The account of the latest transaction.
  Future<String?> lastAccountId();

  /// Puts [draft] into the ledger.
  Future<void> record(TransactionDraft draft);
}
