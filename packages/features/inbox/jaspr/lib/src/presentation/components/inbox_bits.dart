import 'package:design_jaspr/design_jaspr.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// What [transaction] does to money, for people: «−1 450 ₽» or «+700 ₽».
String amountLabel(Transaction transaction) {
  final amount = transaction.entries.single.amount;
  return amount.isPositive ? '+${formatMoney(amount)}' : formatMoney(amount);
}

/// The tone of the amount of [transaction]: money in is green.
AmountTone toneOf(Transaction transaction) =>
    transaction.entries.single.amount.isPositive
    ? AmountTone.positive
    : AmountTone.neutral;

/// The day and the account of [transaction]: «4 октября · Зарплатная карта».
String placeLabel(Transaction transaction, InboxState state, int thisYear) {
  final day = transaction.occurredOn;
  final accountId = transaction.entries.single.accountId;
  final account = state.accounts.where((it) => it.id == accountId).firstOrNull;
  return [
    dateLabel(
      year: day.year,
      month: day.month,
      day: day.day,
      thisYear: thisYear,
    ),
    ?account?.name,
  ].join(' · ');
}

/// The kind of categories that [transaction] takes.
CategoryKind kindOf(Transaction transaction) =>
    transaction.kind == TransactionKind.income
    ? CategoryKind.income
    : CategoryKind.expense;

/// The options of a field of categories of [kinds]: [first] on top, then
/// the open categories, each parent followed by its subcategories.
({Map<String, String> options, Set<String> nested}) categoryOptions(
  InboxState state,
  Iterable<CategoryKind> kinds, {
  required String first,
}) {
  final tree = [
    for (final kind in kinds) ...categoryTree(state.categories, kind),
  ];
  return (
    options: {
      '': first,
      for (final (:category, nested: _) in tree) category.id: category.name,
    },
    nested: {
      for (final (:category, :nested) in tree)
        if (nested) category.id,
    },
  );
}

/// The color of [category], or a quiet one when it has none.
String colorOf(Category? category) =>
    category?.color ?? 'var(--color-text-subtle)';
