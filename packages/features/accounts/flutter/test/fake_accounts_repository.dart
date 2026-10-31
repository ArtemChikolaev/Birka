import 'dart:async';

import 'package:accounts_common/accounts_common.dart';
import 'package:money/money.dart';

/// Keeps accounts in memory.
final class FakeAccountsRepository implements AccountsRepository {
  /// Creates a repository with [rows].
  FakeAccountsRepository([this.rows = const []]);

  /// The accounts.
  List<AccountBalance> rows;

  /// Whether reading the accounts fails.
  bool broken = false;

  /// The drafts that were added.
  final added = <AccountDraft>[];

  /// The drafts that were saved over accounts.
  final updated = <String, AccountDraft>{};

  /// The ids whose state of being archived changed, with the new state.
  final archived = <String, bool>{};

  @override
  Stream<List<AccountBalance>> watchAccounts() =>
      broken ? Stream.error(Exception('broken')) : Stream.value(rows);

  @override
  Future<AccountBalance?> account(String id) async {
    for (final row in rows) {
      if (row.account.id == id) return row;
    }
    return null;
  }

  @override
  Future<void> add(AccountDraft draft) async => added.add(draft);

  @override
  Future<void> update(String id, AccountDraft draft) async =>
      updated[id] = draft;

  @override
  Future<void> setArchived(String id, {required bool archived}) async =>
      this.archived[id] = archived;
}

/// An account with its balance for tests.
AccountBalance row(
  String name,
  Money balance, {
  AccountType type = AccountType.debit,
  bool archived = false,
  bool includeInTotals = true,
  String? lastDigits,
  AccountArt art = AccountArt.emerald,
  Money? opening,
}) => AccountBalance(
  Account(
    id: name,
    name: name,
    type: type,
    openingBalance: opening ?? balance,
    includeInTotals: includeInTotals,
    archived: archived,
    sortOrder: 0,
    lastDigits: lastDigits,
    art: art,
  ),
  balance,
);
