import 'package:accounts_common/src/domain/account_draft.dart';
import 'package:ledger/ledger.dart';

/// Where the feature keeps its accounts.
abstract interface class AccountsRepository {
  /// The accounts with their balances, archived ones included, in their
  /// order.
  Stream<List<AccountBalance>> watchAccounts();

  /// The account [id], if it exists.
  Future<Account?> account(String id);

  /// Adds an account after the others.
  Future<void> add(AccountDraft draft);

  /// Changes account [id]. Its currency stays as it is.
  Future<void> update(String id, AccountDraft draft);

  /// Hides account [id] from everyday lists, or brings it back.
  Future<void> setArchived(String id, {required bool archived});
}
