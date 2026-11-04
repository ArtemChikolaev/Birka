import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:import_common/import_common.dart';
import 'package:import_common/src/data/windows_1251.dart';

/// A table of text cells, one row for each list, numbered from 1.
StatementTable tableOf(
  List<List<String>> rows, {
  String fileName = 'statement.csv',
  TableFile file = TableFile.csv,
}) => StatementTable(
  fileName: fileName,
  file: file,
  rows: [
    for (final (index, cells) in rows.indexed)
      TableRow(index + 1, [for (final cell in cells) Cell.text(cell)]),
  ],
);

/// [text] in Windows-1251, for the characters that it has.
Uint8List windows1251(String text) {
  final bytes = Uint8List.fromList(List.generate(256, (byte) => byte));
  final decoded = decodeWindows1251(bytes);
  final byChar = {
    for (var byte = 0; byte < 256; byte++) decoded.codeUnitAt(byte): byte,
  };
  return Uint8List.fromList([
    for (final unit in text.codeUnits) byChar[unit]!,
  ]);
}

/// [text] in UTF-8 with a byte order mark, as Excel saves CSV.
Uint8List utf8WithMark(String text) =>
    Uint8List.fromList([0xef, 0xbb, 0xbf, ...utf8.encode(text)]);

/// [text] in UTF-16 with its byte order mark, little-endian.
Uint8List utf16(String text) => Uint8List.fromList([
  0xff,
  0xfe,
  for (final unit in text.codeUnits) ...[unit & 0xff, unit >> 8],
]);

/// A workbook whose first sheet has [rows], each given as the parts of the
/// XML of a row.
///
/// [shared] are the shared strings and [formats] the custom formats of
/// numbers by id; each id in [styles] is the format of a style of cells.
Uint8List workbook({
  required List<List<String>> rows,
  List<String> shared = const [],
  Map<int, String> formats = const {},
  List<int> styles = const [0],
  bool since1904 = false,
  String sheetPath = 'worksheets/sheet1.xml',
}) {
  const main = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  const relations =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  const package =
      'http://schemas.openxmlformats.org/package/2006/relationships';
  final archive = Archive()
    ..add(
      _part('xl/workbook.xml', [
        '<workbook xmlns="$main" xmlns:r="$relations">',
        '<workbookPr${since1904 ? ' date1904="1"' : ''}/>',
        '<sheets><sheet name="Выписка" sheetId="1" r:id="rId7"/>',
        '<sheet name="Итоги" sheetId="2" r:id="rId8"/></sheets>',
        '</workbook>',
      ]),
    )
    ..add(
      _part('xl/_rels/workbook.xml.rels', [
        '<Relationships xmlns="$package">',
        '<Relationship Id="rId8" Type="$relations/worksheet" ',
        'Target="worksheets/sheet2.xml"/>',
        '<Relationship Id="rId7" Type="$relations/worksheet" ',
        'Target="$sheetPath"/>',
        '</Relationships>',
      ]),
    )
    ..add(
      _part('xl/sharedStrings.xml', [
        '<sst xmlns="$main" count="${shared.length}">',
        for (final text in shared) '<si>$text</si>',
        '</sst>',
      ]),
    )
    ..add(
      _part('xl/styles.xml', [
        '<styleSheet xmlns="$main">',
        '<numFmts count="${formats.length}">',
        for (final MapEntry(key: id, value: code) in formats.entries)
          '<numFmt numFmtId="$id" formatCode="${_escape(code)}"/>',
        '</numFmts>',
        '<cellStyleXfs count="1"><xf numFmtId="14"/></cellStyleXfs>',
        '<cellXfs count="${styles.length}">',
        for (final id in styles) '<xf numFmtId="$id" applyNumberFormat="1"/>',
        '</cellXfs></styleSheet>',
      ]),
    )
    ..add(
      _part('xl/$sheetPath', [
        '<worksheet xmlns="$main"><sheetData>',
        for (final row in rows) row.join(),
        '</sheetData></worksheet>',
      ]),
    )
    ..add(
      _part('xl/worksheets/sheet2.xml', [
        '<worksheet xmlns="$main"><sheetData><row r="1">',
        '<c r="A1" t="inlineStr"><is><t>Не та</t></is></c></row>',
        '</sheetData></worksheet>',
      ]),
    );
  return ZipEncoder().encodeBytes(archive);
}

ArchiveFile _part(String name, List<String> xml) => ArchiveFile.string(
  name,
  ['<?xml version="1.0" encoding="UTF-8"?>', ...xml].join(),
);

String _escape(String value) =>
    value.replaceAll('&', '&amp;').replaceAll('"', '&quot;');
