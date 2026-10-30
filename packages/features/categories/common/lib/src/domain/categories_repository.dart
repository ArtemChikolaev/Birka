import 'package:categories_common/src/domain/category_draft.dart';
import 'package:ledger/ledger.dart';

/// Where the feature keeps its categories.
abstract interface class CategoriesRepository {
  /// The categories of [kind], archived ones included, in their order.
  Stream<List<Category>> watchCategories(CategoryKind kind);

  /// The category [id], if it exists.
  Future<Category?> category(String id);

  /// Adds a category after the others of its kind.
  Future<void> add(CategoryDraft draft);

  /// Adds every category of [drafts] in one go.
  Future<void> addAll(List<CategoryDraft> drafts);

  /// Changes category [id]. Its kind stays as it is.
  Future<void> update(String id, CategoryDraft draft);

  /// Hides category [id] from pickers, or brings it back.
  Future<void> setArchived(String id, {required bool archived});
}
