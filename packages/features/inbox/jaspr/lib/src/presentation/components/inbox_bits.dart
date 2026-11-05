import 'package:design_jaspr/design_jaspr.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:ledger/ledger.dart';

/// The tone of the amount of [transaction]: money in is green.
AmountTone toneOf(Transaction transaction) =>
    transaction.entries.single.amount.isPositive
    ? AmountTone.positive
    : AmountTone.neutral;

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
