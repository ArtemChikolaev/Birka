import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:decimal/decimal.dart';
import 'package:import_common/src/domain/statement_reader.dart';
import 'package:import_common/src/domain/statement_table.dart';
import 'package:xml/xml_events.dart';

/// The table of the first sheet of the Excel workbook in [bytes].
///
/// Numbers stay exact decimals, and a number in the format of a date becomes
/// a date, as Excel shows it. A formula gives the value it last had.
StatementTable readXlsx(String fileName, Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object {
    throw const UnreadableFile(UnreadableReason.damaged);
  }
  String? part(String name) {
    final file = archive.findFile(name);
    return file == null
        ? null
        : utf8.decode(file.content, allowMalformed: true);
  }

  if (archive.files.isEmpty) {
    throw const UnreadableFile(UnreadableReason.damaged);
  }
  final workbook = part('xl/workbook.xml');
  if (workbook == null) throw const UnreadableFile(UnreadableReason.notATable);
  try {
    final path = _firstSheet(workbook, part('xl/_rels/workbook.xml.rels'));
    final sheet =
        (path == null ? null : part(path)) ?? part('xl/worksheets/sheet1.xml');
    if (sheet == null) throw const UnreadableFile(UnreadableReason.damaged);
    final rows = _rows(
      sheet,
      strings: _sharedStrings(part('xl/sharedStrings.xml')),
      dates: _dateStyles(part('xl/styles.xml')),
      since1904: RegExp('date1904="(1|true)"').hasMatch(workbook),
    );
    if (rows.isEmpty) throw const UnreadableFile(UnreadableReason.empty);
    return StatementTable(
      fileName: fileName,
      file: TableFile.xlsx,
      rows: List.unmodifiable(rows),
    );
  } on UnreadableFile {
    rethrow;
  } on Object {
    throw const UnreadableFile(UnreadableReason.damaged);
  }
}

String? _attribute(XmlStartElementEvent event, String localName) {
  for (final attribute in event.attributes) {
    if (attribute.localName == localName) return attribute.value;
  }
  return null;
}

/// The path in the archive of the first sheet of [workbook].
String? _firstSheet(String workbook, String? relations) {
  String? id;
  for (final event in parseEvents(workbook)) {
    if (event is XmlStartElementEvent && event.localName == 'sheet') {
      id = _attribute(event, 'id');
      break;
    }
  }
  if (id == null || relations == null) return null;
  for (final event in parseEvents(relations)) {
    if (event is XmlStartElementEvent &&
        event.localName == 'Relationship' &&
        _attribute(event, 'Id') == id) {
      final target = _attribute(event, 'Target');
      if (target == null) return null;
      return target.startsWith('/') ? target.substring(1) : 'xl/$target';
    }
  }
  return null;
}

/// The texts that cells share, in their order. The hints of reading that
/// Japanese adds stay out.
List<String> _sharedStrings(String? xml) {
  if (xml == null) return const [];
  final strings = <String>[];
  final text = StringBuffer();
  var inText = false;
  var hints = 0;
  for (final event in parseEvents(xml)) {
    switch (event) {
      case XmlStartElementEvent(localName: 'si', isSelfClosing: false):
        text.clear();
      case XmlStartElementEvent(localName: 'si', isSelfClosing: true):
        strings.add('');
      case XmlStartElementEvent(localName: 'rPh', isSelfClosing: false):
        hints++;
      case XmlEndElementEvent(localName: 'rPh'):
        hints--;
      case XmlStartElementEvent(localName: 't', isSelfClosing: false):
        inText = true;
      case XmlEndElementEvent(localName: 't'):
        inText = false;
      case XmlTextEvent(:final value) when inText && hints == 0:
        text.write(value);
      case XmlCDATAEvent(:final value) when inText && hints == 0:
        text.write(value);
      case XmlEndElementEvent(localName: 'si'):
        strings.add(text.toString());
      default:
        break;
    }
  }
  return strings;
}

/// Whether each style of a cell shows a date, by its index.
List<bool> _dateStyles(String? xml) {
  if (xml == null) return const [];
  final custom = <int, bool>{};
  final styles = <bool>[];
  var inCellStyles = false;
  for (final event in parseEvents(xml)) {
    switch (event) {
      case XmlStartElementEvent(localName: 'numFmt'):
        final id = int.tryParse(_attribute(event, 'numFmtId') ?? '');
        if (id != null) {
          custom[id] = _showsDate(_attribute(event, 'formatCode') ?? '');
        }
      case XmlStartElementEvent(localName: 'cellXfs', isSelfClosing: false):
        inCellStyles = true;
      case XmlEndElementEvent(localName: 'cellXfs'):
        inCellStyles = false;
      case XmlStartElementEvent(localName: 'xf') when inCellStyles:
        final id = int.tryParse(_attribute(event, 'numFmtId') ?? '') ?? 0;
        styles.add(custom[id] ?? _isBuiltInDate(id));
      default:
        break;
    }
  }
  return styles;
}

/// Whether the built-in format of numbers [id] shows a date or a time.
bool _isBuiltInDate(int id) =>
    (id >= 14 && id <= 22) ||
    (id >= 27 && id <= 36) ||
    (id >= 45 && id <= 47) ||
    (id >= 50 && id <= 58);

/// Whether the format [code] shows a date or a time: it has the letters of
/// one outside quotes, brackets and escapes.
bool _showsDate(String code) => RegExp('[dmyhs]').hasMatch(
  code
      .replaceAll(RegExp('"[^"]*"'), '')
      .replaceAll(RegExp(r'\[[^\]]*\]'), '')
      .replaceAll(RegExp(r'\\.'), '')
      .toLowerCase(),
);

List<TableRow> _rows(
  String xml, {
  required List<String> strings,
  required List<bool> dates,
  required bool since1904,
}) {
  final rows = <TableRow>[];
  var line = 0;
  var cells = <Cell>[];
  var column = 0;
  String? type;
  var style = 0;
  final value = StringBuffer();
  final inline = StringBuffer();
  var inValue = false;
  var inInline = false;
  var inCell = false;
  void endRow() {
    final row = TableRow(line, List.unmodifiable(cells));
    if (row.isBlank) return;
    if (rows.length == StatementReader.maxRows) {
      throw const UnreadableFile(UnreadableReason.tooLarge);
    }
    rows.add(row);
  }

  for (final event in parseEvents(xml)) {
    switch (event) {
      case XmlStartElementEvent(localName: 'row'):
        line = int.tryParse(_attribute(event, 'r') ?? '') ?? line + 1;
        cells = <Cell>[];
        column = 0;
        if (event.isSelfClosing) endRow();
      case XmlEndElementEvent(localName: 'row'):
        endRow();
      case XmlStartElementEvent(localName: 'c'):
        final reference = _attribute(event, 'r');
        column = reference == null ? cells.length : _columnOf(reference);
        type = _attribute(event, 't');
        style = int.tryParse(_attribute(event, 's') ?? '') ?? 0;
        value.clear();
        inline.clear();
        inCell = !event.isSelfClosing;
      case XmlStartElementEvent(localName: 'v', isSelfClosing: false)
          when inCell:
        inValue = true;
      case XmlEndElementEvent(localName: 'v'):
        inValue = false;
      case XmlStartElementEvent(localName: 'is', isSelfClosing: false)
          when inCell:
        inInline = true;
      case XmlEndElementEvent(localName: 'is'):
        inInline = false;
      case XmlTextEvent(value: final text) when inValue:
        value.write(text);
      case XmlTextEvent(value: final text) when inInline:
        inline.write(text);
      case XmlEndElementEvent(localName: 'c'):
        inCell = false;
        while (cells.length < column) {
          cells.add(Cell.empty);
        }
        cells.add(
          _cellOf(
            type,
            value.toString(),
            inline.toString(),
            strings: strings,
            date: style < dates.length && dates[style],
            since1904: since1904,
          ),
        );
      default:
        break;
    }
  }
  return rows;
}

/// The index of the column of a reference such as `AB12`, from 0.
int _columnOf(String reference) {
  var column = 0;
  for (final unit in reference.codeUnits) {
    if (unit < 0x41 || unit > 0x5a) break;
    column = column * 26 + unit - 0x40;
  }
  return column - 1;
}

Cell _cellOf(
  String? type,
  String value,
  String inline, {
  required List<String> strings,
  required bool date,
  required bool since1904,
}) {
  switch (type) {
    case 's':
      final index = int.tryParse(value.trim());
      if (index == null || index < 0 || index >= strings.length) {
        return Cell.empty;
      }
      return Cell.text(strings[index]);
    case 'inlineStr':
      return Cell.text(inline);
    case 'str' || 'e':
      return Cell.text(value);
    case 'b':
      return Cell.text(value.trim() == '1' ? 'TRUE' : 'FALSE');
    case 'd':
      return Cell.date(value.trim());
  }
  if (value.trim().isEmpty) return Cell.empty;
  final number = Decimal.tryParse(value.trim());
  if (number == null) return Cell.text(value);
  return date ? _dateOf(number, since1904: since1904) : Cell.number('$number');
}

/// The date of the serial number [serial] of Excel: days since the end of
/// 1899, or since 1904 in old Mac workbooks, with the time as the fraction.
Cell _dateOf(Decimal serial, {required bool since1904}) {
  final days = serial.floor();
  final seconds = ((serial - days) * Decimal.fromInt(86400)).round();
  final base = since1904 ? DateTime.utc(1904) : DateTime.utc(1899, 12, 30);
  final moment = base.add(
    Duration(
      days: days.toBigInt().toInt(),
      seconds: seconds.toBigInt().toInt(),
    ),
  );
  String two(int value) => value.toString().padLeft(2, '0');
  final time =
      '${two(moment.hour)}:${two(moment.minute)}:${two(moment.second)}';
  if (days == Decimal.zero && !since1904) return Cell.text(time);
  final day =
      '${moment.year.toString().padLeft(4, '0')}-'
      '${two(moment.month)}-${two(moment.day)}';
  return Cell.date(seconds == Decimal.zero ? day : '${day}T$time');
}
