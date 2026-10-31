import 'package:accounts_common/src/domain/account_draft.dart';
import 'package:accounts_common/src/domain/accounts_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// Keeps the accounts in the ledger, which holds their rules.
final class LedgerAccountsRepository implements AccountsRepository {
  /// Creates a repository on [_ledger]. [now] tells the time in tests.
  LedgerAccountsRepository(this._ledger, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final LedgerRepository _ledger;
  final DateTime Function() _now;

  @override
  Stream<List<AccountBalance>> watchAccounts() =>
      _ledger.watchAccountBalances(includeArchived: true);

  @override
  Future<AccountBalance?> account(String id) async {
    final account = await _ledger.account(id);
    if (account == null) return null;
    return AccountBalance(account, await _ledger.balance(id));
  }

  @override
  Future<void> add(AccountDraft draft) => _ledger.addAccount(
    name: draft.name,
    type: draft.type,
    openingBalance: draft.balance ?? Money.zero(draft.currency),
    lastDigits: draft.lastDigits,
    art: draft.art,
    includeInTotals: draft.includeInTotals,
  );

  @override
  Future<void> update(String id, AccountDraft draft) =>
      _ledger.atomically(() async {
        await _ledger.updateAccount(
          id,
          name: draft.name,
          type: draft.type,
          lastDigits: Value(draft.lastDigits),
          art: draft.art,
          includeInTotals: draft.includeInTotals,
        );
        final balance = draft.balance;
        if (balance == null) return;
        final change = balance - await _ledger.balance(id);
        if (change.isZero) return;
        final now = _now();
        await _ledger.record(
          TransactionDraft.adjustment(
            accountId: id,
            change: change,
            occurredOn: CivilDate.of(now),
            occurredAt: now,
          ),
        );
      });

  @override
  Future<void> setArchived(String id, {required bool archived}) =>
      _ledger.updateAccount(id, archived: archived);
}
