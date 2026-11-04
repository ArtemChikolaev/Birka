import 'dart:convert';
import 'dart:typed_data';

import 'package:import_common/src/data/windows_1251.dart';
import 'package:import_common/src/domain/statement_reader.dart';
import 'package:import_common/src/domain/statement_table.dart';

/// The table of a CSV file in [bytes].
///
/// The encoding comes from the byte order mark, else from whether the bytes
/// are valid UTF-8, else Windows-1251. The separator is the one of `,`, `;`,
/// tab and `|` that splits the first lines into the same number of cells,
/// unless a first line `sep=;` names it, as Excel writes.
StatementTable readCsv(String fileName, Uint8List bytes) {
  var text = decodeText(bytes);
  if (text.contains('\u0000')) {
    throw const UnreadableFile(UnreadableReason.notATable);
  }
  final hint = RegExp(r'^sep=(.)\r?\n').firstMatch(text);
  final String separator;
  if (hint != null) {
    separator = hint[1]!;
    text = text.substring(hint.end);
  } else {
    separator = guessSeparator(text);
  }
  final rows = <TableRow>[];
  var line = hint == null ? 0 : 1;
  for (final cells in parseCsv(text, separator)) {
    line++;
    final row = TableRow(line, [for (final cell in cells) Cell.text(cell)]);
    if (row.isBlank) continue;
    if (rows.length == StatementReader.maxRows) {
      throw const UnreadableFile(UnreadableReason.tooLarge);
    }
    rows.add(row);
  }
  if (rows.isEmpty) throw const UnreadableFile(UnreadableReason.empty);
  return StatementTable(
    fileName: fileName,
    file: TableFile.csv,
    rows: List.unmodifiable(rows),
  );
}

/// [bytes] as text: UTF-8 or UTF-16 by their byte order mark, UTF-16 by its
/// zero bytes, UTF-8 when they are valid UTF-8, and Windows-1251 otherwise.
String decodeText(Uint8List bytes) {
  if (_startsWith(bytes, const [0xef, 0xbb, 0xbf])) {
    return utf8.decode(bytes.sublist(3), allowMalformed: true);
  }
  if (_startsWith(bytes, const [0xff, 0xfe])) {
    return _utf16(bytes.sublist(2), littleEndian: true);
  }
  if (_startsWith(bytes, const [0xfe, 0xff])) {
    return _utf16(bytes.sublist(2), littleEndian: false);
  }
  final head = bytes.length < 400 ? bytes.length : 400;
  var evenZeros = 0;
  var oddZeros = 0;
  for (var index = 0; index < head; index++) {
    if (bytes[index] != 0) continue;
    if (index.isEven) {
      evenZeros++;
    } else {
      oddZeros++;
    }
  }
  if (oddZeros * 4 > head) return _utf16(bytes, littleEndian: true);
  if (evenZeros * 4 > head) return _utf16(bytes, littleEndian: false);
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return decodeWindows1251(bytes);
  }
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var index = 0; index < prefix.length; index++) {
    if (bytes[index] != prefix[index]) return false;
  }
  return true;
}

String _utf16(Uint8List bytes, {required bool littleEndian}) {
  final units = Uint16List(bytes.length ~/ 2);
  for (var index = 0; index < units.length; index++) {
    final low = bytes[index * 2 + (littleEndian ? 0 : 1)];
    final high = bytes[index * 2 + (littleEndian ? 1 : 0)];
    units[index] = high << 8 | low;
  }
  return String.fromCharCodes(units);
}

/// The separator of the cells of [text]: the one that splits most of its
/// first lines, outside quotes, into the same number of cells.
String guessSeparator(String text) {
  const candidates = [';', ',', '\t', '|'];
  final lines = parseLines(text).take(30).toList();
  var best = ',';
  var bestScore = 0;
  for (final separator in candidates) {
    final counts = <int, int>{};
    for (final line in lines) {
      final cells = _countOutsideQuotes(line, separator);
      if (cells == 0) continue;
      counts[cells] = (counts[cells] ?? 0) + 1;
    }
    for (final MapEntry(key: cells, value: alike) in counts.entries) {
      final score = alike * 100 + cells;
      if (score > bestScore) {
        bestScore = score;
        best = separator;
      }
    }
  }
  return best;
}

int _countOutsideQuotes(String line, String separator) {
  var count = 0;
  var quoted = false;
  for (var index = 0; index < line.length; index++) {
    final char = line[index];
    if (char == '"') quoted = !quoted;
    if (!quoted && char == separator) count++;
  }
  return count;
}

/// The lines of [text], with line ends inside quotes kept in their line.
Iterable<String> parseLines(String text) sync* {
  final line = StringBuffer();
  var quoted = false;
  for (var index = 0; index < text.length; index++) {
    final char = text[index];
    if (char == '"') quoted = !quoted;
    if (!quoted && (char == '\n' || char == '\r')) {
      if (char == '\r' && index + 1 < text.length && text[index + 1] == '\n') {
        index++;
      }
      yield line.toString();
      line.clear();
      continue;
    }
    line.write(char);
  }
  if (line.isNotEmpty) yield line.toString();
}

/// The records of [text] split by [separator] as RFC 4180 says: a cell in
/// quotes can hold the separator, line ends and doubled quotes.
Iterable<List<String>> parseCsv(String text, String separator) sync* {
  var cells = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  var started = false;
  for (var index = 0; index < text.length; index++) {
    final char = text[index];
    if (quoted) {
      if (char != '"') {
        cell.write(char);
      } else if (index + 1 < text.length && text[index + 1] == '"') {
        cell.write('"');
        index++;
      } else {
        quoted = false;
      }
      continue;
    }
    if (char == '"' && cell.isEmpty) {
      quoted = true;
      started = true;
    } else if (char == separator) {
      cells.add(cell.toString());
      cell.clear();
      started = true;
    } else if (char == '\n' || char == '\r') {
      if (char == '\r' && index + 1 < text.length && text[index + 1] == '\n') {
        index++;
      }
      cells.add(cell.toString());
      cell.clear();
      yield cells;
      cells = <String>[];
      started = false;
    } else {
      cell.write(char);
      started = true;
    }
  }
  if (started || cell.isNotEmpty) {
    cells.add(cell.toString());
    yield cells;
  }
}
