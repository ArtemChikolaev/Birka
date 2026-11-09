import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// An operation that came every month on about the same day and has no
/// regular payment yet, such as a subscription or a bill that the person
/// never added (ADR 0023, point 23). Birka offers to make it one.
@immutable
final class RepeatFind {
  /// Creates the find of [times], the earliest first, one a month.
  RepeatFind(this.key, List<Transaction> times)
    : times = List.unmodifiable(times),
      assert(times.length >= 3, 'A find has three months at least');

  /// What keeps a dismissed find away: its kind, its account and its name.
  final String key;

  /// Its operations, the earliest first, one in each month in a row.
  final List<Transaction> times;

  /// Its last operation, which the form of the payment starts as.
  Transaction get latest => times.last;

  /// An expense or an income.
  TransactionKind get kind => latest.kind;

  /// The account it moves money on.
  String get accountId => latest.entries.single.accountId;

  /// What its last operation is called.
  String get name => latest.note.trim();

  /// The day of the month it falls on: the middle one of its days.
  int get day {
    final days = [for (final time in times) time.occurredOn.day]..sort();
    return days[days.length ~/ 2];
  }

  /// What each time moved, the earliest first.
  List<Money> get amounts => [
    for (final time in times) time.entries.single.amount.abs(),
  ];

  /// Whether the amount changed from one month to another, as a bill's does.
  bool get varies => amounts.toSet().length > 1;

  /// The amount it moves: the last one, or about what the months moved when
  /// it changes, rounded as a person would say it.
  Money get amount {
    if (!varies) return amounts.last;
    final sum = amounts.fold(0, (all, it) => all + it.minorUnits);
    final average = sum ~/ amounts.length;
    final step = _roundStep(average, amounts.last.currency);
    return Money((average / step).round() * step, amounts.last.currency);
  }

  /// The smallest and the largest amount of its times.
  ({Money min, Money max}) get range {
    final sorted = [...amounts]..sort((a, b) => a.compareTo(b));
    return (min: sorted.first, max: sorted.last);
  }

  // A hundred units for the amounts of a thousand and more, ten below.
  static int _roundStep(int minorUnits, Currency currency) {
    var unit = 1;
    for (var i = 0; i < currency.decimalDigits; i++) {
      unit *= 10;
    }
    return minorUnits >= 1000 * unit ? 100 * unit : 10 * unit;
  }
}

/// How many months of history [findRepeats] looks through: enough for three
/// months in a row that end a month and a half ago.
const repeatHistoryMonths = 6;

/// The operations of [history] that came every month on about the same day
/// and have no regular payment among [schedules], apart from the [dismissed]
/// ones, by their keys (ADR 0023, point 23).
///
/// A find is an expense or an income on one account whose notes share a
/// name ([nameKey]), once a month in [months] months in a row or more, the
/// last of them no longer than [recent] days before [today]. Its days keep
/// within [slack] days of the middle one, and its amounts within 30% of each
/// other. A name that comes more than once in a month is everyday spending
/// rather than a payment, and the posts of regular payments are theirs
/// already. The finds come with the most months first.
List<RepeatFind> findRepeats(
  Iterable<Transaction> history, {
  required CivilDate today,
  required List<Schedule> schedules,
  Set<String> dismissed = const {},
  int months = 3,
  int recent = 45,
  int slack = 3,
}) {
  final groups = <String, List<Transaction>>{};
  for (final transaction in history) {
    if (transaction.kind != TransactionKind.expense &&
        transaction.kind != TransactionKind.income) {
      continue;
    }
    if (transaction.source == TransactionSource.recurring ||
        transaction.status == TransactionStatus.planned ||
        transaction.entries.length != 1) {
      continue;
    }
    final name = nameKey(transaction.note);
    if (name.isEmpty) continue;
    final key = findKey(
      transaction.kind,
      transaction.entries.single.accountId,
      transaction.note,
    );
    (groups[key] ??= []).add(transaction);
  }

  int monthOf(CivilDate day) => day.year * 12 + day.month - 1;
  final finds = <RepeatFind>[];
  for (final MapEntry(:key, value: all) in groups.entries) {
    if (dismissed.contains(key)) continue;
    final byMonth = <int, List<Transaction>>{};
    for (final transaction in all) {
      (byMonth[monthOf(transaction.occurredOn)] ??= []).add(transaction);
    }
    // More than once in some month: a shop, not a payment.
    if (byMonth.values.any((list) => list.length > 1)) continue;
    final last = byMonth.keys.reduce((a, b) => a > b ? a : b);
    final run = <Transaction>[];
    for (var month = last; byMonth.containsKey(month); month--) {
      run.insert(0, byMonth[month]!.single);
    }
    if (run.length < months) continue;
    if (run.last.occurredOn.daysUntil(today) > recent) continue;
    final find = RepeatFind(key, run);
    if (run.any((it) => (it.occurredOn.day - find.day).abs() > slack)) {
      continue;
    }
    final range = find.range;
    if (range.min.minorUnits <= 0 ||
        range.max.minorUnits * 10 > range.min.minorUnits * 13) {
      continue;
    }
    if (_paid(find, schedules)) continue;
    finds.add(find);
  }
  finds.sort((a, b) {
    final byMonths = b.times.length.compareTo(a.times.length);
    return byMonths != 0 ? byMonths : a.name.compareTo(b.name);
  });
  return finds;
}

/// The key of a find of an operation of [kind] on [accountId] called [note]:
/// what a dismissal remembers.
String findKey(TransactionKind kind, String accountId, String note) =>
    '${kind.name}|$accountId|${nameKey(note)}';

/// Whether a regular payment of [schedules] already stands for [find]: one
/// made from one of its operations, one that one of them was the last time
/// of, or one of its name on its account.
bool _paid(RepeatFind find, List<Schedule> schedules) {
  final ids = {for (final time in find.times) time.id};
  final name = nameKey(find.name);
  return schedules.any(
    (schedule) =>
        ids.contains(schedule.madeFrom) ||
        ids.contains(schedule.last?.transactionId) ||
        (schedule.kind == find.kind &&
            schedule.accountId == find.accountId &&
            nameKey(schedule.name) == name),
  );
}
