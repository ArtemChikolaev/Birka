import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';

/// A category with its subcategories.
@immutable
final class CategoryGroup {
  /// Creates a group.
  const CategoryGroup(this.category, this.children);

  /// The category on the first level.
  final Category category;

  /// Its subcategories.
  final List<Category> children;
}

/// The categories of one kind as a screen shows them.
@immutable
final class CategoriesOverview {
  /// Creates an overview.
  const CategoriesOverview({required this.groups, required this.archived});

  /// Sorts [categories] into groups. A subcategory of an archived category is
  /// put away with it, and one whose parent is gone stands on its own.
  factory CategoriesOverview.of(List<Category> categories) {
    final byId = {for (final category in categories) category.id: category};
    final groups = <String, List<Category>>{};
    final archived = <Category>[];
    for (final category in categories) {
      final parent = byId[category.parentId];
      if (category.archived || (parent?.archived ?? false)) {
        archived.add(category);
      } else if (parent == null) {
        groups[category.id] ??= [];
      } else {
        (groups[parent.id] ??= []).add(category);
      }
    }
    return CategoriesOverview(
      groups: [
        for (final MapEntry(key: id, value: children) in groups.entries)
          CategoryGroup(byId[id]!, children),
      ],
      archived: archived,
    );
  }

  /// The categories in everyday use.
  final List<CategoryGroup> groups;

  /// The categories that were put away.
  final List<Category> archived;

  /// Whether there is nothing to show.
  bool get isEmpty => groups.isEmpty && archived.isEmpty;
}
