import 'dart:typed_data';

import 'package:import_common/src/data/pdf/pdf_document.dart';
import 'package:import_common/src/data/pdf/pdf_text.dart';
import 'package:import_common/src/data/pdf/sber_statement.dart';
import 'package:import_common/src/domain/statement_reader.dart';
import 'package:import_common/src/domain/statement_table.dart';

/// The table of a statement in the PDF of [bytes], when it is a statement
/// that Birka knows how to read: for now those of Sberbank, which gives no
/// other format.
///
/// A PDF holds text where it stands on the page, not a table, so each bank
/// needs its own reading. Throws an [UnreadableFile] for any other PDF, an
/// encrypted one or a scan.
StatementTable readPdf(String fileName, Uint8List bytes) {
  final List<PdfLine> lines;
  try {
    lines = textLines(PdfDocument.parse(bytes));
  } on Object {
    throw const UnreadableFile(UnreadableReason.pdf);
  }
  final table = sberStatement(fileName, lines);
  if (table == null) throw const UnreadableFile(UnreadableReason.pdf);
  if (table.rows.length - 1 > StatementReader.maxRows) {
    throw const UnreadableFile(UnreadableReason.tooLarge);
  }
  return table;
}
