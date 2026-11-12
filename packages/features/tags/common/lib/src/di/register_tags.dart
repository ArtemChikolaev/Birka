import 'package:get_it/get_it.dart';
import 'package:tags_common/src/data/ledger_tags_repository.dart';
import 'package:tags_common/src/domain/tags_repository.dart';
import 'package:tags_common/src/presentation/operation_tags_cubit.dart';
import 'package:tags_common/src/presentation/tag_form_cubit.dart';
import 'package:tags_common/src/presentation/tag_picker_cubit.dart';
import 'package:tags_common/src/presentation/tag_report_cubit.dart';
import 'package:tags_common/src/presentation/tags_cubit.dart';

/// Registers the feature in [getIt], which has to know the `LedgerRepository`,
/// the `RatesRepository` and the `BaseCurrency` of the host.
void registerTags(GetIt getIt) {
  getIt
    ..registerLazySingleton<TagsRepository>(
      () => LedgerTagsRepository(getIt(), getIt(), getIt()),
    )
    ..registerFactory(() => TagsCubit(getIt()))
    ..registerFactoryParam<TagReportCubit, String, void>(
      (id, _) => TagReportCubit(getIt(), id),
    )
    // A new метка starts with the name that the picker had in its search.
    ..registerFactoryParam<TagFormCubit, String?, String?>(
      (id, name) => TagFormCubit(getIt(), id: id, name: name ?? ''),
    )
    ..registerFactoryParam<TagPickerCubit, Set<String>, void>(
      (picked, _) => TagPickerCubit(getIt(), picked: picked),
    )
    ..registerFactoryParam<OperationTagsCubit, String, void>(
      (id, _) => OperationTagsCubit(getIt(), id),
    );
}
