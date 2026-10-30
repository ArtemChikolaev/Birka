import 'dart:async';

import 'package:categories_common/categories_common.dart';

/// Keeps categories in memory.
final class FakeCategoriesRepository implements CategoriesRepository {
  /// Creates a repository with [categories].
  FakeCategoriesRepository([List<Category> categories = const []])
    : _categories = [...categories];

  final List<Category> _categories;
  final _changes = StreamController<void>.broadcast();

  /// The drafts that were added.
  final added = <CategoryDraft>[];

  /// The drafts that were saved over categories, by id.
  final updated = <String, CategoryDraft>{};

  /// The error of the next write.
  Exception? failure;

  /// Fails the stream of categories.
  void failStream() => _changes.addError(Exception('broken'));

  /// Replaces the categories.
  void emit(List<Category> categories) {
    _categories
      ..clear()
      ..addAll(categories);
    _changes.add(null);
  }

  List<Category> _of(CategoryKind kind) => [
    for (final category in _categories)
      if (category.kind == kind) category,
  ];

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) async* {
    yield _of(kind);
    yield* _changes.stream.map((_) => _of(kind));
  }

  @override
  Future<Category?> category(String id) async {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  @override
  Future<void> add(CategoryDraft draft) async {
    if (failure case final failure?) throw failure;
    added.add(draft);
  }

  @override
  Future<void> addAll(List<CategoryDraft> drafts) async {
    for (final draft in drafts) {
      await add(draft);
    }
  }

  @override
  Future<void> update(String id, CategoryDraft draft) async {
    if (failure case final failure?) throw failure;
    updated[id] = draft;
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    if (failure case final failure?) throw failure;
    emit([
      for (final item in _categories)
        if (item.id == id)
          testCategory(
            item.id,
            kind: item.kind,
            parentId: item.parentId,
            archived: archived,
          )
        else
          item,
    ]);
  }
}

/// A category for tests.
Category testCategory(
  String name, {
  CategoryKind kind = CategoryKind.expense,
  String? parentId,
  bool archived = false,
  String? icon,
  String? color,
}) => Category(
  id: name,
  kind: kind,
  name: name,
  archived: archived,
  sortOrder: 0,
  parentId: parentId,
  icon: icon,
  color: color,
);
