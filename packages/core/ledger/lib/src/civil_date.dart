import 'package:meta/meta.dart';

/// A calendar date without a time or a time zone: the day a transaction
/// happened.
///
/// Statements often give no time, and a moment in UTC can land in another
/// month after a change of time zone.
@immutable
final class CivilDate implements Comparable<CivilDate> {
  /// Creates a date. Throws an [ArgumentError] if it does not exist, such as
  /// February 30, or if its year does not fit the four digits of the stored
  /// form, because such a date could not be read back.
  CivilDate(this.year, this.month, this.day) {
    RangeError.checkValueInInterval(year, 0, 9999, 'year');
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw ArgumentError('No such date: $year-$month-$day');
    }
  }

  /// The date of [moment] on the calendar of its own time zone.
  factory CivilDate.of(DateTime moment) =>
      CivilDate(moment.year, moment.month, moment.day);

  /// Parses `YYYY-MM-DD`. Throws a [FormatException] on anything else.
  factory CivilDate.parse(String text) {
    final match = _format.firstMatch(text);
    if (match == null) throw FormatException('Not a civil date', text);
    return CivilDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  static final _format = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// The year.
  final int year;

  /// The month, from 1 to 12.
  final int month;

  /// The day of the month.
  final int day;

  @override
  int compareTo(CivilDate other) => toString().compareTo(other.toString());

  @override
  bool operator ==(Object other) =>
      other is CivilDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// The date as `YYYY-MM-DD`, which sorts as text.
  @override
  String toString() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// The nearest of [months] before [month] in time when [earlier], else the
/// nearest after it, such as the month to swipe to among those to choose
/// from; `null` when there is none. [month] need not be among them, such as
/// a month whose operations are all gone.
CivilDate? neighbourMonth(
  Iterable<CivilDate> months,
  CivilDate month, {
  required bool earlier,
}) {
  CivilDate? nearest;
  for (final other in months) {
    final order = other.compareTo(month);
    if (earlier ? order >= 0 : order <= 0) continue;
    final closer =
        nearest == null ||
        (earlier ? other.compareTo(nearest) > 0 : other.compareTo(nearest) < 0);
    if (closer) nearest = other;
  }
  return nearest;
}
