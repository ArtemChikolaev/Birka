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

/// How the last times of a schedule were done.
enum ScheduleDone {
  /// The person or Birka posted them, each as a transaction of its own.
  posted,

  /// The person skipped them.
  skipped,

  /// A statement brought them, so they need no transaction of their own.
  found,
}

/// The last times of a schedule that were done, and how (ADR 0023).
@immutable
final class ScheduleLast {
  /// Creates what was done to the times from [from] to [on].
  const ScheduleLast({
    required this.done,
    required this.from,
    required this.on,
    required this.at,
    this.transactionId,
    this.importId,
  });

  /// How they were done.
  final ScheduleDone done;

  /// The first of them.
  final CivilDate from;

  /// The last of them.
  final CivilDate on;

  /// When they were done.
  final DateTime at;

  /// The transaction of the last one: the one a post gave or the one a
  /// statement brought, or `null` when they were skipped.
  final String? transactionId;

  /// The import whose statement brought them, or `null`.
  final String? importId;

  @override
  bool operator ==(Object other) =>
      other is ScheduleLast &&
      other.done == done &&
      other.from == from &&
      other.on == on &&
      other.at == at &&
      other.transactionId == transactionId &&
      other.importId == importId;

  @override
  int get hashCode => Object.hash(done, from, on, at, transactionId, importId);

  @override
  String toString() => 'ScheduleLast(${done.name}, $from to $on)';
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
    this.advanceDay,
    this.advanceAmount,
    this.last,
    this.madeFrom,
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

  /// The positive amount in the currency of [accountId]: of each time, or of
  /// the rest of a payment with an advance of its own ([advanceAmount]).
  final Money amount;

  /// How often it comes.
  final ScheduleEvery every;

  /// The day of the month it falls on, every month or every year.
  final int day;

  /// The day of the month of its advance, for a payment that comes twice a
  /// month, such as a salary: its advance on this day and the rest on [day],
  /// each time with [amount] unless the advance has [advanceAmount].
  final int? advanceDay;

  /// The positive amount of its advance, when the advance does not bring
  /// the same as the rest, such as 40 000 ₽ of a salary of 120 000 ₽.
  final Money? advanceAmount;

  /// When it comes next.
  final CivilDate next;

  /// What its day does.
  final ScheduleOnDay onDay;

  /// When Birka reminds of it.
  final ScheduleReminder reminder;

  /// Its last times that were done, or `null` while none is.
  final ScheduleLast? last;

  /// The id of the transaction it was made from (ADR 0023, point 22), which
  /// stays its time after later ones, or `null`.
  final String? madeFrom;

  /// The time of the rule that comes after [time].
  CivilDate after(CivilDate time) => switch (every) {
    ScheduleEvery.week => time.addDays(7),
    ScheduleEvery.month => switch (advanceDay) {
      final advance? => _earlier(_nextOn(time, advance), _nextOn(time, day)),
      null => CivilDate.onDay(time.year, time.month + 1, day),
    },
    ScheduleEvery.year => CivilDate.onDay(time.year + 1, time.month, day),
  };

  /// What its [time] brings or takes: [advanceAmount] on the day of an
  /// advance of its own, [amount] otherwise.
  Money amountOn(CivilDate time) =>
      isAdvance(time) ? advanceAmount ?? amount : amount;

  /// What it brings or takes in a month when it comes twice a month, the
  /// advance and the rest together; [amount] otherwise.
  Money get monthAmount =>
      advanceDay == null ? amount : (advanceAmount ?? amount) + amount;

  /// Whether [time] is the time of its advance rather than of the rest.
  bool isAdvance(CivilDate time) => switch (advanceDay) {
    final advance? =>
      CivilDate.onDay(time.year, time.month, advance) == time &&
          CivilDate.onDay(time.year, time.month, day) != time,
    null => false,
  };

  /// The first time after [time] on [day] of a month, or on the last day of a
  /// shorter one.
  static CivilDate _nextOn(CivilDate time, int day) {
    final same = CivilDate.onDay(time.year, time.month, day);
    return same.compareTo(time) > 0
        ? same
        : CivilDate.onDay(time.year, time.month + 1, day);
  }

  static CivilDate _earlier(CivilDate a, CivilDate b) =>
      a.compareTo(b) <= 0 ? a : b;

  /// Its times from [next] to [until], both included.
  Iterable<CivilDate> timesUntil(CivilDate until) sync* {
    for (var time = next; time.compareTo(until) <= 0; time = after(time)) {
      yield time;
    }
  }

  /// Whether it waits on [today]: its day has come and it is not posted.
  bool isDue(CivilDate today) => next.compareTo(today) <= 0;

  /// The same schedule with [next] as its next time, and with [last] as its
  /// last times done when it is given.
  Schedule movedTo(CivilDate next, {ScheduleLast? last}) => Schedule(
    id: id,
    kind: kind,
    name: name,
    accountId: accountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    amount: amount,
    every: every,
    day: day,
    advanceDay: advanceDay,
    advanceAmount: advanceAmount,
    next: next,
    onDay: onDay,
    reminder: reminder,
    last: last ?? this.last,
    madeFrom: madeFrom,
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
      other.advanceDay == advanceDay &&
      other.advanceAmount == advanceAmount &&
      other.next == next &&
      other.onDay == onDay &&
      other.reminder == reminder &&
      other.last == last &&
      other.madeFrom == madeFrom;

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
    advanceDay,
    advanceAmount,
    next,
    onDay,
    reminder,
    last,
    madeFrom,
  );

  @override
  String toString() => 'Schedule($name, $amount, ${every.name}, next $next)';
}
