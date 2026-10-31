import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:categories_common/src/domain/categories_repository.dart';
import 'package:categories_common/src/domain/category_draft.dart';
import 'package:categories_common/src/domain/category_looks.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';

/// Where the form stands.
enum CategoryFormStatus {
  /// The category to edit is on its way.
  loading,

  /// The user is filling in the form.
  editing,

  /// A save is under way.
  saving,

  /// The category is saved, and the form can close.
  saved,

  /// The category could not be read or saved.
  failed,
}

/// The fields of the form.
@immutable
final class CategoryFormState {
  /// Creates a state.
  const CategoryFormState({
    required this.status,
    required this.kind,
    required this.name,
    required this.color,
    required this.icon,
    required this.isNew,
    this.parentId,
    this.parents = const [],
    this.archived = false,
    this.nameMissing = false,
  });

  /// Where the form stands.
  final CategoryFormStatus status;

  /// Whether it is for spending or for earning.
  final CategoryKind kind;

  /// The name as typed.
  final String name;

  /// The color as `#rrggbb`.
  final String color;

  /// The name of the icon.
  final String icon;

  /// Whether the form creates a category instead of changing one.
  final bool isNew;

  /// The parent, for a subcategory.
  final String? parentId;

  /// The categories this one can go inside.
  final List<Category> parents;

  /// Whether the category is archived.
  final bool archived;

  /// Whether the name was left empty on a save.
  final bool nameMissing;

  /// A copy with the given fields changed. [parentId] takes a function, so it
  /// can also become `null`.
  CategoryFormState copyWith({
    CategoryFormStatus? status,
    CategoryKind? kind,
    String? name,
    String? color,
    String? icon,
    String? Function()? parentId,
    List<Category>? parents,
    bool? archived,
    bool? nameMissing,
  }) {
    return CategoryFormState(
      status: status ?? this.status,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isNew: isNew,
      parentId: parentId == null ? this.parentId : parentId(),
      parents: parents ?? this.parents,
      archived: archived ?? this.archived,
      nameMissing: nameMissing ?? this.nameMissing,
    );
  }
}

/// Fills in and saves the form of a category.
class CategoryFormCubit extends Cubit<CategoryFormState> {
  /// Creates the form for a new category of [kind], or loads category
  /// [categoryId].
  CategoryFormCubit(
    this._repository, {
    CategoryKind kind = CategoryKind.expense,
    String? categoryId,
  }) : _categoryId = categoryId,
       super(
         CategoryFormState(
           status: categoryId == null
               ? CategoryFormStatus.editing
               : CategoryFormStatus.loading,
           kind: kind,
           name: '',
           color: categoryColors.first,
           icon: categoryIcons.first,
           isNew: categoryId == null,
         ),
       ) {
    unawaited(_load());
  }

  final CategoriesRepository _repository;
  final String? _categoryId;

  /// Sets the name.
  void nameChanged(String value) =>
      emit(state.copyWith(name: value, nameMissing: false));

  /// Sets the kind, which only a new category can change. Another kind has
  /// other parents.
  Future<void> kindChanged(CategoryKind value) async {
    if (!state.isNew || value == state.kind) return;
    emit(state.copyWith(kind: value, parentId: () => null, parents: const []));
    await _loadParents();
  }

  /// Sets the parent, or none.
  void parentChanged(String? value) =>
      emit(state.copyWith(parentId: () => value));

  /// Sets the color.
  void colorChanged(String value) => emit(state.copyWith(color: value));

  /// Sets the icon.
  void iconChanged(String value) => emit(state.copyWith(icon: value));

  /// Checks the fields and saves the category.
  Future<void> save() async {
    final name = state.name.trim();
    if (name.isEmpty) {
      emit(state.copyWith(nameMissing: true));
      return;
    }
    emit(state.copyWith(status: CategoryFormStatus.saving));
    final draft = CategoryDraft(
      kind: state.kind,
      name: name,
      parentId: state.parentId,
      icon: state.icon,
      color: state.color,
    );
    final id = _categoryId;
    await _finish(
      id == null ? _repository.add(draft) : _repository.update(id, draft),
    );
  }

  /// Puts the category away, or brings it back, and closes the form.
  Future<void> toggleArchived() async {
    final id = _categoryId;
    if (id == null) return;
    emit(state.copyWith(status: CategoryFormStatus.saving));
    await _finish(_repository.setArchived(id, archived: !state.archived));
  }

  Future<void> _finish(Future<void> write) async {
    try {
      await write;
      emit(state.copyWith(status: CategoryFormStatus.saved));
    } on Exception {
      emit(state.copyWith(status: CategoryFormStatus.failed));
    }
  }

  Future<void> _load() async {
    try {
      final id = _categoryId;
      if (id != null) {
        final category = await _repository.category(id);
        if (isClosed) return;
        if (category == null) {
          emit(state.copyWith(status: CategoryFormStatus.failed));
          return;
        }
        emit(
          state.copyWith(
            status: CategoryFormStatus.editing,
            kind: category.kind,
            name: category.name,
            color: category.colorHex,
            icon: category.iconName,
            parentId: () => category.parentId,
            archived: category.archived,
          ),
        );
      }
      await _loadParents();
    } on Exception {
      emit(state.copyWith(status: CategoryFormStatus.failed));
    }
  }

  /// A parent is a live category on the first level. A category that has
  /// subcategories cannot go inside another one, so it gets no parents.
  Future<void> _loadParents() async {
    final kind = state.kind;
    final categories = await _repository.watchCategories(kind).first;
    final id = _categoryId;
    final hasChildren = categories.any((category) => category.parentId == id);
    if (kind != state.kind || isClosed) return;
    emit(
      state.copyWith(
        parents: id != null && hasChildren
            ? const []
            : [
                for (final category in categories)
                  if (category.parentId == null &&
                      !category.archived &&
                      category.id != id)
                    category,
              ],
      ),
    );
  }
}
