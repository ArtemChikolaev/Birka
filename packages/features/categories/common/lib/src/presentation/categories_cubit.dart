import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:categories_common/src/domain/categories_overview.dart';
import 'package:categories_common/src/domain/categories_repository.dart';
import 'package:categories_common/src/domain/category_draft.dart';
import 'package:categories_common/src/domain/category_presets.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';

/// What the list of categories shows.
@immutable
sealed class CategoriesState {
  const CategoriesState(this.kind);

  /// The kind on the screen.
  final CategoryKind kind;
}

/// The first read has not come back yet.
final class CategoriesLoading extends CategoriesState {
  /// Creates the state.
  const CategoriesLoading(super.kind);
}

/// The categories are here.
final class CategoriesLoaded extends CategoriesState {
  /// Creates the state with [overview].
  const CategoriesLoaded(super.kind, this.overview);

  /// The categories of the kind.
  final CategoriesOverview overview;
}

/// The categories could not be read.
final class CategoriesFailed extends CategoriesState {
  /// Creates the state.
  const CategoriesFailed(super.kind);
}

/// Follows the categories of one kind in the local database.
class CategoriesCubit extends Cubit<CategoriesState> {
  /// Creates the cubit and starts to follow [_repository].
  CategoriesCubit(this._repository)
    : super(const CategoriesLoading(CategoryKind.expense)) {
    _follow();
  }

  final CategoriesRepository _repository;
  StreamSubscription<void>? _subscription;

  /// Shows the categories of [kind].
  Future<void> kindChanged(CategoryKind kind) async {
    if (kind == state.kind) return;
    await _restart(kind);
  }

  /// Reads the categories again after a failure.
  Future<void> retry() => _restart(state.kind);

  /// Adds the ready set, in the language of the user.
  Future<void> addPresets() => _repository.addAll([
    for (final preset in categoryPresets)
      CategoryDraft(
        kind: preset.kind,
        name: t.categories.presets[preset.key] ?? preset.key,
        icon: preset.icon,
        color: preset.color,
      ),
  ]);

  /// Moves to [kind] at once and lets the old stream finish cancelling.
  Future<void> _restart(CategoryKind kind) async {
    final cancelled = _subscription?.cancel();
    emit(CategoriesLoading(kind));
    _follow();
    await cancelled;
  }

  void _follow() {
    final kind = state.kind;
    _subscription = _repository
        .watchCategories(kind)
        .listen(
          (categories) => emit(
            CategoriesLoaded(kind, CategoriesOverview.of(categories)),
          ),
          onError: (Object _) => emit(CategoriesFailed(kind)),
        );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
