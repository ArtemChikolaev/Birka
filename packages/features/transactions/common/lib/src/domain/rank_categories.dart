import 'package:ledger/ledger.dart';

/// Puts the categories used most often in [recent] first. The others keep
/// their order behind them, and so do categories used equally often.
List<Category> rankCategories(
  List<Category> categories,
  List<Transaction> recent,
) {
  final uses = <String, int>{};
  for (final transaction in recent) {
    for (final allocation in transaction.allocations) {
      uses.update(allocation.categoryId, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  final places = {
    for (final (index, category) in categories.indexed) category.id: index,
  };
  return [...categories]..sort((a, b) {
    final byUse = (uses[b.id] ?? 0).compareTo(uses[a.id] ?? 0);
    return byUse != 0 ? byUse : places[a.id]!.compareTo(places[b.id]!);
  });
}
