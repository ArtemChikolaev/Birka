/// «Спросить» in pure Dart: a question in words becomes a typed query that
/// the ledger counts on the device, shared by both hosts (ADR 0028).
library;

export 'src/data/ledger_ask_repository.dart';
export 'src/di/register_ask.dart';
export 'src/domain/ask_answer.dart';
export 'src/domain/ask_parser.dart';
export 'src/domain/ask_period.dart';
export 'src/domain/ask_query.dart';
export 'src/domain/ask_reading.dart';
export 'src/domain/ask_repository.dart';
export 'src/domain/ask_words.dart' show askTokens, wordMatch;
export 'src/presentation/ask_cubit.dart';
export 'src/presentation/ask_labels.dart';
