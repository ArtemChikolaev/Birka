import 'dart:async';

import 'package:debts_common/src/domain/debt.dart';
import 'package:debts_common/src/domain/debts_repository.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Keeps the debts in the ledger as accounts named after people, and their
/// steps as transfers (ADR 0029).
final class LedgerDebtsRepository implements DebtsRepository {
  /// Creates a repository on [_ledger], [_rates] and the choice of
  /// [_baseCurrency]. [now] tells the time in tests.
  LedgerDebtsRepository(
    this._ledger,
    this._rates,
    this._baseCurrency, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final LedgerRepository _ledger;
  final RatesRepository _rates;
  final BaseCurrency _baseCurrency;
  final DateTime Function() _now;

  /// The art of each new person in turn, so that people next to each other
  /// look apart.
  static const List<AccountArt> _arts = [
    AccountArt.emerald,
    AccountArt.sapphire,
    AccountArt.amber,
    AccountArt.rose,
    AccountArt.violet,
    AccountArt.graphite,
  ];

  @override
  CivilDate today() => CivilDate.of(_now());

  @override
  Stream<List<Debt>> watchDebts() {
    late final StreamController<List<Debt>> controller;
    final subscriptions = <StreamSubscription<Object?>>[];
    List<Account>? accounts;
    List<Transaction>? transactions;
    void update() {
      final all = accounts;
      final moves = transactions;
      if (all == null || moves == null) return;
      controller.add(
        debtsOf(
          all.where((account) => account.isDebt),
          moves,
          accounts: {for (final account in all) account.id: account},
        ),
      );
    }

    controller = StreamController<List<Debt>>(
      onListen: () {
        subscriptions.addAll([
          _ledger
              .watchAccounts(includeArchived: true, includeDebts: true)
              .listen((it) {
                accounts = it;
                update();
              }, onError: controller.addError),
          _ledger.watchTransactions(debts: true, limit: null).listen((it) {
            transactions = it;
            update();
          }, onError: controller.addError),
        ]);
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<AccountBalance>> watchAccounts() =>
      _ledger.watchAccountBalances();

  @override
  Stream<RateBook> watchRates() => _rates.watchRates();

  @override
  Stream<Currency?> watchBaseCurrency() => _baseCurrency.watch();

  @override
  Stream<Currency?> watchMainCurrency() => _ledger.watchAccounts().map(
    (accounts) => accounts
        .where((account) => account.includeInTotals)
        .firstOrNull
        ?.currency,
  );

  @override
  Future<String> open({
    required String name,
    required DebtSide side,
    required String accountId,
    required Money amount,
    required CivilDate day,
    String? debtId,
    String note = '',
    DebtTerms? terms,
  }) async {
    // A stream cannot be read inside a write, so the debts are read first.
    final debts =
        (await _ledger
                .watchAccounts(includeArchived: true, includeDebts: true)
                .first)
            .where((account) => account.isDebt)
            .toList();
    final named = name.trim();
    final kept = terms?.copyWith(side: side);
    final found = debtId != null
        ? debts.where((debt) => debt.id == debtId).firstOrNull
        : debts
              .where(
                (debt) =>
                    debt.debt?.side == side &&
                    debt.currency == amount.currency &&
                    _sameName(debt.name, named),
              )
              .firstOrNull;
    if (debtId != null && found == null) {
      throw LedgerException('No debt $debtId');
    }
    return _ledger.atomically(() async {
      final String id;
      if (found == null) {
        final account = await _ledger.addAccount(
          name: named,
          type: AccountType.debt,
          openingBalance: Money.zero(amount.currency),
          art: _arts[debts.length % _arts.length],
          debt: kept ?? DebtTerms(side: side),
        );
        id = account.id;
      } else {
        id = found.id;
        if (found.debt?.side != side) {
          throw LedgerException('Debt ${found.name} goes the other way');
        }
        final changed = kept != null && kept != found.debt;
        if (changed || found.archived) {
          await _ledger.updateAccount(
            id,
            debt: changed ? kept : null,
            archived: found.archived ? false : null,
          );
        }
      }
      final lends = side == DebtSide.lent;
      await _ledger.record(
        TransactionDraft.transfer(
          fromAccountId: lends ? accountId : id,
          sent: amount,
          toAccountId: lends ? id : accountId,
          received: amount,
          occurredOn: day,
          note: note.trim(),
        ),
      );
      return id;
    });
  }

  @override
  Future<void> settle(
    String debtId, {
    required String accountId,
    required Money amount,
    required CivilDate day,
  }) => _ledger.atomically(() async {
    final debt = await _ledger.account(debtId);
    final side = debt?.debt?.side;
    if (debt == null || side == null) {
      throw LedgerException('No debt $debtId');
    }
    final back = side == DebtSide.lent;
    await _ledger.record(
      TransactionDraft.transfer(
        fromAccountId: back ? debtId : accountId,
        sent: amount,
        toAccountId: back ? accountId : debtId,
        received: amount,
        occurredOn: day,
      ),
    );
  });

  @override
  Future<void> update(
    String debtId, {
    required String name,
    required DebtTerms terms,
  }) => _ledger.updateAccount(debtId, name: name.trim(), debt: terms);

  static bool _sameName(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();
}
