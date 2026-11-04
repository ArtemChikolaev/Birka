import 'dart:typed_data';

import 'package:import_common/src/data/csv_table.dart';
import 'package:import_common/src/data/xlsx_table.dart';
import 'package:import_common/src/domain/statement_reader.dart';
import 'package:import_common/src/domain/statement_table.dart';

/// Reads statements in CSV and in Excel workbooks, on the device.
///
/// What a file is comes from its first bytes rather than its name: a bank can
/// call a CSV `.xls`.
final class FileStatementReader implements StatementReader {
  /// Creates the reader.
  const FileStatementReader();

  @override
  Future<StatementTable> read(String fileName, Uint8List bytes) async {
    if (bytes.isEmpty) throw const UnreadableFile(UnreadableReason.empty);
    if (bytes.length > StatementReader.maxBytes) {
      throw const UnreadableFile(UnreadableReason.tooLarge);
    }
    if (_startsWith(bytes, '%PDF'.codeUnits)) {
      throw const UnreadableFile(UnreadableReason.pdf);
    }
    if (_startsWith(bytes, const [0x50, 0x4b, 0x03, 0x04])) {
      return readXlsx(fileName, bytes);
    }
    // A workbook of Excel 97, an HTML page and an image are not tables of
    // text.
    if (_startsWith(bytes, const [0xd0, 0xcf, 0x11, 0xe0]) ||
        _startsWith(bytes, '<'.codeUnits) ||
        _startsWith(bytes, const [0x89, 0x50, 0x4e, 0x47]) ||
        _startsWith(bytes, const [0xff, 0xd8, 0xff])) {
      throw const UnreadableFile(UnreadableReason.notATable);
    }
    return readCsv(fileName, bytes);
  }

  static bool _startsWith(Uint8List bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var index = 0; index < prefix.length; index++) {
      if (bytes[index] != prefix[index]) return false;
    }
    return true;
  }
}
