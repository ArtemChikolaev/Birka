import 'package:import_common/src/domain/cell_values.dart';
import 'package:import_common/src/domain/statement_format.dart';
import 'package:import_common/src/domain/statement_formats.dart';
import 'package:import_common/src/domain/statement_table.dart';
import 'package:meta/meta.dart';

/// A column of a statement as a person sees it.
@immutable
final class StatementColumn {
  /// Creates a column.
  const StatementColumn({
    required this.index,
    required this.header,
    required this.sample,
  });

  /// The place of the column, from 0.
  final int index;

  /// The header, or an empty string when the file has none.
  final String header;

  /// The first value under the header, or an empty cell.
  final Cell sample;
}

/// How to read a statement: where its headers are, what each column holds and
/// how it writes values.
@immutable
final class StatementLayout {
  /// Creates a layout.
  const StatementLayout({
    required this.header,
    required this.columns,
    required this.roles,
    required this.options,
    this.format,
    this.known = 0,
  });

  /// The index in `StatementTable.rows` of the row of headers, or -1 when the
  /// table starts with operations.
  final int header;

  /// The columns of the table.
  final List<StatementColumn> columns;

  /// The role of each column.
  final List<ColumnRole> roles;

  /// How values are written.
  final ReadingOptions options;

  /// The known format that the headers matched, or `null`.
  final StatementFormat? format;

  /// How many columns [format] knew.
  final int known;

  /// What the roles lack for a row to become an operation:
  /// [ColumnRole.date], and [ColumnRole.amount] when there is no column of
  /// money at all.
  Set<ColumnRole> get missing => {
    if (!roles.contains(ColumnRole.date)) ColumnRole.date,
    if (!roles.any(_money.contains)) ColumnRole.amount,
  };

  /// The same layout with [role] on [column]. A role that one column holds
  /// leaves the column that held it before.
  StatementLayout withRole(int column, ColumnRole role) {
    final roles = [
      for (final (index, held) in this.roles.indexed)
        if (index == column)
          role
        else if (held == role && !_shared.contains(role))
          ColumnRole.skip
        else
          held,
    ];
    return StatementLayout(
      header: header,
      columns: columns,
      roles: roles,
      options: options,
      format: format,
      known: known,
    );
  }

  /// The same layout read with [options].
  StatementLayout withOptions(ReadingOptions options) => StatementLayout(
    header: header,
    columns: columns,
    roles: roles,
    options: options,
    format: format,
    known: known,
  );

  static const Set<ColumnRole> _money = {
    ColumnRole.amount,
    ColumnRole.expense,
    ColumnRole.income,
  };

  /// Roles that several columns can hold, whose values join.
  static const Set<ColumnRole> _shared = {
    ColumnRole.skip,
    ColumnRole.description,
    ColumnRole.note,
  };
}

/// How many rows from the top can come before the headers: the name of the
/// bank, the period, the number of the account.
const _preamble = 30;

/// How many rows under the headers show what the columns hold.
const _samples = 20;

/// The layout of [table]: the known format whose headers it has, or a guess
/// from the words of its headers and from its values.
StatementLayout detectLayout(
  StatementTable table, {
  List<StatementFormat> formats = statementFormats,
}) {
  ({StatementFormat format, int header, int known, double share})? best;
  for (final format in formats) {
    final match = _match(table, format);
    if (match == null) continue;
    final (header, known, share) = match;
    final better =
        best == null ||
        share > best.share ||
        (share == best.share && known > best.known);
    if (better) {
      best = (format: format, header: header, known: known, share: share);
    }
  }
  if (best != null) {
    return _layoutOf(
      table,
      best.header,
      _rolesOf(table.rows[best.header], best.format),
      format: best.format,
      known: best.known,
    );
  }
  return guessLayout(table);
}

/// The layout of [table] read as [format], which a person chose, even when
/// its headers are not all there.
StatementLayout layoutAs(StatementTable table, StatementFormat format) {
  final match = _match(table, format, strict: false);
  if (match == null) return guessLayout(table);
  return _layoutOf(
    table,
    match.$1,
    _rolesOf(table.rows[match.$1], format),
    format: format,
    known: match.$2,
  );
}

/// The row of headers of [table] that [format] knows best, with how many
/// columns it knows and their share of the named ones. A [strict] match
/// needs a date, an amount and most of the headers.
(int, int, double)? _match(
  StatementTable table,
  StatementFormat format, {
  bool strict = true,
}) {
  (int, int, double)? best;
  final rows = table.rows.length < _preamble ? table.rows.length : _preamble;
  for (var index = 0; index < rows; index++) {
    final row = table.rows[index];
    final named = row.cells.where((cell) => !cell.isBlank).length;
    if (named < 2) continue;
    final roles = _rolesOf(row, format);
    final known = row.cells
        .where((cell) => format.columns.containsKey(normalizeHeader(cell.text)))
        .length;
    final share = known / named;
    final readable =
        roles.contains(ColumnRole.date) &&
        roles.any(StatementLayout._money.contains);
    if (strict && (!readable || share < 0.6)) continue;
    if (!strict && known == 0) continue;
    if (best == null || known > best.$2) best = (index, known, share);
  }
  return best;
}

List<ColumnRole> _rolesOf(TableRow headers, StatementFormat format) {
  final taken = <ColumnRole>{};
  return [
    for (final cell in headers.cells)
      switch (format.columns[normalizeHeader(cell.text)]) {
        final role? when StatementLayout._shared.contains(role) => role,
        final role? when taken.add(role) => role,
        _ => ColumnRole.skip,
      },
  ];
}

/// The layout of [table] guessed without a known format: the headers are the
/// row above the first operation, or the first row of words when nothing
/// looks like an operation, and their words or the values under them tell
/// the roles.
StatementLayout guessLayout(StatementTable table) {
  final first = _firstOperation(table);
  final header = first == null
      ? table.rows.take(_preamble).toList().indexWhere(_isHeader)
      : first > 0 && _isHeader(table.rows[first - 1])
      ? first - 1
      : -1;
  final width = table.width;
  final roles = List.filled(width, ColumnRole.skip);
  if (header >= 0) {
    final taken = <ColumnRole>{};
    for (final (index, cell) in table.rows[header].cells.indexed) {
      final role = _roleByWords(normalizeHeader(cell.text));
      if (role == null) continue;
      if (StatementLayout._shared.contains(role) || taken.add(role)) {
        roles[index] = role;
      }
    }
  }
  final data = _dataRows(table, header).toList();
  if (!roles.contains(ColumnRole.date)) {
    final column = _columnWhere(roles, data, _readsAsDate);
    if (column != null) roles[column] = ColumnRole.date;
  }
  if (!roles.any(StatementLayout._money.contains)) {
    final column = _columnWhere(roles, data, _readsAsAmount);
    if (column != null) roles[column] = ColumnRole.amount;
  }
  return _layoutOf(table, header, roles);
}

StatementLayout _layoutOf(
  StatementTable table,
  int header,
  List<ColumnRole> found, {
  StatementFormat? format,
  int known = 0,
}) {
  final width = table.width;
  final roles = [
    for (var index = 0; index < width; index++)
      index < found.length ? found[index] : ColumnRole.skip,
  ];
  final data = _dataRows(table, header).toList();
  Iterable<Cell> cellsOf(bool Function(ColumnRole) holds) => [
    for (final (index, role) in roles.indexed)
      if (holds(role))
        for (final row in data) row[index],
  ];
  final words = header >= 0 ? table.rows[header].cells : const <Cell>[];
  final cyrillic = words.any((cell) => _cyrillic.hasMatch(cell.text));
  final options = ReadingOptions(
    sign: format?.sign ?? AmountSign.expenseNegative,
    decimalMark:
        guessDecimalMark(cellsOf(_holdsMoney)) ??
        format?.decimalMark ??
        (cyrillic ? DecimalMark.comma : DecimalMark.dot),
    dateOrder:
        guessDateOrder(cellsOf((role) => role == ColumnRole.date)) ??
        format?.dateOrder ??
        DateOrder.dayMonthYear,
  );
  return StatementLayout(
    header: header,
    columns: [
      for (var index = 0; index < width; index++)
        StatementColumn(
          index: index,
          header: header >= 0 ? table.rows[header][index].text.trim() : '',
          sample: data
              .map((row) => row[index])
              .firstWhere((cell) => !cell.isBlank, orElse: () => Cell.empty),
        ),
    ],
    roles: roles,
    options: options,
    format: format,
    known: known,
  );
}

final _cyrillic = RegExp('[а-яА-ЯёЁ]');
final _digit = RegExp(r'\d');

bool _holdsMoney(ColumnRole role) =>
    StatementLayout._money.contains(role) ||
    role == ColumnRole.fee ||
    role == ColumnRole.balance;

Iterable<TableRow> _dataRows(StatementTable table, int header) =>
    table.rows.skip(header + 1).where((row) => !row.isBlank).take(_samples);

/// The index of the first row that looks like an operation: a date and an
/// amount in two of its cells.
int? _firstOperation(StatementTable table) {
  final rows = table.rows.length < _preamble ? table.rows.length : _preamble;
  for (var index = 0; index < rows; index++) {
    final cells = table.rows[index].cells;
    final dates = [
      for (final (column, cell) in cells.indexed)
        if (_readsAsDate(cell)) column,
    ];
    if (dates.isEmpty) continue;
    final amounts = [
      for (final (column, cell) in cells.indexed)
        if (!dates.contains(column) && _readsAsAmount(cell)) column,
    ];
    if (amounts.isNotEmpty) return index;
  }
  return null;
}

bool _isHeader(TableRow row) {
  final named = row.cells.where((cell) => !cell.isBlank).toList();
  return named.length >= 2 &&
      named.every((cell) => !_readsAsDate(cell) && !_readsAsAmount(cell));
}

/// The first column without a role whose values mostly pass [test].
int? _columnWhere(
  List<ColumnRole> roles,
  List<TableRow> data,
  bool Function(Cell) test,
) {
  for (var column = 0; column < roles.length; column++) {
    if (roles[column] != ColumnRole.skip) continue;
    final cells = [
      for (final row in data)
        if (!row[column].isBlank) row[column],
    ];
    if (cells.isEmpty) continue;
    if (cells.where(test).length * 5 >= cells.length * 4) return column;
  }
  return null;
}

bool _readsAsDate(Cell cell) {
  if (!looksLikeDate(cell)) return false;
  for (final order in DateOrder.values) {
    try {
      readDate(cell, order);
      return true;
    } on CellException {
      continue;
    }
  }
  return false;
}

bool _readsAsAmount(Cell cell) {
  if (cell.kind == CellKind.date || !_digit.hasMatch(cell.text)) {
    return false;
  }
  for (final mark in DecimalMark.values) {
    try {
      if (readAmount(cell, mark) != null) return true;
    } on CellException {
      continue;
    }
  }
  return false;
}

/// The words of headers that tell a role, in the order they are tried: a
/// balance before an amount, because «Остаток» is also a sum.
const _words = <(ColumnRole, List<String>)>[
  (ColumnRole.balance, ['остаток', 'баланс', 'balance']),
  (ColumnRole.fee, ['комисси', 'fee']),
  (
    ColumnRole.expense,
    ['расход', 'списан', 'debit', 'withdraw', 'paid out', 'outflow'],
  ),
  (
    ColumnRole.income,
    ['приход', 'поступлен', 'зачислен', 'credit', 'deposit', 'paid in'],
  ),
  (ColumnRole.date, ['дата', 'date']),
  (ColumnRole.currency, ['валют', 'currency']),
  (ColumnRole.amount, ['сумма', 'amount', 'sum']),
  (ColumnRole.category, ['категори', 'category']),
  (ColumnRole.card, ['карт', 'card']),
  (ColumnRole.note, ['комментари', 'примечани', 'comment', 'note', 'memo']),
  (
    ColumnRole.description,
    [
      'описани',
      'назначени',
      'получател',
      'контрагент',
      'наименовани',
      'description',
      'narrative',
      'details',
      'payee',
      'merchant',
      'counterparty',
    ],
  ),
  (ColumnRole.account, ['счет', 'account']),
];

ColumnRole? _roleByWords(String header) {
  if (header.isEmpty) return null;
  for (final (role, words) in _words) {
    if (words.any(header.contains)) return role;
  }
  return null;
}
