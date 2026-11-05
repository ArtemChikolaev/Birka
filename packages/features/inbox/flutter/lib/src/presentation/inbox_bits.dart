import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// The name of the operation of [item], or a dash when it has none.
String nameOf(InboxItem item) {
  final note = item.transaction.note.trim();
  return note.isEmpty ? '—' : note;
}

/// The tone of the amount of [transaction]: money in is green.
AmountTone toneOf(Transaction transaction) =>
    transaction.entries.single.amount.isPositive
    ? AmountTone.positive
    : AmountTone.neutral;

/// How many operations [count] is, for a line: «3 операции».
String operationsOf(int count) =>
    t.imports.operations(n: count, count: formatCount(count));

/// Lets the person choose an open category of [kinds] in a sheet titled
/// [title], each parent followed by its subcategories and the one that
/// [hinted] names marked; gives the category, or `null` when they chose none.
Future<Category?> chooseCategory(
  BuildContext context,
  InboxState state,
  Iterable<CategoryKind> kinds, {
  required String title,
  String? hinted,
}) async {
  final tree = [
    for (final kind in kinds) ...categoryTree(state.categories, kind),
  ];
  final byId = {
    for (final (:category, nested: _) in tree) category.id: category,
  };
  final nested = {
    for (final (:category, :nested) in tree)
      if (nested) category.id,
  };
  final picked = await showChoiceSheet<String>(
    context,
    title: title,
    choices: byId.keys.toList(),
    selected: '',
    labelOf: (id) => byId[id]!.name,
    subtitleOf: (id) => id == hinted ? t.inbox.hinted : null,
    leadingOf: (id) => Padding(
      padding: EdgeInsetsDirectional.only(
        start: nested.contains(id) ? BirkaTokens.spaceMd : 0,
      ),
      child: CategoryDot(byId[id]!),
    ),
  );
  return picked == null ? null : byId[picked.$1];
}

/// The dot of the color of [category], or of a quiet one when it has none.
class CategoryDot extends StatelessWidget {
  /// Creates the dot of [category].
  const CategoryDot(this.category, {super.key});

  /// The category.
  final Category category;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color == null
            ? BirkaColors.of(context).textSubtle
            : BirkaColors.fromHex(color),
        shape: BoxShape.circle,
      ),
    );
  }
}
