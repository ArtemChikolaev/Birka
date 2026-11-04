import 'package:inbox_common/src/domain/transfer_pairs.dart';
import 'package:ledger/ledger.dart';
import 'package:rates/rates.dart';

/// What the inbox needs of the ledger and its rates.
abstract interface class InboxRepository {
  /// Every transaction of the ledger, the latest first.
  Stream<List<Transaction>> watchTransactions();

  /// The accounts, archived ones included.
  Stream<List<Account>> watchAccounts();

  /// The categories of [kind], archived ones included.
  Stream<List<Category>> watchCategories(CategoryKind kind);

  /// The rates of the Bank of Russia that the ledger keeps.
  Stream<RateBook> watchRates();

  /// The past imports, the latest first.
  Stream<List<LedgerImport>> watchImports();

  /// Gives each transaction of [choices] its category, at once. A
  /// transaction keeps its import, so that the undo of it still takes the
  /// transaction out.
  Future<void> categorize(List<(Transaction, String)> choices);

  /// Puts one transfer between the accounts of [pair] in place of its two
  /// transactions, at once, and returns its id. The transfer is the person's
  /// own record and belongs to no import.
  Future<String> makeTransfer(TransferPair pair);
}
