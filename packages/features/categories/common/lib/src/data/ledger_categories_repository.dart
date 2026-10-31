import 'package:categories_common/src/domain/categories_repository.dart';
import 'package:categories_common/src/domain/category_draft.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ledger/ledger.dart';

/// Keeps the categories in the ledger, which holds their rules.
final class LedgerCategoriesRepository implements CategoriesRepository {
  /// Creates a repository on [_ledger].
  const LedgerCategoriesRepository(this._ledger);

  final LedgerRepository _ledger;

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) =>
      _ledger.watchCategories(kind, includeArchived: true);

  @override
  Future<Category?> category(String id) => _ledger.category(id);

  @override
  Future<void> add(CategoryDraft draft) => _ledger.addCategory(
    kind: draft.kind,
    name: draft.name,
    parentId: draft.parentId,
    icon: draft.icon,
    color: draft.color,
  );

  @override
  Future<void> addAll(List<CategoryDraft> drafts) =>
      _ledger.atomically(() async {
        for (final draft in drafts) {
          await add(draft);
        }
      });

  @override
  Future<void> update(String id, CategoryDraft draft) => _ledger.updateCategory(
    id,
    name: draft.name,
    parentId: Value(draft.parentId),
    icon: Value(draft.icon),
    color: Value(draft.color),
  );

  @override
  Future<void> setArchived(String id, {required bool archived}) =>
      _ledger.updateCategory(id, archived: archived);
}
