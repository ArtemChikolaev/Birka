import 'package:decimal/decimal.dart';
import 'package:import_common/src/domain/statement_table.dart';
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:meta/meta.dart';

/// How a column of signed amounts writes money spent.
enum AmountSign {
  /// Below zero, as most banks write it.
  expenseNegative,

  /// Above zero.
  expensePositive,

  /// Without a sign, while money received carries a plus, as Sberbank writes
  /// it.
  incomePlus,
}

/// What stands between the whole part of an amount and its fraction.
enum DecimalMark {
  /// `2 340,50`, as in Russian.
  comma,

  /// `2,340.50`, as in English.
  dot,
}

/// The order of the parts of a date such as `03/10/2026`. A date that starts
/// with four digits always starts with the year.
enum DateOrder {
  /// `03.10.2026` is October 3.
  dayMonthYear,

  /// `10/03/2026` is October 3.
  monthDayYear,
}

/// What was wrong with the value of a cell.
enum CellFault {
  /// Not a date at all.
  unreadableDate,

  /// A date that does not exist, such as September 31.
  noSuchDay,

  /// Not an amount.
  unreadableAmount,
}

/// A value of a cell that could not be read.
final class CellException implements Exception {
  /// Creates the failure.
  const CellException(this.fault);

  /// What was wrong.
  final CellFault fault;

  @override
  String toString() => 'CellException(${fault.name})';
}

/// A date read from a cell, with the time on the clock of the bank when the
/// cell has one.
@immutable
final class CellDate {
  /// Creates a date.
  const CellDate(this.day, [this.time]);

  /// The day.
  final CivilDate day;

  /// The time since midnight, when the cell gives it.
  final Duration? time;

  @override
  bool operator ==(Object other) =>
      other is CellDate && other.day == day && other.time == time;

  @override
  int get hashCode => Object.hash(day, time);

  @override
  String toString() => time == null ? '$day' : '$day $time';
}

final _date = RegExp(
  r'^(\d{1,4})[.\-/](\d{1,2})[.\-/](\d{1,4})'
  r'(?:[ T,]+(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?)?',
);

/// The date in [cell], whose parts come in [order] unless it starts with the
/// year. Throws a [CellException] when it holds no date.
CellDate readDate(Cell cell, DateOrder order) {
  final match = _date.firstMatch(cell.text.trim());
  if (match == null) throw const CellException(CellFault.unreadableDate);
  final parts = [for (var group = 1; group <= 3; group++) match[group]!];
  final int year;
  final int month;
  final int day;
  if (parts[0].length == 4) {
    if (parts[2].length > 2) {
      throw const CellException(CellFault.unreadableDate);
    }
    year = int.parse(parts[0]);
    month = int.parse(parts[1]);
    day = int.parse(parts[2]);
  } else {
    year = switch (parts[2].length) {
      4 => int.parse(parts[2]),
      2 => 2000 + int.parse(parts[2]),
      _ => throw const CellException(CellFault.unreadableDate),
    };
    if (parts[0].length > 2) {
      throw const CellException(CellFault.unreadableDate);
    }
    final first = int.parse(parts[0]);
    final second = int.parse(parts[1]);
    if (order == DateOrder.dayMonthYear) {
      day = first;
      month = second;
    } else {
      day = second;
      month = first;
    }
  }
  if (!_exists(year, month, day)) {
    throw const CellException(CellFault.noSuchDay);
  }
  final date = CivilDate(year, month, day);
  if (match[4] == null) return CellDate(date);
  final hours = int.parse(match[4]!);
  final minutes = int.parse(match[5]!);
  final seconds = int.parse(match[6] ?? '0');
  if (hours > 23 || minutes > 59 || seconds > 59) {
    throw const CellException(CellFault.unreadableDate);
  }
  return CellDate(
    date,
    Duration(hours: hours, minutes: minutes, seconds: seconds),
  );
}

bool _exists(int year, int month, int day) {
  if (year > 9999 || month < 1 || month > 12 || day < 1) return false;
  final last = DateTime.utc(year, month + 1, 0).day;
  return day <= last;
}

/// Whether [cell] holds anything that could be a date, even a wrong one: a
/// row whose date cell holds words, such as a total, is not an operation.
bool looksLikeDate(Cell cell) =>
    cell.kind == CellKind.date || _dateLike.hasMatch(cell.text.trim());

final _dateLike = RegExp(r'^\d[\d\s.\-/:,T]*$');

final _spaces = RegExp(r"[\s\u00a0\u2007\u2009\u202f']");
final _minuses = RegExp(r'[\u2010-\u2015\u2212\ufe63\uff0d]');
final _marks = RegExp(r'[^0-9+\-.,]');
final _byComma = RegExp(r'^(?:\d{1,3}(?:\.\d{3})+|\d+)(?:,\d+)?$');
final _byDot = RegExp(r'^(?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d+)?$');

/// The amount in [cell], with its sign as the file writes it, or `null` when
/// the cell is blank. A number of a workbook needs no [mark]. Throws a
/// [CellException] when the cell holds no amount.
///
/// Text may group digits with spaces, write the minus as U+2212 or put the
/// amount in brackets, and may carry the mark or the code of a currency. A
/// separator other than [mark] counts only between groups of three digits,
/// so `2 340,50` is no amount by [DecimalMark.dot].
Decimal? readAmount(Cell cell, DecimalMark mark) {
  if (cell.isBlank) return null;
  if (cell.kind == CellKind.number) {
    final value = Decimal.tryParse(cell.text.trim());
    if (value == null) throw const CellException(CellFault.unreadableAmount);
    return value;
  }
  final digits = _amountDigits(cell.text, mark);
  if (digits == null) throw const CellException(CellFault.unreadableAmount);
  return Decimal.parse(digits);
}

/// [text] as a plain decimal with a dot, or `null` when it is no amount.
String? _amountDigits(String text, DecimalMark mark) {
  var rest = text.trim();
  var negative = false;
  if (rest.startsWith('(') && rest.endsWith(')')) {
    negative = true;
    rest = rest.substring(1, rest.length - 1);
  }
  rest = rest
      .replaceAll(_spaces, '')
      .replaceAll(_minuses, '-')
      .replaceAll(_marks, '');
  if (rest.endsWith('-') && !rest.startsWith('-')) {
    rest = '-${rest.substring(0, rest.length - 1)}';
  }
  var sign = '';
  if (rest.startsWith('-') || rest.startsWith('+')) {
    sign = rest[0] == '-' ? '-' : '';
    rest = rest.substring(1);
  }
  if (negative) sign = sign == '-' ? '' : '-';
  switch (mark) {
    case DecimalMark.comma:
      if (!_byComma.hasMatch(rest)) return null;
      rest = rest.replaceAll('.', '').replaceAll(',', '.');
    case DecimalMark.dot:
      if (!_byDot.hasMatch(rest)) return null;
      rest = rest.replaceAll(',', '');
  }
  return '$sign$rest';
}

/// The mark that reads more of [cells] than the other, or `null` when they
/// read the same, such as `1 234` or `1,234`.
DecimalMark? guessDecimalMark(Iterable<Cell> cells) {
  var comma = 0;
  var dot = 0;
  for (final cell in cells) {
    if (cell.kind != CellKind.text || cell.isBlank) continue;
    final byComma = _amountDigits(cell.text, DecimalMark.comma);
    final byDot = _amountDigits(cell.text, DecimalMark.dot);
    if (byComma == byDot) continue;
    if (byDot == null) comma++;
    if (byComma == null) dot++;
  }
  if (comma == dot) return null;
  return comma > dot ? DecimalMark.comma : DecimalMark.dot;
}

/// [AmountSign.incomePlus] when the amounts of [cells] carry no minus and
/// some of them a plus, or `null` when they say nothing of it.
AmountSign? guessAmountSign(Iterable<Cell> cells) {
  var plus = false;
  var bare = false;
  for (final cell in cells) {
    if (cell.kind != CellKind.text || cell.isBlank) continue;
    final text = cell.text.trim();
    if (text.startsWith('-') ||
        text.startsWith('(') ||
        text.endsWith('-') ||
        text.contains(_minuses)) {
      return null;
    }
    if (text.startsWith('+')) {
      plus = true;
    } else {
      bare = true;
    }
  }
  return plus && bare ? AmountSign.incomePlus : null;
}

/// Whether the text of [cell] marks its amount with a plus.
bool hasPlus(Cell cell) =>
    cell.kind == CellKind.text && cell.text.trim().startsWith('+');

/// The order that [cells] show, by a part that cannot be a month, or `null`
/// when nothing tells, as with `03.10.2026` alone.
DateOrder? guessDateOrder(Iterable<Cell> cells) {
  var dayFirst = 0;
  var monthFirst = 0;
  for (final cell in cells) {
    if (cell.kind != CellKind.text) continue;
    final match = _date.firstMatch(cell.text.trim());
    if (match == null || match[1]!.length == 4) continue;
    if (int.parse(match[1]!) > 12) dayFirst++;
    if (int.parse(match[2]!) > 12) monthFirst++;
  }
  if (dayFirst == monthFirst) return null;
  return dayFirst > monthFirst
      ? DateOrder.dayMonthYear
      : DateOrder.monthDayYear;
}

final _currencyMarks = {
  '₽': 'RUB',
  'Р': 'RUB',
  'РУБ': 'RUB',
  'РУБ.': 'RUB',
  'RUR': 'RUB',
  r'$': 'USD',
  '€': 'EUR',
  '£': 'GBP',
  '₸': 'KZT',
  '₾': 'GEL',
  '֏': 'AMD',
  '₺': 'TRY',
  '₴': 'UAH',
  'BR': 'BYN',
};

final _currencyCode = RegExp(r'^[A-Z0-9]{2,10}$');

/// The code of the currency that [text] names, such as `RUB` for `RUR` or
/// `₽`, or `null` when it names none.
String? currencyCode(String? text) {
  if (text == null) return null;
  final normalized = text.trim().toUpperCase();
  if (normalized.isEmpty) return null;
  final known = _currencyMarks[normalized];
  if (known != null) return known;
  return _currencyCode.hasMatch(normalized) ? normalized : null;
}
