import 'package:ledger/src/civil_date.dart';

/// How far back a chart looks.
enum ChartPeriod {
  /// The last seven days.
  week,

  /// The month so far.
  month,

  /// The last twelve months.
  year
  ;

  /// The day whose end the chart starts from, when today is [today].
  CivilDate startFrom(CivilDate today) => switch (this) {
    week => _date(today.year, today.month, today.day - 7),
    month => _date(today.year, today.month, 0),
    year => _date(today.year - 1, today.month, today.day),
  };

  /// The earliest day any period needs, when today is [today].
  static CivilDate earliest(CivilDate today) => year.startFrom(today);
}

CivilDate _date(int year, int month, int day) =>
    CivilDate.of(DateTime.utc(year, month, day));

/// What a balance came to at the end of each day from [start] to [today]: the
/// balance of today, [now], with what each day changed taken back. Everything
/// is in the same minor units.
List<int> balanceHistory({
  required int now,
  required Map<CivilDate, int> changes,
  required CivilDate start,
  required CivilDate today,
}) {
  final first = DateTime.utc(start.year, start.month, start.day);
  final last = DateTime.utc(today.year, today.month, today.day);
  final values = List.filled(last.difference(first).inDays + 1, 0);
  var value = now;
  for (var index = values.length - 1; index >= 0; index--) {
    values[index] = value;
    value -= changes[_date(start.year, start.month, start.day + index)] ?? 0;
  }
  return values;
}
