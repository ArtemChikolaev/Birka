import 'dart:async';

import 'package:accounts_common/accounts_common.dart';
import 'package:money/money.dart';

/// Keeps accounts in memory.
final class FakeAccountsRepository implements AccountsRepository {
  /// Creates a repository with [accounts].
  FakeAccountsRepository([List<AccountBalance> accounts = const []])
    : _accounts = [...accounts];

  final List<AccountBalance> _accounts;
  final _changes = StreamController<List<AccountBalance>>.broadcast();

  /// The drafts that were added.
  final added = <AccountDraft>[];

  /// The drafts that were saved over accounts, by id.
  final updated = <String, AccountDraft>{};

  /// The error of the next write.
  Exception? failure;

  /// Fails the stream of accounts.
  void failStream() => _changes.addError(Exception('broken'));

  /// Replaces the accounts.
  void emit(List<AccountBalance> accounts) {
    _accounts
      ..clear()
      ..addAll(accounts);
    _changes.add([..._accounts]);
  }

  @override
  Stream<List<AccountBalance>> watchAccounts() async* {
    yield [..._accounts];
    yield* _changes.stream;
  }

  @override
  Future<AccountBalance?> account(String id) async {
    for (final row in _accounts) {
      if (row.account.id == id) return row;
    }
    return null;
  }

  @override
  Future<void> add(AccountDraft draft) async {
    if (failure case final failure?) throw failure;
    added.add(draft);
  }

  @override
  Future<void> update(String id, AccountDraft draft) async {
    if (failure case final failure?) throw failure;
    updated[id] = draft;
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    if (failure case final failure?) throw failure;
    emit([
      for (final row in _accounts)
        if (row.account.id == id)
          AccountBalance(_withArchived(row.account, archived), row.balance)
        else
          row,
    ]);
  }
}

Account _withArchived(Account account, bool archived) => Account(
  id: account.id,
  name: account.name,
  type: account.type,
  openingBalance: account.openingBalance,
  includeInTotals: account.includeInTotals,
  archived: archived,
  sortOrder: account.sortOrder,
  lastDigits: account.lastDigits,
  art: account.art,
);

/// An account for tests.
Account account(
  String name,
  Money opening, {
  AccountType type = AccountType.debit,
  bool archived = false,
  bool includeInTotals = true,
  String? lastDigits,
}) => Account(
  id: name,
  name: name,
  type: type,
  openingBalance: opening,
  includeInTotals: includeInTotals,
  archived: archived,
  sortOrder: 0,
  lastDigits: lastDigits,
);
