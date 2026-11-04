import 'dart:typed_data';

import 'package:import_common/src/domain/statement_table.dart';

/// Why a file did not become a table.
enum UnreadableReason {
  /// A PDF, which Birka does not read yet.
  pdf,

  /// Neither a table of text nor a workbook.
  notATable,

  /// A workbook whose parts are broken or missing.
  damaged,

  /// A file without a single row.
  empty,

  /// More rows than [StatementReader.maxRows], or more bytes than
  /// [StatementReader.maxBytes].
  tooLarge,
}

/// A file that did not become a table.
final class UnreadableFile implements Exception {
  /// Creates the failure.
  const UnreadableFile(this.reason);

  /// Why.
  final UnreadableReason reason;

  @override
  String toString() => 'UnreadableFile(${reason.name})';
}

/// Turns the bytes of a statement into a table. It reads on the device, and
/// the file never leaves it.
abstract interface class StatementReader {
  /// The most rows a file may have.
  static const int maxRows = 10000;

  /// The most bytes a file may have.
  static const int maxBytes = 20 * 1024 * 1024;

  /// The table in [bytes] of the file [fileName]. Throws an [UnreadableFile]
  /// when there is none.
  Future<StatementTable> read(String fileName, Uint8List bytes);
}
