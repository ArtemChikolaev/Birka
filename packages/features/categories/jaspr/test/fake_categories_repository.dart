import 'package:categories_common/categories_common.dart';

/// Keeps categories in memory.
final class FakeCategoriesRepository implements CategoriesRepository {
  /// Creates a repository with [categories].
  FakeCategoriesRepository([this.categories = const []]);

  /// The categories.
  List<Category> categories;

  /// Whether reading the categories fails.
  bool broken = false;

  /// The drafts that were added.
  final added = <CategoryDraft>[];

  /// The drafts that were saved over categories.
  final updated = <String, CategoryDraft>{};

  /// The ids whose state of being archived changed, with the new state.
  final archived = <String, bool>{};

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) => broken
      ? Stream.error(Exception('broken'))
      : Stream.value([
          for (final category in categories)
            if (category.kind == kind) category,
        ]);

  @override
  Future<Category?> category(String id) async {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  @override
  Future<Category> add(CategoryDraft draft) async {
    added.add(draft);
    return _made(draft);
  }

  /// The category that [draft] became, the last of [added].
  Category _made(CategoryDraft draft) => Category(
    id: 'new-${added.length}',
    kind: draft.kind,
    name: draft.name,
    parentId: draft.parentId,
    icon: draft.icon,
    color: draft.color,
    archived: false,
    sortOrder: categories.length + added.length,
  );

  @override
  Future<void> addAll(List<CategoryDraft> drafts) async => added.addAll(drafts);

  @override
  Future<void> update(String id, CategoryDraft draft) async =>
      updated[id] = draft;

  @override
  Future<void> setArchived(String id, {required bool archived}) async =>
      this.archived[id] = archived;
}

/// A category for tests.
Category category(
  String name, {
  CategoryKind kind = CategoryKind.expense,
  String? parentId,
  bool archived = false,
}) => Category(
  id: name,
  kind: kind,
  name: name,
  archived: archived,
  sortOrder: 0,
  parentId: parentId,
  icon: 'cart',
  color: categoryColors.first,
);
