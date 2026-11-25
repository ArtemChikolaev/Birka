import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Where a метка stands in the list of метки (ADR 0027).
enum TagShelf {
  /// A trip that goes on today.
  now,

  /// A trip ahead or behind.
  trips,

  /// A метка without days.
  plain,
}

/// The shelf of [tag] on [today].
TagShelf shelfOf(Tag tag, CivilDate today) {
  final days = tag.days;
  if (days == null) return TagShelf.plain;
  return days.contains(today) ? TagShelf.now : TagShelf.trips;
}

/// What a метка took, as the list of метки shows it.
@immutable
final class TagSummary {
  /// Creates the summary of [tag].
  const TagSummary({
    required this.tag,
    required this.count,
    required this.total,
  });

  /// The метка.
  final Tag tag;

  /// How many operations wear it.
  final int count;

  /// Its expenses in the base currency, each at the rate of its day, without
  /// those that have no rate.
  final Money total;

  @override
  bool operator ==(Object other) =>
      other is TagSummary &&
      other.tag == tag &&
      other.count == count &&
      other.total == total;

  @override
  int get hashCode => Object.hash(tag, count, total);
}

/// The summaries of [tags], in their order, from the transactions that wear
/// them, [tagged], with totals in [base] at [rates].
List<TagSummary> summarize(
  List<Tag> tags,
  List<Transaction> tagged, {
  required RateBook rates,
  required Currency base,
}) {
  final worn = <String, List<Transaction>>{};
  for (final transaction in tagged) {
    for (final id in transaction.tagIds) {
      (worn[id] ??= []).add(transaction);
    }
  }
  return [
    for (final tag in tags)
      TagSummary(
        tag: tag,
        count: worn[tag.id]?.length ?? 0,
        total: _total(
          _parts(worn[tag.id] ?? const [], const {}),
          rates,
          base,
        ).$1,
      ),
  ];
}

/// What the expenses in one currency came to.
@immutable
final class TagCurrencyPart {
  /// Creates the part of [amount].
  const TagCurrencyPart({
    required this.amount,
    required this.inBase,
    required this.count,
    required this.there,
    this.only,
  });

  /// What they came to in their currency.
  final Money amount;

  /// The same in the base currency, each at the rate of its day, or `null`
  /// without a rate.
  final Money? inBase;

  /// How many expenses were in it.
  final int count;

  /// How many of them fell on the days of the trip.
  final int there;

  /// The one expense in it, when there is only one.
  final Transaction? only;
}

/// What the expenses of one category came to.
@immutable
final class TagCategoryPart {
  /// Creates the part of [category].
  const TagCategoryPart({
    required this.category,
    required this.total,
    required this.percent,
    required this.fraction,
  });

  /// The category, never a subcategory, or `null` for what waits for one.
  final Category? category;

  /// What they came to in the base currency.
  final Money total;

  /// The share of the whole in percent; the parts add up to 100.
  final int percent;

  /// The part of the biggest category, from 0 to 1, as the bars of the
  /// reports measure.
  final double fraction;
}

/// The three civil-date ranges of a trip.
enum TripPeriod {
  /// Dates before departure.
  before,

  /// Departure through the last day, inclusive.
  during,

  /// Dates following the last day.
  after
  ;

  static TripPeriod _of(CivilDate day, TagDays days) {
    if (days.contains(day)) return during;
    return day.compareTo(days.first) < 0 ? before : after;
  }
}

/// Tagged expenses in one period, valued at the rates of their own days.
@immutable
final class TripSpending {
  const TripSpending._(this.period, this.count, this.total, this.converted);

  /// The period relative to the trip dates.
  final TripPeriod period;

  /// Number of expense transactions, including any without a rate.
  final int count;

  /// The full amount, or null if any expense lacks a historical rate.
  final Money? total;

  /// Whether at least one expense was in a different currency.
  final bool converted;
}

/// What a метка took, in every currency and by category (ADR 0027).
@immutable
final class TagReport {
  /// Creates a report.
  const TagReport({
    required this.tag,
    required this.base,
    required this.total,
    required this.missingRates,
    required this.currencies,
    required this.categories,
    required this.operations,
    required this.there,
    required this.before,
    required this.after,
    required this.elapsed,
    this.periods = const [],
    this.perDay,
    this.perDayLocal,
    this.perMonth,
    this.span = 0,
    this.first,
    this.last,
  });

  /// The метка.
  final Tag tag;

  /// The currency of the totals.
  final Currency base;

  /// Its expenses in [base], each at the rate of its day.
  final Money total;

  /// Whether some expenses have no rate and stay out of [total].
  final bool missingRates;

  /// The expenses by currency, the biggest first.
  final List<TagCurrencyPart> currencies;

  /// The expenses by category, the biggest first.
  final List<TagCategoryPart> categories;

  /// Before, during and after a trip with at least one expense.
  final List<TripSpending> periods;

  /// The operations that wear it, the latest first.
  final List<Transaction> operations;

  /// How many operations fell on the days of the trip.
  final int there;

  /// How many came before its days, such as the tickets.
  final int before;

  /// How many came after them.
  final int after;

  /// The days of the trip so far, or 0 before it starts or without days.
  final int elapsed;

  /// What a day on the spot took so far in [base]: the expenses of its days
  /// over [elapsed].
  final Money? perDay;

  /// The same in the currency that took the most on the spot, when it is not
  /// [base], at the latest rate.
  final Money? perDayLocal;

  /// What 30 days took, for a метка without days whose operations span more
  /// than that.
  final Money? perMonth;

  /// The days from its first operation to its latest, both included.
  final int span;

  /// The day of its first operation.
  final CivilDate? first;

  /// The day of its latest operation.
  final CivilDate? last;

  /// Whether nothing wears it yet.
  bool get isEmpty => operations.isEmpty;
}

/// The report of [tag] from [operations] that wear it, the latest first, with
/// totals in [base] at [rates] on [today]. Subcategories count in their
/// parents among [categories].
TagReport reportOf({
  required Tag tag,
  required List<Transaction> operations,
  required List<Category> categories,
  required RateBook rates,
  required Currency base,
  required CivilDate today,
}) {
  final byId = {for (final category in categories) category.id: category};
  final parts = _parts(operations, byId);
  final (total, missing) = _total(parts, rates, base);
  final days = tag.days;

  final byPeriod = <TripPeriod, List<Transaction>>{};
  if (days != null) {
    for (final operation in operations) {
      final period = TripPeriod._of(operation.occurredOn, days);
      (byPeriod[period] ??= []).add(operation);
    }
  }

  final currencies = _currencies(operations, rates, base, days);
  final categoryParts = _categories(parts, rates, base);

  var elapsed = 0;
  Money? perDay;
  Money? perDayLocal;
  if (days != null && today.compareTo(days.first) >= 0) {
    final end = today.compareTo(days.last) < 0 ? today : days.last;
    elapsed = days.first.daysUntil(end) + 1;
    final spot = [
      for (final part in parts)
        if (days.contains(part.day)) part,
    ];
    final (spent, _) = _total(spot, rates, base);
    if (spent.isPositive) {
      perDay = spent.split(elapsed).first;
      final local = _localCurrency(spot, rates, base);
      if (local != null) perDayLocal = rates.convert(perDay, local);
    }
  }

  final first = operations.lastOrNull?.occurredOn;
  final last = operations.firstOrNull?.occurredOn;
  final span = first == null || last == null ? 0 : first.daysUntil(last) + 1;
  Money? perMonth;
  if (days == null && span > 30 && total.isPositive) {
    perMonth = total.allocate([30, span - 30]).first;
  }

  return TagReport(
    tag: tag,
    base: base,
    total: total,
    missingRates: missing,
    currencies: currencies,
    categories: categoryParts,
    operations: operations,
    there: days == null
        ? operations.length
        : byPeriod[TripPeriod.during]?.length ?? 0,
    before: byPeriod[TripPeriod.before]?.length ?? 0,
    after: byPeriod[TripPeriod.after]?.length ?? 0,
    periods: [
      if (days != null && currencies.isNotEmpty)
        for (final period in TripPeriod.values)
          _spending(period, byPeriod[period] ?? const [], rates, base),
    ],
    elapsed: elapsed,
    perDay: perDay,
    perDayLocal: perDayLocal,
    perMonth: perMonth,
    span: span,
    first: first,
    last: last,
  );
}

/// The parts of the expenses of [transactions] by category and day, with
/// subcategories in their parents from [categories].
List<CategoryDayTotal> _parts(
  List<Transaction> transactions,
  Map<String, Category> categories,
) => [
  for (final transaction in transactions)
    if (transaction.kind == TransactionKind.expense)
      for (final allocation in transaction.allocations)
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

/// What [parts] come to in [base], and whether some had no rate and stayed
/// out.
(Money, bool) _total(
  List<CategoryDayTotal> parts,
  RateBook rates,
  Currency base,
) {
  final all = rates.sumOfDays(parts, base);
  if (all != null) return (all, false);
  final known = [
    for (final part in parts)
      if (rates.convert(part.total, base, on: part.day) != null) part,
  ];
  return (rates.sumOfDays(known, base) ?? Money.zero(base), true);
}

CategoryDayTotal _expenseOnDay(Transaction expense) =>
    CategoryDayTotal(null, expense.occurredOn, -expense.entries.first.amount);

TripSpending _spending(
  TripPeriod period,
  List<Transaction> operations,
  RateBook rates,
  Currency base,
) {
  final expenses = [
    for (final operation in operations)
      if (operation.kind == TransactionKind.expense) _expenseOnDay(operation),
  ];
  return TripSpending._(
    period,
    expenses.length,
    rates.sumOfDays(expenses, base),
    expenses.any((expense) => expense.total.currency != base),
  );
}

List<TagCurrencyPart> _currencies(
  List<Transaction> operations,
  RateBook rates,
  Currency base,
  TagDays? days,
) {
  final spent = <Currency, List<Transaction>>{};
  for (final operation in operations) {
    if (operation.kind != TransactionKind.expense) continue;
    final currency = operation.entries.first.amount.currency;
    (spent[currency] ??= []).add(operation);
  }
  final parts = [
    for (final MapEntry(key: currency, value: expenses) in spent.entries)
      _currencyPart(currency, expenses, rates, base, days),
  ];
  int compare(TagCurrencyPart a, TagCurrencyPart b) {
    final first = a.inBase?.minorUnits ?? 0;
    final second = b.inBase?.minorUnits ?? 0;
    return second.compareTo(first);
  }

  return parts..sort(compare);
}

TagCurrencyPart _currencyPart(
  Currency currency,
  List<Transaction> expenses,
  RateBook rates,
  Currency base,
  TagDays? days,
) {
  var amount = Money.zero(currency);
  final rows = <CategoryDayTotal>[];
  var there = 0;
  for (final expense in expenses) {
    final row = _expenseOnDay(expense);
    amount += row.total;
    rows.add(row);
    if (days == null || days.contains(expense.occurredOn)) there++;
  }
  return TagCurrencyPart(
    amount: amount,
    inBase: rates.sumOfDays(rows, base),
    count: expenses.length,
    there: there,
    only: expenses.length == 1 ? expenses.single : null,
  );
}

List<TagCategoryPart> _categories(
  List<CategoryDayTotal> parts,
  RateBook rates,
  Currency base,
) {
  final grouped = <String?, List<CategoryDayTotal>>{};
  final categories = <String?, Category?>{};
  for (final part in parts) {
    final id = part.category?.id;
    (grouped[id] ??= []).add(part);
    categories[id] = part.category;
  }
  final totals = [
    for (final MapEntry(key: id, value: rows) in grouped.entries)
      (
        categories[id],
        rates.sumOfDays(rows, base) ?? _known(rows, rates, base),
      ),
  ]..sort((a, b) => b.$2.minorUnits.compareTo(a.$2.minorUnits));
  final whole = totals.fold(0, (sum, it) => sum + it.$2.minorUnits);
  final biggest = totals.firstOrNull?.$2.minorUnits ?? 0;
  final percents = _percents([
    for (final it in totals) it.$2.minorUnits,
  ], whole);
  return [
    for (final (i, (category, total)) in totals.indexed)
      TagCategoryPart(
        category: category,
        total: total,
        percent: percents[i],
        fraction: biggest <= 0 ? 0 : total.minorUnits / biggest,
      ),
  ];
}

Money _known(List<CategoryDayTotal> rows, RateBook rates, Currency base) =>
    _total(rows, rates, base).$1;

/// Whole percents of [whole] that add up to 100: the floors, and one more for
/// the biggest remainders.
List<int> _percents(List<int> amounts, int whole) {
  if (whole <= 0) return [for (final _ in amounts) 0];
  final floors = [for (final amount in amounts) amount * 100 ~/ whole];
  final rest = [for (final amount in amounts) amount * 100 % whole];
  var left = 100 - floors.fold(0, (sum, it) => sum + it);
  final order = [for (var i = 0; i < amounts.length; i++) i]
    ..sort((a, b) => rest[b].compareTo(rest[a]));
  for (final i in order) {
    if (left <= 0) break;
    floors[i]++;
    left--;
  }
  return floors;
}

/// The currency that took the most on the spot, when it is not [base].
Currency? _localCurrency(
  List<CategoryDayTotal> spot,
  RateBook rates,
  Currency base,
) {
  final byCurrency = <Currency, List<CategoryDayTotal>>{};
  for (final part in spot) {
    (byCurrency[part.total.currency] ??= []).add(part);
  }
  Currency? most;
  var biggest = -1;
  for (final MapEntry(key: currency, value: rows) in byCurrency.entries) {
    final inBase = rates.sumOfDays(rows, base)?.minorUnits ?? -1;
    if (inBase > biggest) {
      biggest = inBase;
      most = currency;
    }
  }
  return most == base ? null : most;
}
