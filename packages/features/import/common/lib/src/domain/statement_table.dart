import 'package:meta/meta.dart';

/// What a file stores in a cell.
enum CellKind {
  /// Text, as in every cell of a CSV file.
  text,

  /// A number, which a spreadsheet keeps apart from its look.
  number,

  /// A date, which a spreadsheet keeps as a number with the format of a date.
  date,
}

/// One cell of a statement, as the file stores it.
@immutable
final class Cell {
  /// A cell of text.
  const Cell.text(this.text) : kind = CellKind.text;

  /// A number: [text] is its exact decimal with a dot, such as `-2340.5`.
  const Cell.number(this.text) : kind = CellKind.number;

  /// A date: [text] is `YYYY-MM-DD`, or `YYYY-MM-DDTHH:MM:SS` with a time.
  const Cell.date(this.text) : kind = CellKind.date;

  /// An empty cell.
  static const empty = Cell.text('');

  /// What the file stores.
  final CellKind kind;

  /// The value as text.
  final String text;

  /// Whether the cell holds nothing but spaces.
  bool get isBlank => text.trim().isEmpty;

  @override
  bool operator ==(Object other) =>
      other is Cell && other.kind == kind && other.text == text;

  @override
  int get hashCode => Object.hash(kind, text);

  @override
  String toString() => '${kind.name}($text)';
}

/// A row of a statement and its number in the file, as a spreadsheet or a
/// text editor shows it.
@immutable
final class TableRow {
  /// Creates a row.
  const TableRow(this.line, this.cells);

  /// The number of the row in the file, from 1.
  final int line;

  /// The cells, from the first column.
  final List<Cell> cells;

  /// The cell in [column], and an empty one past the end of the row.
  Cell operator [](int column) =>
      column < cells.length ? cells[column] : Cell.empty;

  /// Whether every cell is blank.
  bool get isBlank => cells.every((cell) => cell.isBlank);
}

/// The kind of file a table came from.
enum TableFile {
  /// Text with a separator between cells.
  csv,

  /// An Excel workbook.
  xlsx,
}

/// A table read from a statement file, before anything knows what its
/// columns mean.
@immutable
final class StatementTable {
  /// Creates a table.
  const StatementTable({
    required this.fileName,
    required this.file,
    required this.rows,
  });

  /// The name of the file, as the person chose it.
  final String fileName;

  /// The kind of the file.
  final TableFile file;

  /// The rows that hold anything, in the order of the file.
  final List<TableRow> rows;

  /// The number of columns of the widest row.
  int get width => rows.fold(
    0,
    (widest, row) => row.cells.length > widest ? row.cells.length : widest,
  );
}
