import 'package:decimal/decimal.dart';
import 'package:import_common/src/domain/cell_values.dart';
import 'package:import_common/src/domain/statement_format.dart';
import 'package:import_common/src/domain/statement_layout.dart';
import 'package:import_common/src/domain/statement_table.dart';
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:meta/meta.dart';

/// Money that left or reached one account of a statement.
@immutable
final class StatementLeg {
  /// Creates a leg.
  const StatementLeg({
    required this.account,
    required this.amount,
    this.currency,
  });

  /// The key of the account in the file: see [SourceAccount.key].
  final String account;

  /// The amount, above zero.
  final Decimal amount;

  /// The code of the currency, when the file gives it.
  final String? currency;
}

/// An operation read from a statement, before it becomes a transaction.
@immutable
final class StatementRow {
  /// Creates an operation.
  const StatementRow({
    required this.line,
    required this.date,
    this.out,
    this.into,
    this.fee,
    this.description = '',
    this.note = '',
    this.category,
    this.card,
    this.balance,
  }) : assert(out != null || into != null, 'An operation moves money');

  /// The number of its row in the file.
  final int line;

  /// When it happened.
  final CellDate date;

  /// What left an account, or `null`.
  final StatementLeg? out;

  /// What reached an account, or `null`. With [out] it is a transfer.
  final StatementLeg? into;

  /// A fee on top of the amount, above zero, from the same account.
  final Decimal? fee;

  /// What the bank wrote about it.
  final String description;

  /// What a person wrote about it.
  final String note;

  /// The category of the bank or the app.
  final String? category;

  /// The last four digits of the card.
  final String? card;

  /// The balance of the account after it.
  final Decimal? balance;

  /// Whether money moved between two accounts of the file.
  bool get isTransfer => out != null && into != null;

  /// The account of the row, which is the one that money left in a
  /// transfer.
  String get account => (out ?? into)!.account;

  /// What it changed on the account of an operation that is not a transfer.
  Decimal get change =>
      (into?.amount ?? Decimal.zero) -
      (out?.amount ?? Decimal.zero) -
      (fee ?? Decimal.zero);
}

/// Why a row of a statement did not become an operation.
enum RowFault {
  /// Its date does not read.
  unreadableDate,

  /// Its date does not exist, such as September 31.
  noSuchDay,

  /// It has no amount.
  noAmount,

  /// Its amount does not read.
  unreadableAmount,

  /// Its amount is zero.
  zeroAmount,

  /// It did not go through: the bank declined or reverted it.
  declined,
}

/// A row of a statement that did not become an operation.
@immutable
final class RowProblem {
  /// Creates a problem.
  const RowProblem(this.line, this.fault, this.text);

  /// The number of the row in the file.
  final int line;

  /// What is wrong.
  final RowFault fault;

  /// What to show of the row: the value that does not read, or the
  /// description of the operation.
  final String text;

  @override
  String toString() => 'RowProblem($line, ${fault.name}, $text)';
}

/// An account that a statement moves money on, as the file names it.
@immutable
final class SourceAccount {
  /// Creates an account.
  const SourceAccount({
    required this.key,
    required this.operations,
    required this.spent,
    required this.received,
    this.currency,
    this.cards = const {},
    this.opening,
    this.closing,
  });

  /// The name of the account in the file; the code of the currency in a
  /// file of one account in several currencies; or an empty string for the
  /// one account of a file that names none.
  final String key;

  /// The number of operations on it.
  final int operations;

  /// All that left it, fees included.
  final Decimal spent;

  /// All that reached it.
  final Decimal received;

  /// The code of its currency, when the file gives one.
  final String? currency;

  /// The last four digits of its cards.
  final Set<String> cards;

  /// The balance before its first operation, when the file gives balances.
  final Decimal? opening;

  /// The balance after its last operation, when the file gives balances.
  final Decimal? closing;
}

/// What a statement holds, read by a layout.
@immutable
final class Statement {
  /// Creates a statement.
  const Statement({
    required this.layout,
    required this.rows,
    required this.problems,
    required this.accounts,
  });

  /// How it was read.
  final StatementLayout layout;

  /// The operations, the earliest first.
  final List<StatementRow> rows;

  /// The rows that did not become operations, in the order of the file.
  final List<RowProblem> problems;

  /// The accounts it moves money on, the busiest first.
  final List<SourceAccount> accounts;

  /// The day of the first operation.
  CivilDate? get from => rows.isEmpty ? null : rows.first.date.day;

  /// The day of the last operation.
  CivilDate? get to => rows.isEmpty ? null : rows.last.date.day;

  /// Whether the sign of the amounts looks the wrong way round: nearly all
  /// operations are money received.
  bool get looksInverted {
    if (!layout.roles.contains(ColumnRole.amount) || rows.length < 5) {
      return false;
    }
    final received = rows.where((row) => row.out == null).length;
    return received * 3 > rows.length * 2;
  }
}

/// The value of a cell that did not read as money.
final class _Unreadable implements Exception {
  const _Unreadable(this.text);

  final String text;
}

/// The operations of [table] read by [layout], and the rows that did not
/// become operations.
///
/// A row without anything like a date, such as a total or a title, is not an
/// operation and no problem either.
Statement readStatement(StatementTable table, StatementLayout layout) {
  if (layout.missing.isNotEmpty) {
    return Statement(
      layout: layout,
      rows: const [],
      problems: const [],
      accounts: const [],
    );
  }
  final columns = <ColumnRole, List<int>>{};
  for (final (index, role) in layout.roles.indexed) {
    (columns[role] ??= []).add(index);
  }
  Cell? cellOf(TableRow row, ColumnRole role) {
    final at = columns[role];
    return at == null ? null : row[at.first];
  }

  String textOf(TableRow row, ColumnRole role) => {
    for (final at in columns[role] ?? const <int>[])
      if (!row[at].isBlank) row[at].text.trim(),
  }.join(' · ');

  Decimal? moneyOf(TableRow row, ColumnRole role) {
    final cell = cellOf(row, role);
    if (cell == null) return null;
    try {
      return readAmount(cell, layout.options.decimalMark);
    } on CellException {
      throw _Unreadable(cell.text.trim());
    }
  }

  final options = layout.options;
  final accepted = layout.format?.accepted ?? const <String>{};
  final read = <StatementRow>[];
  final problems = <RowProblem>[];
  for (final row in table.rows.skip(layout.header + 1)) {
    final dateCell = cellOf(row, ColumnRole.date)!;
    if (dateCell.isBlank || !looksLikeDate(dateCell)) continue;
    final description = textOf(row, ColumnRole.description);
    final CellDate date;
    try {
      date = readDate(dateCell, options.dateOrder);
    } on CellException catch (error) {
      final fault = error.fault == CellFault.noSuchDay
          ? RowFault.noSuchDay
          : RowFault.unreadableDate;
      problems.add(RowProblem(row.line, fault, dateCell.text.trim()));
      continue;
    }
    final status = cellOf(row, ColumnRole.status);
    if (status != null &&
        accepted.isNotEmpty &&
        !accepted.contains(status.text.trim().toLowerCase())) {
      problems.add(RowProblem(row.line, RowFault.declined, description));
      continue;
    }
    final account = cellOf(row, ColumnRole.account)?.text.trim() ?? '';
    final currency = currencyCode(cellOf(row, ColumnRole.currency)?.text);
    StatementLeg legOf(Decimal amount, ColumnRole accountRole, ColumnRole of) {
      final side = cellOf(row, accountRole)?.text.trim() ?? '';
      final code = currencyCode(cellOf(row, of)?.text) ?? currency;
      return StatementLeg(
        account: _keyOf(side.isEmpty ? account : side, code),
        amount: amount,
        currency: code,
      );
    }

    StatementLeg? out;
    StatementLeg? into;
    Decimal? fee;
    Decimal? balance;
    try {
      if (columns.containsKey(ColumnRole.amount)) {
        final amount = moneyOf(row, ColumnRole.amount);
        if (amount != null && amount != Decimal.zero) {
          final spent = options.sign == AmountSign.expenseNegative
              ? amount < Decimal.zero
              : amount > Decimal.zero;
          final leg = StatementLeg(
            account: _keyOf(account, currency),
            amount: amount.abs(),
            currency: currency,
          );
          if (spent) {
            out = leg;
          } else {
            into = leg;
          }
        }
      } else {
        final spent = moneyOf(row, ColumnRole.expense)?.abs();
        if (spent != null && spent > Decimal.zero) {
          out = legOf(
            spent,
            ColumnRole.expenseAccount,
            ColumnRole.expenseCurrency,
          );
        }
        final received = moneyOf(row, ColumnRole.income)?.abs();
        if (received != null && received > Decimal.zero) {
          into = legOf(
            received,
            ColumnRole.incomeAccount,
            ColumnRole.incomeCurrency,
          );
        }
      }
      final taken = moneyOf(row, ColumnRole.fee)?.abs();
      if (taken != null && taken > Decimal.zero) fee = taken;
      balance = moneyOf(row, ColumnRole.balance);
    } on _Unreadable catch (error) {
      problems.add(RowProblem(row.line, RowFault.unreadableAmount, error.text));
      continue;
    }
    if (out == null && into == null) {
      final written = [
        ColumnRole.amount,
        ColumnRole.expense,
        ColumnRole.income,
      ].any((role) => !(cellOf(row, role)?.isBlank ?? true));
      problems.add(
        RowProblem(
          row.line,
          written ? RowFault.zeroAmount : RowFault.noAmount,
          description,
        ),
      );
      continue;
    }
    final digits =
        cellOf(row, ColumnRole.card)?.text.replaceAll(_nonDigits, '') ?? '';
    final category = textOf(row, ColumnRole.category);
    read.add(
      StatementRow(
        line: row.line,
        date: date,
        out: out,
        into: into,
        fee: fee,
        description: description,
        note: textOf(row, ColumnRole.note),
        category: category.isEmpty ? null : category,
        card: digits.length >= 4 ? digits.substring(digits.length - 4) : null,
        balance: balance,
      ),
    );
  }
  _sortByTime(read);
  return Statement(
    layout: layout,
    rows: List.unmodifiable(read),
    problems: List.unmodifiable(problems),
    accounts: _accountsOf(read),
  );
}

final _nonDigits = RegExp(r'\D');

String _keyOf(String account, String? currency) =>
    account.isNotEmpty ? account : currency ?? '';

/// Sorts [rows] by their time. Rows of one day without times keep the order
/// of their operations: the order of the file, or its reverse in a file that
/// lists the latest first.
void _sortByTime(List<StatementRow> rows) {
  var earlier = 0;
  var later = 0;
  for (var index = 1; index < rows.length; index++) {
    final order = rows[index].date.day.compareTo(rows[index - 1].date.day);
    if (order < 0) earlier++;
    if (order > 0) later++;
  }
  final latestFirst = earlier > later;
  rows.sort((a, b) {
    final byDay = a.date.day.compareTo(b.date.day);
    if (byDay != 0) return byDay;
    final (atA, atB) = (a.date.time, b.date.time);
    if (atA != null && atB != null && atA != atB) return atA.compareTo(atB);
    return latestFirst ? b.line.compareTo(a.line) : a.line.compareTo(b.line);
  });
}

List<SourceAccount> _accountsOf(List<StatementRow> rows) {
  final tallies = <String, _Tally>{};
  for (final row in rows) {
    for (final leg in [row.out, row.into].nonNulls) {
      tallies
          .putIfAbsent(leg.account, () => _Tally(leg.currency))
          .add(row, leg);
    }
    if (!row.isTransfer && row.balance != null) {
      tallies[row.account]!.balanced(row);
    }
  }
  final accounts = [
    for (final MapEntry(:key, :value) in tallies.entries)
      SourceAccount(
        key: key,
        operations: value.operations,
        spent: value.spent,
        received: value.received,
        currency: value.mixed ? null : value.currency,
        cards: Set.unmodifiable(value.cards),
        opening: value.opening,
        closing: value.closing,
      ),
  ];
  return List.unmodifiable(
    accounts..sort((a, b) {
      final busier = b.operations.compareTo(a.operations);
      return busier != 0 ? busier : a.key.compareTo(b.key);
    }),
  );
}

final class _Tally {
  _Tally(this.currency);

  String? currency;
  bool mixed = false;
  int operations = 0;
  Decimal spent = Decimal.zero;
  Decimal received = Decimal.zero;
  final cards = <String>{};
  Decimal? opening;
  Decimal? closing;

  void add(StatementRow row, StatementLeg leg) {
    operations++;
    if (leg.currency != currency) {
      if (currency == null) {
        currency = leg.currency;
      } else if (leg.currency != null) {
        mixed = true;
      }
    }
    if (identical(leg, row.out)) {
      spent += leg.amount + (row.fee ?? Decimal.zero);
    } else {
      received += leg.amount;
      if (row.out == null) spent += row.fee ?? Decimal.zero;
    }
    if (row.card != null) cards.add(row.card!);
  }

  void balanced(StatementRow row) {
    opening ??= row.balance! - row.change;
    closing = row.balance;
  }
}
