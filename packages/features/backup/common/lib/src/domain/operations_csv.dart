import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// What a table of operations is made of.
@immutable
final class OperationsExport {
  /// Creates what a table is made of.
  const OperationsExport({
    required this.transactions,
    required this.accounts,
    required this.categories,
  });

  /// The operations, in any order.
  final List<Transaction> transactions;

  /// The accounts, archived ones included.
  final List<Account> accounts;

  /// The categories of both kinds, archived ones included.
  final List<Category> categories;
}

/// The words and marks of a table in one language.
@immutable
final class CsvLanguage {
  /// Creates a language of a table.
  const CsvLanguage({
    required this.separator,
    required this.decimalMark,
    required this.headings,
    required this.kinds,
  });

  /// What stands between two cells: a spreadsheet in Russian expects `;`,
  /// because `,` is its decimal mark.
  final String separator;

  /// What stands between the whole part of an amount and its fraction.
  final String decimalMark;

  /// The names of the eight columns: the date, the kind, the amount, the
  /// currency, the account, the category, the subcategory and the note.
  final List<String> headings;

  /// The name of each kind of operation.
  final Map<TransactionKind, String> kinds;
}

/// [export] as a table for Excel and Google Sheets, the earliest operation
/// first: one row for each category of an expense or an income and for each
/// account of a transfer, with signed amounts in the currency of the account.
///
/// It is UTF-8 with a byte order mark, which Excel needs to read Cyrillic,
/// and with the line ends of RFC 4180.
String operationsCsv(OperationsExport export, CsvLanguage language) {
  final accounts = {for (final it in export.accounts) it.id: it};
  final categories = {for (final it in export.categories) it.id: it};
  final transactions = [...export.transactions]
    ..sort((a, b) {
      final days = a.occurredOn.compareTo(b.occurredOn);
      return days != 0 ? days : a.id.compareTo(b.id);
    });
  final rows = [language.headings.map(_text).toList()];
  for (final transaction in transactions) {
    List<String> row(Money amount, String accountId, [String? categoryId]) {
      final category = categories[categoryId];
      final parent = categories[category?.parentId];
      return [
        transaction.occurredOn.toString(),
        _text(language.kinds[transaction.kind]!),
        amount.toDecimalString().replaceFirst('.', language.decimalMark),
        amount.currency.code,
        _text(accounts[accountId]?.name ?? ''),
        _text(parent?.name ?? category?.name ?? ''),
        _text(parent == null ? '' : category?.name ?? ''),
        _text(transaction.note),
      ];
    }

    if (transaction.allocations.isEmpty) {
      for (final entry in transaction.entries) {
        rows.add(row(entry.amount, entry.accountId));
      }
      continue;
    }
    final entry = transaction.entries.single;
    for (final allocation in transaction.allocations) {
      final amount = allocation.amount;
      rows.add(
        row(
          entry.amount.isNegative ? -amount : amount,
          entry.accountId,
          allocation.categoryId,
        ),
      );
    }
  }
  final separator = language.separator;
  final lines = [
    for (final row in rows)
      row.map((cell) => _quoted(cell, separator)).join(separator),
  ];
  return '\uFEFF${lines.join('\r\n')}\r\n';
}

/// A cell of text. A spreadsheet takes text that starts with one of `=+-@` for
/// a formula, so such text gets an apostrophe before it.
String _text(String text) =>
    text.startsWith(RegExp('[=+\\-@\t\r]')) ? "'$text" : text;

/// [cell] in quotes when it holds a quote, a line end or [separator].
String _quoted(String cell, String separator) {
  if (!cell.contains(separator) && !cell.contains(RegExp('["\r\n]'))) {
    return cell;
  }
  return '"${cell.replaceAll('"', '""')}"';
}
