import 'package:import_common/src/domain/cell_values.dart';
import 'package:import_common/src/domain/statement_table.dart';
import 'package:meta/meta.dart';

/// What a column of a statement holds.
enum ColumnRole {
  /// The day of the operation, with its time when the file gives it.
  date,

  /// A signed amount: money spent with one sign and money received with the
  /// other (`AmountSign`).
  amount,

  /// Money spent, without a sign, beside a column of money received.
  expense,

  /// Money received, without a sign, beside a column of money spent.
  income,

  /// A fee taken on top of the amount, which becomes an expense of its own.
  fee,

  /// The currency of the amounts of a row.
  currency,

  /// The currency of money spent, when it has a column of its own.
  expenseCurrency,

  /// The currency of money received, when it has a column of its own.
  incomeCurrency,

  /// The account of a row, in a file of several accounts.
  account,

  /// The account that money left, when it has a column of its own.
  expenseAccount,

  /// The account that money reached, when it has a column of its own.
  incomeAccount,

  /// What the bank wrote about the operation: a payee, a shop, a purpose.
  description,

  /// A note that a person wrote, such as a comment in another app.
  note,

  /// The category that the bank or the app gave the operation.
  category,

  /// The category that the person gave the operation in the bank or the
  /// app, which wins over [category] when it is there.
  ownCategory,

  /// The number of the card, of which the last four digits count.
  card,

  /// The balance of the account after the operation.
  balance,

  /// Whether the operation went through; see `StatementFormat.accepted`.
  status,

  /// A column that Birka does not take.
  skip,
}

/// How to read the values of a statement.
@immutable
final class ReadingOptions {
  /// Creates the options.
  const ReadingOptions({
    this.sign = AmountSign.expenseNegative,
    this.decimalMark = DecimalMark.comma,
    this.dateOrder = DateOrder.dayMonthYear,
  });

  /// How a column of signed amounts writes money spent.
  final AmountSign sign;

  /// What separates the fraction of an amount written as text.
  final DecimalMark decimalMark;

  /// The order of the parts of a date that does not start with the year.
  final DateOrder dateOrder;

  /// The same options with the given ones changed.
  ReadingOptions copyWith({
    AmountSign? sign,
    DecimalMark? decimalMark,
    DateOrder? dateOrder,
  }) => ReadingOptions(
    sign: sign ?? this.sign,
    decimalMark: decimalMark ?? this.decimalMark,
    dateOrder: dateOrder ?? this.dateOrder,
  );

  @override
  bool operator ==(Object other) =>
      other is ReadingOptions &&
      other.sign == sign &&
      other.decimalMark == decimalMark &&
      other.dateOrder == dateOrder;

  @override
  int get hashCode => Object.hash(sign, decimalMark, dateOrder);
}

/// A known format of statements: the columns of one bank or app, and how it
/// writes amounts and dates.
@immutable
final class StatementFormat {
  /// Creates a format.
  const StatementFormat({
    required this.id,
    required this.file,
    required this.columns,
    this.sign = AmountSign.expenseNegative,
    this.decimalMark,
    this.dateOrder,
    this.accepted = const {},
  });

  /// What the hosts turn into a name, such as `tbank`.
  final String id;

  /// The kind of file that the bank or the app gives.
  final TableFile file;

  /// The role of each column that the format knows, by its header in lower
  /// case. A header can have several spellings.
  final Map<String, ColumnRole> columns;

  /// How a column of signed amounts writes money spent.
  final AmountSign sign;

  /// The decimal mark of amounts written as text, or `null` when the file
  /// tells it.
  final DecimalMark? decimalMark;

  /// The order of the parts of a date, or `null` when the file tells it.
  final DateOrder? dateOrder;

  /// The values of the [ColumnRole.status] column, in lower case, of
  /// operations that went through. Other rows are left out.
  final Set<String> accepted;
}

/// [header] as the formats know it: in lower case, with single spaces and
/// without quotes, a colon at the end or the letter ё.
String normalizeHeader(String header) => header
    .replaceAll('\ufeff', '')
    .replaceAll('"', '')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r':$'), '')
    .toLowerCase()
    .replaceAll('ё', 'е');
