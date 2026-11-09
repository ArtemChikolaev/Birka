import 'dart:math' as math;

import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:schedules_common/src/domain/spending_plan.dart';

/// How many months back the usual pace of spending looks.
const usualPaceMonths = 3;

/// What the [counted] accounts spend a day as usual (ADR 0023, point 24):
/// their expenses over the [months] months before [today], without the
/// regular payments of [schedules], which the plan counts on their days, and
/// without transfers, split evenly between the days of that time. A younger
/// ledger counts from its first operation on those accounts, and gives no
/// pace while it has less than [least] days.
Money? usualPace(
  Iterable<Transaction> history, {
  required CivilDate today,
  required Set<String> counted,
  required List<Schedule> schedules,
  required Currency currency,
  int months = usualPaceMonths,
  int least = 28,
}) {
  final from = today.addMonths(-months);
  CivilDate? first;
  var spent = 0;
  for (final transaction in history) {
    final on = transaction.occurredOn;
    if (on.compareTo(today) >= 0 ||
        transaction.status == TransactionStatus.planned) {
      continue;
    }
    final ours = [
      for (final entry in transaction.entries)
        if (counted.contains(entry.accountId)) entry,
    ];
    if (ours.isEmpty) continue;
    if (first == null || on.compareTo(first) < 0) first = on;
    if (on.compareTo(from) < 0 ||
        transaction.kind != TransactionKind.expense ||
        transaction.source == TransactionSource.recurring ||
        _isPayment(transaction, schedules)) {
      continue;
    }
    for (final entry in ours) {
      spent -= entry.amount.minorUnits;
    }
  }
  if (first == null) return null;
  final start = first.compareTo(from) < 0 ? from : first;
  final days = start.daysUntil(today);
  if (days < least) return null;
  return Money(math.max(0, spent) ~/ days, currency);
}

/// Whether [transaction] is a time of one of [schedules]: the operation a
/// payment was made from, the last time one found or posted, or one of its
/// name on its account.
bool _isPayment(Transaction transaction, List<Schedule> schedules) {
  final name = nameKey(transaction.note);
  return schedules.any(
    (schedule) =>
        schedule.madeFrom == transaction.id ||
        schedule.last?.transactionId == transaction.id ||
        (name.isNotEmpty &&
            schedule.kind == transaction.kind &&
            nameKey(schedule.name) == name &&
            transaction.entries.any(
              (entry) => entry.accountId == schedule.accountId,
            )),
  );
}

/// What becomes of the money of the days of [plan] when the days take the
/// [usual] pace instead of what the plan allows (ADR 0023, point 24).
@immutable
final class SpendingForecast {
  /// Creates the forecast of [plan] at the [usual] pace.
  const SpendingForecast(this.plan, this.usual);

  /// The plan it looks at.
  final SpendingPlan plan;

  /// What the days take as usual.
  final Money usual;

  /// Whether the payments take all the money already, so no pace helps.
  bool get none => !plan.free.isPositive;

  /// What is left after the last day of [plan]: negative when the money
  /// runs out before it.
  Money get left => plan.free - usual * plan.days;

  /// Whether the money runs out before the end of [plan].
  bool get short => left.isNegative;

  /// The first day that the money no longer covers at the usual pace, or
  /// `null` while it lasts until the end.
  CivilDate? get runsOut {
    if (none) return plan.today;
    if (!short) return null;
    return plan.today.addDays(plan.free.minorUnits ~/ usual.minorUnits);
  }
}
