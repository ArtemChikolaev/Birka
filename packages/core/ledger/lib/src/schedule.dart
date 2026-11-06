import 'package:ledger/src/civil_date.dart';
import 'package:ledger/src/transaction.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// How often a schedule comes (ADR 0023).
enum ScheduleEvery {
  /// Every month, on its day, or on the last day of a shorter month.
  month,

  /// Every week, on the weekday of its first time.
  week,

  /// Every year, on its day of the month of its first time.
  year,
}

/// What the day of a schedule does.
enum ScheduleOnDay {
  /// It waits for the person to post it or to skip it, as a payment whose
  /// amount changes from time to time.
  ask,

  /// Birka posts it, as a subscription of one amount.
  post,
}

/// When Birka reminds of a schedule.
enum ScheduleReminder {
  /// On its day.
  onDay,

  /// The day before.
  dayBefore,

  /// Never.
  none,
}

/// A payment that comes again, such as the rent or a salary: a rule that
/// gives a transaction of its own each time it comes, rather than a
/// transaction itself (ADR 0023).
@immutable
final class Schedule {
  /// Creates a schedule.
  const Schedule({
    required this.id,
    required this.kind,
    required this.name,
    required this.accountId,
    required this.amount,
    required this.every,
    required this.day,
    required this.next,
    required this.onDay,
    required this.reminder,
    this.toAccountId,
    this.categoryId,
  });

  /// The id.
  final String id;

  /// An expense, an income or a transfer.
  final TransactionKind kind;

  /// What the person calls it, which becomes the note of each transaction.
  final String name;

  /// The account the money leaves, or the account an income reaches.
  final String accountId;

  /// The account a transfer reaches.
  final String? toAccountId;

  /// The category of an expense or an income, or `null` to let each of its
  /// transactions wait in the inbox for one.
  final String? categoryId;

  /// The positive amount in the currency of [accountId].
  final Money amount;

  /// How often it comes.
  final ScheduleEvery every;

  /// The day of the month it falls on, every month or every year.
  final int day;

  /// When it comes next.
  final CivilDate next;

  /// What its day does.
  final ScheduleOnDay onDay;

  /// When Birka reminds of it.
  final ScheduleReminder reminder;

  /// The time of the rule that comes after [time].
  CivilDate after(CivilDate time) => switch (every) {
    ScheduleEvery.week => time.addDays(7),
    ScheduleEvery.month => CivilDate.onDay(time.year, time.month + 1, day),
    ScheduleEvery.year => CivilDate.onDay(time.year + 1, time.month, day),
  };

  /// Its times from [next] to [until], both included.
  Iterable<CivilDate> timesUntil(CivilDate until) sync* {
    for (var time = next; time.compareTo(until) <= 0; time = after(time)) {
      yield time;
    }
  }

  /// Whether it waits on [today]: its day has come and it is not posted.
  bool isDue(CivilDate today) => next.compareTo(today) <= 0;

  /// The same schedule with [next] as its next time.
  Schedule movedTo(CivilDate next) => Schedule(
    id: id,
    kind: kind,
    name: name,
    accountId: accountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    amount: amount,
    every: every,
    day: day,
    next: next,
    onDay: onDay,
    reminder: reminder,
  );

  @override
  bool operator ==(Object other) =>
      other is Schedule &&
      other.id == id &&
      other.kind == kind &&
      other.name == name &&
      other.accountId == accountId &&
      other.toAccountId == toAccountId &&
      other.categoryId == categoryId &&
      other.amount == amount &&
      other.every == every &&
      other.day == day &&
      other.next == next &&
      other.onDay == onDay &&
      other.reminder == reminder;

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    name,
    accountId,
    toAccountId,
    categoryId,
    amount,
    every,
    day,
    next,
    onDay,
    reminder,
  );

  @override
  String toString() => 'Schedule($name, $amount, ${every.name}, next $next)';
}
