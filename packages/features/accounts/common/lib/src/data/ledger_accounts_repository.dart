import 'package:accounts_common/src/domain/account_draft.dart';
import 'package:accounts_common/src/domain/accounts_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ledger/ledger.dart';

/// Keeps the accounts in the ledger, which holds their rules.
final class LedgerAccountsRepository implements AccountsRepository {
  /// Creates a repository on [_ledger].
  const LedgerAccountsRepository(this._ledger);

  final LedgerRepository _ledger;

  @override
  Stream<List<AccountBalance>> watchAccounts() =>
      _ledger.watchAccountBalances(includeArchived: true);

  @override
  Future<Account?> account(String id) => _ledger.account(id);

  @override
  Future<void> add(AccountDraft draft) => _ledger.addAccount(
    name: draft.name,
    type: draft.type,
    openingBalance: draft.openingBalance,
    lastDigits: draft.lastDigits,
    art: draft.art,
    includeInTotals: draft.includeInTotals,
  );

  @override
  Future<void> update(String id, AccountDraft draft) => _ledger.updateAccount(
    id,
    name: draft.name,
    openingBalance: draft.openingBalance,
    lastDigits: Value(draft.lastDigits),
    art: draft.art,
    includeInTotals: draft.includeInTotals,
  );

  @override
  Future<void> setArchived(String id, {required bool archived}) =>
      _ledger.updateAccount(id, archived: archived);
}
