import 'package:ask_common/src/domain/ask_period.dart';
import 'package:ask_common/src/domain/ask_query.dart';
import 'package:ask_common/src/domain/ask_words.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// What one stretch of the days of an answer took: a day, a week, a month
/// or a year.
@immutable
final class AskBar {
  /// Creates the bar of the days from [first] to [last].
  const AskBar(this.first, this.last, this.total, {this.top = false});

  /// The first day.
  final CivilDate first;

  /// The last day.
  final CivilDate last;

  /// What the days took, in the currency of the answer.
  final Money total;

  /// Whether it is the biggest of the bars.
  final bool top;

  /// What one bar takes: [AskBarSpan.day] and up.
  AskBarSpan get span => switch (first.daysUntil(last)) {
    0 => AskBarSpan.day,
    < 7 => AskBarSpan.week,
    < 31 => AskBarSpan.week,
    < 366 => AskBarSpan.month,
    _ => AskBarSpan.year,
  };
}

/// What one bar of an answer takes.
enum AskBarSpan {
  /// A day.
  day,

  /// A week, or the part of one at an end of the period.
  week,

  /// A month.
  month,

  /// A year.
  year,
}

/// An operation that an answer counts.
@immutable
final class AskOperation {
  /// Creates the operation of [transaction], which counts [amount].
  const AskOperation(this.transaction, this.amount, this.counted);

  /// The operation.
  final Transaction transaction;

  /// What it counts, above zero, in its own currency: the parts of its
  /// categories that the question keeps.
  final Money amount;

  /// What [amount] came to in the currency of the answer at the rate of its
  /// day, or `null` while that rate is missing.
  final Money? counted;
}

/// What one category took of an answer.
@immutable
final class AskShare {
  /// Creates the share of [category], or of what waits for one.
  const AskShare(this.category, this.total, this.percent);

  /// The category, or `null` for what waits for one.
  final Category? category;

  /// What it took, in the currency of the answer.
  final Money total;

  /// Its part of the whole, in percent.
  final int percent;
}

/// What the ledger says to a question about money (ADR 0028).
@immutable
final class AskAnswer {
  /// Creates an answer.
  const AskAnswer({
    required this.query,
    required this.total,
    this.count = 0,
    this.average,
    this.before,
    this.bars = const [],
    this.biggest = const [],
    this.shares = const [],
    this.operations = const [],
    this.partial = false,
  });

  /// The question it answers, with the period it counted.
  final AskQuery query;

  /// What the operations came to, in the currency of the answer, each at the
  /// rate of its day.
  final Money total;

  /// How many operations it counted.
  final int count;

  /// What one operation came to on average.
  final Money? average;

  /// What the same stretch right before came to, for a comparison.
  final Money? before;

  /// What each stretch of the period took, when there are at least two.
  final List<AskBar> bars;

  /// The biggest operations, the biggest first.
  final List<AskOperation> biggest;

  /// What each category took, the biggest first, when the question does not
  /// keep one category.
  final List<AskShare> shares;

  /// Every operation it counted, the latest first.
  final List<AskOperation> operations;

  /// Whether some amounts stayed out for want of a rate.
  final bool partial;

  /// The currency of the answer.
  Currency get currency => total.currency;
}

/// Counts [query] over [transactions], in [currency] at the rate of the day
/// of each operation (ADR 0028). [transactions] cover its period and the
/// stretch right before it, which gives the comparison.
AskAnswer answerOf(
  AskQuery query, {
  required List<Transaction> transactions,
  required List<Category> categories,
  required RateBook rates,
  required Currency currency,
}) {
  final byId = {for (final category in categories) category.id: category};
  final period = query.period;
  final matching = _matching(query, transactions, byId, rates, currency);
  final now = [
    for (final operation in matching)
      if (period == null || period.contains(operation.transaction.occurredOn))
        operation,
  ];
  final rows = _rows(now, query, byId);
  final (total, partial) = _sum(rows, rates, currency);
  final earlier = period?.before;
  final before = earlier == null
      ? null
      : _sum(
          _rows(
            [
              for (final operation in matching)
                if (earlier.contains(operation.transaction.occurredOn))
                  operation,
            ],
            query,
            byId,
          ),
          rates,
          currency,
        ).$1;
  final biggest = [...now]..sort(_bySize);
  return AskAnswer(
    query: query,
    total: total,
    count: now.length,
    average: now.isEmpty ? null : total.split(now.length).first,
    before: before,
    bars: _bars(rows, period ?? _spanOf(now), rates, currency),
    biggest: biggest.take(3).toList(),
    shares: query.categoryIds.length == 1
        ? const []
        : _shares(rows, total, rates, currency),
    operations: now,
    partial: partial,
  );
}

/// The day of the first and of the last of [operations], or `null`.
AskPeriod? _spanOf(List<AskOperation> operations) {
  if (operations.isEmpty) return null;
  var first = operations.first.transaction.occurredOn;
  var last = first;
  for (final AskOperation(:transaction) in operations) {
    final day = transaction.occurredOn;
    if (day.compareTo(first) < 0) first = day;
    if (day.compareTo(last) > 0) last = day;
  }
  return AskPeriod.range(first, last);
}

List<AskOperation> _matching(
  AskQuery query,
  List<Transaction> transactions,
  Map<String, Category> categories,
  RateBook rates,
  Currency currency,
) {
  final kind = query.side == AskSide.income
      ? TransactionKind.income
      : TransactionKind.expense;
  final found = <AskOperation>[];
  for (final transaction in transactions) {
    if (transaction.kind != kind) continue;
    if (transaction.status == TransactionStatus.planned) continue;
    final tag = query.tagId;
    if (tag != null && !transaction.tagIds.contains(tag)) continue;
    final account = query.accountId;
    if (account != null &&
        !transaction.entries.any((entry) => entry.accountId == account)) {
      continue;
    }
    if (!_holds(transaction.note, query.words)) continue;
    final parts = [
      for (final allocation in transaction.allocations)
        if (_keeps(query, allocation.categoryId, categories)) allocation.amount,
    ];
    if (parts.isEmpty) continue;
    final amount = parts.reduce((a, b) => a + b);
    final day = transaction.occurredOn;
    if (!_fits(amount, day, query, rates)) continue;
    found.add(
      AskOperation(
        transaction,
        amount,
        rates.convert(amount, currency, on: day),
      ),
    );
  }
  return found;
}

bool _keeps(AskQuery query, String? id, Map<String, Category> categories) {
  final wanted = query.categoryIds;
  if (wanted.isEmpty) return true;
  if (id == null) return false;
  return wanted.contains(id) || wanted.contains(categories[id]?.parentId);
}

/// Whether [note] holds every word of [words], in any form of it.
bool _holds(String note, List<String> words) {
  if (words.isEmpty) return true;
  final noted = [for (final token in askTokens(note)) token.text];
  return words.every(
    (word) => noted.any((other) => wordMatch(word, other) >= 2),
  );
}

/// Whether [amount] of [day] is above and below the bounds of [query], in
/// their currencies at the rate of the day. Without the rate it is not.
bool _fits(Money amount, CivilDate day, AskQuery query, RateBook rates) {
  final above = query.above;
  if (above != null) {
    final there = rates.convert(amount, above.currency, on: day);
    if (there == null || there <= above) return false;
  }
  final below = query.below;
  if (below != null) {
    final there = rates.convert(amount, below.currency, on: day);
    if (there == null || there >= below) return false;
  }
  return true;
}

/// The parts of [operations] by category and day, with subcategories in
/// their parents unless the question names the subcategory itself.
List<CategoryDayTotal> _rows(
  List<AskOperation> operations,
  AskQuery query,
  Map<String, Category> categories,
) => [
  for (final AskOperation(:transaction) in operations)
    for (final allocation in transaction.allocations)
      if (_keeps(query, allocation.categoryId, categories))
        CategoryDayTotal(
          _topOf(allocation.categoryId, categories),
          transaction.occurredOn,
          allocation.amount,
        ),
];

Category? _topOf(String? id, Map<String, Category> categories) {
  final category = categories[id];
  if (category == null) return null;
  return categories[category.parentId] ?? category;
}

/// What [rows] come to in [currency], and whether some had no rate and
/// stayed out.
(Money, bool) _sum(
  List<CategoryDayTotal> rows,
  RateBook rates,
  Currency currency,
) {
  final all = rates.sumOfDays(rows, currency);
  if (all != null) return (all, false);
  final known = [
    for (final row in rows)
      if (rates.convert(row.total, currency, on: row.day) != null) row,
  ];
  return (rates.sumOfDays(known, currency) ?? Money.zero(currency), true);
}

int _bySize(AskOperation a, AskOperation b) {
  final first = a.counted?.minorUnits ?? -1;
  final second = b.counted?.minorUnits ?? -1;
  final size = second.compareTo(first);
  if (size != 0) return size;
  return b.transaction.occurredOn.compareTo(a.transaction.occurredOn);
}

/// The bars of [period]: days for a week, weeks from Monday for up to two
/// months, months for up to two years, and years beyond. A period of one
/// stretch has none.
List<AskBar> _bars(
  List<CategoryDayTotal> rows,
  AskPeriod? period,
  RateBook rates,
  Currency currency,
) {
  if (period == null) return const [];
  final days = period.days;
  final stretches = <(CivilDate, CivilDate)>[];
  var start = period.first;
  while (start.compareTo(period.last) <= 0) {
    final CivilDate end;
    if (days <= 7) {
      end = start;
    } else if (days <= 62) {
      end = start.addDays(7 - start.weekday);
    } else if (days <= 731) {
      end = CivilDate(start.year, start.month, 1).addMonths(1).addDays(-1);
    } else {
      end = CivilDate(start.year, 12, 31);
    }
    final last = end.compareTo(period.last) < 0 ? end : period.last;
    stretches.add((start, last));
    start = last.addDays(1);
  }
  if (stretches.length < 2) return const [];
  final totals = [
    for (final (first, last) in stretches)
      _sum(
        [
          for (final row in rows)
            if (first.compareTo(row.day) <= 0 && row.day.compareTo(last) <= 0)
              row,
        ],
        rates,
        currency,
      ).$1,
  ];
  final top = totals.fold(Money.zero(currency), (a, b) => b > a ? b : a);
  return [
    for (final (i, (first, last)) in stretches.indexed)
      AskBar(
        first,
        last,
        totals[i],
        top: totals[i].isPositive && totals[i] == top,
      ),
  ];
}

List<AskShare> _shares(
  List<CategoryDayTotal> rows,
  Money total,
  RateBook rates,
  Currency currency,
) {
  if (!total.isPositive) return const [];
  return [
    for (final CategoryTotal(:category, total: part) in totalsIn(
      currency,
      rows,
      rates,
    ))
      if (part.currency == currency)
        AskShare(
          category,
          part,
          (part.minorUnits * 100 / total.minorUnits).round(),
        ),
  ];
}
