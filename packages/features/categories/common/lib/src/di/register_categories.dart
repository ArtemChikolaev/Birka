import 'package:categories_common/src/data/ledger_categories_repository.dart';
import 'package:categories_common/src/domain/categories_repository.dart';
import 'package:categories_common/src/presentation/categories_cubit.dart';
import 'package:categories_common/src/presentation/category_form_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:ledger/ledger.dart';

/// Registers the feature in [getIt], which has to know the [LedgerRepository].
void registerCategories(GetIt getIt) {
  getIt
    ..registerLazySingleton<CategoriesRepository>(
      () => LedgerCategoriesRepository(getIt()),
    )
    ..registerFactory(() => CategoriesCubit(getIt()))
    ..registerFactoryParam<CategoryFormCubit, String?, CategoryKind?>(
      (categoryId, kind) => CategoryFormCubit(
        getIt(),
        categoryId: categoryId,
        kind: kind ?? CategoryKind.expense,
      ),
    );
}
