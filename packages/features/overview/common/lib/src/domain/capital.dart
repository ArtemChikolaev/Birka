import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

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
  return balanceHistory(
    now: now.minorUnits,
    changes: byDay,
    start: start,
    today: today,
  );
}
