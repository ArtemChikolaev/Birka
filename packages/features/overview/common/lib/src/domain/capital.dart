import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// How far back the chart of the capital looks.
enum OverviewPeriod {
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

/// What the capital came to at the end of each day from [start] to [today], in
/// minor units of [now]: the capital of today, with what each day changed taken
/// back. Every change goes through today's rate, so the line follows the money
/// and not the rates (ADR 0012). A change without a rate stays out, as it does
/// from the capital.
List<int> capitalHistory({
  required Money now,
  required List<DayChange> changes,
  required RateBook rates,
  required CivilDate start,
  required CivilDate today,
}) {
  final byDay = <CivilDate, int>{};
  for (final DayChange(:day, :change) in changes) {
    final converted = rates.convert(change, now.currency);
    if (converted == null) continue;
    byDay[day] = (byDay[day] ?? 0) + converted.minorUnits;
  }
  final first = DateTime.utc(start.year, start.month, start.day);
  final last = DateTime.utc(today.year, today.month, today.day);
  final values = List.filled(last.difference(first).inDays + 1, 0);
  var value = now.minorUnits;
  for (var index = values.length - 1; index >= 0; index--) {
    values[index] = value;
    value -= byDay[_date(start.year, start.month, start.day + index)] ?? 0;
  }
  return values;
}
