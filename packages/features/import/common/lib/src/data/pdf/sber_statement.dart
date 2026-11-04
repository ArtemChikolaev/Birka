import 'package:decimal/decimal.dart';
import 'package:import_common/src/data/pdf/pdf_text.dart';
import 'package:import_common/src/domain/cell_values.dart';
import 'package:import_common/src/domain/statement_reader.dart';
import 'package:import_common/src/domain/statement_table.dart';

/// The headers of the table of a statement of Sberbank, as its PDF names the
/// columns, with the fee, the currency and the card of the statement beside.
const sberHeaders = [
  'Дата операции (МСК)',
  'Дата обработки',
  'Код авторизации',
  'Категория',
  'Описание операции',
  'Сумма в валюте счёта',
  'Сумма в валюте операции',
  'Комиссия',
  'Валюта счёта',
  'Карта',
];

/// The table of a statement of an account of Sberbank from its online bank,
/// read from the [lines] of its PDF, or `null` when they are no such
/// statement.
///
/// Each operation takes two lines: the day, the time, the category and the
/// amount in the currency of the account, which is money spent without a sign
/// and money received with a plus; then the day it was processed, the code of
/// its authorisation, its description and the amount in the currency of the
/// operation when that is another. A third line can say that the amount holds
/// a fee: the fee then stands apart, as the ledger keeps fees. The row of an
/// operation has the number of the operation in the statement as its line.
///
/// Throws an [UnreadableFile] when the operations do not add up to the totals
/// of the statement, so that a part of it never comes in alone.
StatementTable? sberStatement(String fileName, List<PdfLine> lines) {
  bool has(String text) => lines.any((line) => line.text.contains(text));
  if (!has('Расшифровка операций') ||
      !(has('sberbank.ru') || has('СберБанк') || has('Сбербанк'))) {
    return null;
  }
  String? value(String label) {
    for (final line in lines) {
      if (line.runs.length > 1 && line.runs.first.text.trim() == label) {
        return line.runs.skip(1).map((run) => run.text.trim()).join(' ');
      }
    }
    return null;
  }

  final named = value('Валюта');
  final currency = _currencies[named?.toLowerCase()] ?? named ?? '';
  final card = value('Карта') ?? '';
  final operations = <_Operation>[];
  _Operation? current;
  PdfLine? previous;
  var table = false;
  for (final line in lines) {
    final runs = line.runs;
    if (line.text.contains('Расшифровка операций')) {
      table = true;
      continue;
    }
    if (!table || runs.isEmpty) continue;
    final first = runs.first.text.trim();
    if (runs.length >= 3 &&
        _date.hasMatch(first) &&
        _time.hasMatch(runs[1].text.trim()) &&
        _amount.hasMatch(runs.last.text.trim())) {
      current = _Operation(
        day: first,
        time: runs[1].text.trim(),
        category: _joined(runs.sublist(2, runs.length - 1)),
        amount: runs.last.text.trim(),
      );
      operations.add(current);
      previous = line;
    } else if (current != null &&
        current.processed == null &&
        _date.hasMatch(first)) {
      var rest = runs.skip(1).toList();
      current.processed = first;
      if (rest.isNotEmpty && _code.hasMatch(rest.first.text.trim())) {
        current.code = rest.first.text.trim();
        rest = rest.skip(1).toList();
      }
      if (rest.length > 1 && _foreign.hasMatch(rest.last.text.trim())) {
        current.foreign = rest.last.text.trim();
        rest = rest.take(rest.length - 1).toList();
      }
      current
        ..description = _joined(rest)
        ..column = rest.isEmpty ? null : rest.first.x;
      previous = line;
    } else if (current != null &&
        current.column != null &&
        previous != null &&
        previous.page == line.page &&
        previous.y - line.y < 16 &&
        (runs.first.x - current.column!).abs() < 4) {
      // A line under the description goes on with it.
      final fee = _fee.firstMatch(line.text);
      if (fee != null) {
        current.fee = fee[1]!.trim();
      } else {
        current.description = '${current.description} ${line.text}'.trim();
      }
      previous = line;
    } else {
      previous = null;
    }
  }
  _checkTotals(operations, value('Пополнение'), value('Списание'));
  return StatementTable(
    fileName: fileName,
    file: TableFile.pdf,
    rows: List.unmodifiable([
      TableRow(0, [for (final header in sberHeaders) Cell.text(header)]),
      for (final (index, operation) in operations.indexed)
        TableRow(index + 1, [
          Cell.text('${operation.day} ${operation.time}'),
          Cell.text(operation.processed ?? ''),
          Cell.text(operation.code ?? ''),
          Cell.text(operation.category),
          Cell.text(operation.description),
          Cell.text(operation.amountWithoutFee),
          Cell.text(operation.foreign ?? ''),
          Cell.text(operation.fee ?? ''),
          Cell.text(currency),
          Cell.text(card),
        ]),
    ]),
  );
}

/// Throws when [operations] do not add up to the totals [received] and
/// [spent] of the statement, when it gives them.
void _checkTotals(
  List<_Operation> operations,
  String? received,
  String? spent,
) {
  var income = Decimal.zero;
  var spending = Decimal.zero;
  for (final operation in operations) {
    final amount = operation.value;
    if (operation.received) {
      income += amount;
    } else {
      spending += amount;
    }
  }
  for (final (total, sum) in [(received, income), (spent, spending)]) {
    if (total == null) continue;
    final expected = _decimal(total);
    if (expected != null && expected.abs() != sum) {
      throw const UnreadableFile(UnreadableReason.incomplete);
    }
  }
}

String _joined(Iterable<PdfTextRun> runs) => runs
    .map((run) => run.text.trim())
    .where((text) => text.isNotEmpty)
    .join(' ');

Decimal? _decimal(String text) {
  try {
    return readAmount(Cell.text(text), DecimalMark.comma);
  } on CellException {
    return null;
  }
}

/// One operation of the statement as its lines give it.
final class _Operation {
  _Operation({
    required this.day,
    required this.time,
    required this.category,
    required this.amount,
  });

  final String day;
  final String time;
  final String category;

  /// The amount as the statement writes it, with a plus for money received.
  final String amount;
  String? processed;
  String? code;
  String description = '';

  /// Where the description starts on the page.
  double? column;
  String? foreign;
  String? fee;

  bool get received => amount.startsWith('+');

  Decimal get value => _decimal(amount)?.abs() ?? Decimal.zero;

  /// The amount without the fee that it holds, which stands apart, with the
  /// plus of money received.
  String get amountWithoutFee {
    final fee = this.fee == null ? null : _decimal(this.fee!);
    if (fee == null || received || fee >= value) return amount;
    return (value - fee).toStringAsFixed(2).replaceAll('.', ',');
  }
}

final _date = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
final _time = RegExp(r'^\d{2}:\d{2}$');
final _code = RegExp(r'^[0-9A-Z]{6}$');
final _amount = RegExp(r'^\+?\d{1,3}(?:\s\d{3})*,\d{2}$');
final _foreign = RegExp(r'^\+?\d{1,3}(?:\s\d{3})*,\d{2}(?:\s?\S{1,4})?$');
final _fee = RegExp(r'включена комиссия\s+(\d[\d\s]*,\d{2})');

/// The currencies of Sberbank accounts by the names its statements give.
const _currencies = {
  'российский рубль': 'RUB',
  'доллар сша': 'USD',
  'евро': 'EUR',
  'китайский юань': 'CNY',
  'казахстанский тенге': 'KZT',
  'белорусский рубль': 'BYN',
  'армянский драм': 'AMD',
  'турецкая лира': 'TRY',
  'дирхам оаэ': 'AED',
  'фунт стерлингов': 'GBP',
  'швейцарский франк': 'CHF',
  'японская иена': 'JPY',
};
