/// The inbox in pure Dart: the operations without a category with hints
/// from past choices, and the transfers between one's own accounts that
/// imports split, shared by both hosts (ADR 0022).
library;

export 'src/data/ledger_inbox_repository.dart';
export 'src/di/register_inbox.dart';
export 'src/domain/inbox_repository.dart';
export 'src/domain/transfer_pairs.dart';
export 'src/presentation/inbox_cubit.dart';
export 'src/presentation/inbox_labels.dart';
