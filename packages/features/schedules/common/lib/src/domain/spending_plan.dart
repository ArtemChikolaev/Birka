import 'dart:math' as math;

import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:schedules_common/src/domain/payday_settings.dart';

/// A time of a regular payment.
typedef Occurrence = ({Schedule schedule, CivilDate on});

/// How much can be spent each day until the salary or until the end of the
/// month (ADR 0023).
///
/// It takes the money of the counted accounts as it was in the morning, less
/// the regular payments that leave them before the end and what stays aside,
/// and splits it evenly between the days left, today included. What was spent
/// today comes out of the share of today, so that it lowers the days to come
/// only from tomorrow on.
@immutable
final class SpendingPlan {
  const SpendingPlan._({
    required this.today,
    required this.until,
    required this.payday,
    required this.end,
    required this.days,
    required this.morning,
    required this.payments,
    required this.paid,
    required this.aside,
    required this.spentToday,
  });

  /// The plan of [today] for the [counted] accounts, all in [currency], or
  /// `null` when it counts [until] a salary that no regular income brings to
  /// them.
  ///
  /// A salary is the nearest time after today of a regular income to one of
  /// the counted accounts. The payments are the times until the end of the
  /// regular expenses from those accounts and of the regular transfers from
  /// them to other accounts, the ones that wait for the person included.
  /// Regular incomes before the salary do not count, so that the plan never
  /// promises money that may not come. Today's spending is what the person
  /// recorded on those accounts today: the transactions of regular payments
  /// are part of the payments instead.
  static SpendingPlan? of({
    required CivilDate today,
    required SpendUntil until,
    required Currency currency,
    required List<Schedule> schedules,
    required List<AccountBalance> counted,
    required List<Transaction> todays,
    required Money aside,
  }) {
    final ids = {for (final row in counted) row.account.id};
    final payday = _paydayAfter(today, schedules, ids);
    final CivilDate end;
    switch (until) {
      case SpendUntil.payday:
        if (payday == null) return null;
        end = payday.addDays(-1);
      case SpendUntil.monthEnd:
        end = CivilDate.onDay(today.year, today.month, 31);
    }
    final payments = <Occurrence>[
      for (final schedule in schedules)
        if (_leaves(schedule, ids))
          for (final on in schedule.timesUntil(end))
            (schedule: schedule, on: on),
    ]..sort((a, b) => a.on.compareTo(b.on));
    var spent = 0;
    for (final transaction in todays) {
      if (transaction.kind != TransactionKind.expense ||
          transaction.source == TransactionSource.recurring ||
          transaction.status == TransactionStatus.planned) {
        continue;
      }
      for (final entry in transaction.entries) {
        if (ids.contains(entry.accountId)) spent -= entry.amount.minorUnits;
      }
    }
    final balance = counted.fold(
      0,
      (sum, row) => sum + row.balance.minorUnits,
    );
    return SpendingPlan._(
      today: today,
      until: until,
      payday: payday,
      end: end,
      days: today.daysUntil(end) + 1,
      morning: Money(balance + spent, currency),
      payments: List.unmodifiable(payments),
      paid: Money(
        payments.fold(0, (sum, it) => sum + it.schedule.amount.minorUnits),
        currency,
      ),
      aside: aside,
      spentToday: Money(spent, currency),
    );
  }

  /// The day the plan is for.
  final CivilDate today;

  /// Until when it counts.
  final SpendUntil until;

  /// The next salary, if a regular income brings one.
  final CivilDate? payday;

  /// The last day it counts: the day before the salary, or the last day of
  /// the month.
  final CivilDate end;

  /// How many days it splits the money between, today included.
  final int days;

  /// What the counted accounts held this morning.
  final Money morning;

  /// The times of the regular payments until [end], the earliest first.
  final List<Occurrence> payments;

  /// What [payments] take together.
  final Money paid;

  /// What stays aside.
  final Money aside;

  /// What the person spent today on the counted accounts.
  final Money spentToday;

  /// What is left for the days: [morning] less [paid] and [aside]. It is
  /// negative when the money does not cover the payments.
  Money get free => morning - paid - aside;

  /// What each day may take, in whole units of the currency.
  Money get perDay => _whole(free.isPositive ? free.minorUnits ~/ days : 0);

  /// What today may still take: negative when today took more than its
  /// share.
  Money get leftToday => perDay - spentToday;

  /// Whether today took more than its share.
  bool get over => leftToday.isNegative;

  /// What each of the days after today may take, once today's spending is
  /// out of the money.
  Money get tomorrow {
    if (days <= 1) return _whole(0);
    final rest = (free - spentToday).minorUnits;
    return _whole(math.max(0, rest) ~/ (days - 1));
  }

  Money _whole(int minorUnits) {
    final unit = math.pow(10, free.currency.decimalDigits).toInt();
    return Money(minorUnits ~/ unit * unit, free.currency);
  }

  /// Whether the payments of [schedule] leave the [counted] accounts: an
  /// expense from one of them, or a transfer from one of them to another
  /// account.
  static bool _leaves(Schedule schedule, Set<String> counted) =>
      switch (schedule.kind) {
        TransactionKind.expense => counted.contains(schedule.accountId),
        TransactionKind.transfer =>
          counted.contains(schedule.accountId) &&
              !counted.contains(schedule.toAccountId),
        TransactionKind.income || TransactionKind.adjustment => false,
      };

  /// The nearest time after [today] of a regular income to one of the
  /// [counted] accounts.
  static CivilDate? _paydayAfter(
    CivilDate today,
    List<Schedule> schedules,
    Set<String> counted,
  ) {
    CivilDate? payday;
    for (final schedule in schedules) {
      if (schedule.kind != TransactionKind.income ||
          !counted.contains(schedule.accountId)) {
        continue;
      }
      var time = schedule.next;
      while (time.compareTo(today) <= 0) {
        time = schedule.after(time);
      }
      if (payday == null || time.compareTo(payday) < 0) payday = time;
    }
    return payday;
  }
}
