import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// What the form of a new regular payment holds when it is saved.
@immutable
final class ScheduleDraft {
  /// Creates a draft.
  const ScheduleDraft({
    required this.kind,
    required this.name,
    required this.accountId,
    required this.amount,
    required this.every,
    required this.next,
    this.day,
    this.advanceDay,
    this.toAccountId,
    this.categoryId,
    this.onDay = ScheduleOnDay.ask,
    this.reminder = ScheduleReminder.onDay,
  });

  /// An expense, an income or a transfer.
  final TransactionKind kind;

  /// What the person calls it.
  final String name;

  /// The account the money leaves, or the account an income reaches.
  final String accountId;

  /// The account a transfer reaches.
  final String? toAccountId;

  /// The category, or `null` to let each transaction wait in the inbox.
  final String? categoryId;

  /// The positive amount in the currency of [accountId].
  final Money amount;

  /// How often it comes.
  final ScheduleEvery every;

  /// Its first time, whose day of the month it keeps unless [day] says
  /// otherwise.
  final CivilDate next;

  /// Its day of the month, when its first time is its advance.
  final int? day;

  /// The day of the month of its advance, for a salary paid in halves.
  final int? advanceDay;

  /// What its day does.
  final ScheduleOnDay onDay;

  /// When to remind of it.
  final ScheduleReminder reminder;
}
