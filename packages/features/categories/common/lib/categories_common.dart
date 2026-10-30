/// The categories feature in pure Dart: the list, the ready set and the form,
/// shared by both hosts (ADR 0006).
library;

export 'package:ledger/ledger.dart' show Category, CategoryKind;

export 'src/di/register_categories.dart';
export 'src/domain/categories_overview.dart';
export 'src/domain/categories_repository.dart';
export 'src/domain/category_draft.dart';
export 'src/domain/category_looks.dart';
export 'src/domain/category_presets.dart';
export 'src/presentation/categories_cubit.dart';
export 'src/presentation/category_form_cubit.dart';
