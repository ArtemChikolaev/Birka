import 'package:ledger/ledger.dart';
import 'package:rates/src/limits.dart';
import 'package:rates/src/rates_repository.dart';

/// Tells the bell when an operation that the person did not type takes the
/// limit of its category past 80 % or over it (ADR 0033): an import of a
/// statement, or a regular payment that posts itself. What the person types
/// they see in quick add as they type it, so it tells nothing of that.
///
/// It counts the month of today alone: a notice is about the money that is
/// left to spend.
final class LimitNotices {
  /// Creates the notices of [_ledger] at the rates of [_rates], in months
  /// that start on the day that [monthStart] gives.
  LimitNotices(
    this._ledger,
    this._rates, {
    required int Function() monthStart,
    DateTime Function()? now,
  }) : _monthStart = monthStart,
       _now = now ?? DateTime.now;

  final LedgerRepository _ledger;
  final RatesRepository _rates;
  final int Function() _monthStart;
  final DateTime Function() _now;

  /// Tells what import [importId] did to the limits.
  Future<void> afterImport(String importId) => _after(importId: importId);

  /// Tells what transactions [ids] of the regular payments that posted
  /// themselves did to the limits.
  Future<void> afterPayments(Iterable<String> ids) async {
    final transactions = ids.toSet();
    if (transactions.isNotEmpty) await _after(transactions: transactions);
  }

  Future<void> _after({String? importId, Set<String>? transactions}) async {
    final limited = [
      for (final category
          in await _ledger.watchCategories(CategoryKind.expense).first)
        if (category.limit != null) category,
    ];
    if (limited.isEmpty) return;
    final today = CivilDate.of(_now());
    final month = today.monthStart(_monthStart());
    Future<List<CategoryDayTotal>> days({
      String? importId,
      Set<String>? transactions,
    }) => _ledger
        .watchCategoryDays(
          CategoryKind.expense,
          from: month,
          to: today,
          importId: importId,
          transactions: transactions,
        )
        .first;
    final added = await days(importId: importId, transactions: transactions);
    if (added.isEmpty) return;
    final rows = await days();
    // The month as it stood before: the same days without what came.
    final before = [
      ...rows,
      for (final row in added)
        CategoryDayTotal(row.category, row.day, -row.total),
    ];
    final rates = await _rates.watchRates().first;
    for (final category in limited) {
      if (!added.any((row) => row.category?.id == category.id)) continue;
      final now = limitProgress(
        category,
        rows,
        rates,
        month: month,
        today: today,
      );
      final share = limitCrossed(
        limitProgress(category, before, rates, month: month, today: today),
        now,
      );
      if (share == null) continue;
      await _ledger.noteLimit(
        categoryId: category.id,
        name: category.name,
        month: month,
        share: share,
        amount: share == LimitNotice.overShare ? -now.left : now.left,
        importId: importId,
      );
    }
  }
}

/// The share of its limit that the month went past from [was] to [now]:
/// [LimitNotice.overShare] once it took more than the limit, or
/// [LimitNotice.nearShare] once it took 80 % of a limit that says so early,
/// or `null` when it went past neither.
int? limitCrossed(LimitProgress was, LimitProgress now) =>
    switch ((was.state, now.state)) {
      (LimitState.over, _) => null,
      (_, LimitState.over) => LimitNotice.overShare,
      (LimitState.ok, LimitState.near) when now.limit.warnEarly =>
        LimitNotice.nearShare,
      _ => null,
    };
