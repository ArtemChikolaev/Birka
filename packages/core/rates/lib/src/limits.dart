import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/src/rate_book.dart';

/// Where the spending of a month stands against its limit (ADR 0033).
enum LimitState {
  /// Less than 80 % of the limit is gone.
  ok,

  /// 80 % or more is gone, but not all of it.
  near,

  /// The month took more than the limit.
  over,
}

/// How much of a category's monthly limit its spending has taken.
@immutable
final class LimitProgress {
  /// Creates the progress of [category], which has a limit.
  const LimitProgress({
    required this.category,
    required this.spent,
    required this.month,
    required this.today,
    this.approximate = false,
    this.unrated = false,
    this.lastsUntil,
  });

  /// The category, with its limit.
  final Category category;

  /// What the month took, in the currency of the limit.
  final Money spent;

  /// The first day of the month.
  final CivilDate month;

  /// The day the progress is counted for.
  final CivilDate today;

  /// Whether part of [spent] came from another currency at a rate.
  final bool approximate;

  /// Whether part of the spending had no rate and is left out of [spent].
  final bool unrated;

  /// The day the limit runs out at the pace of the month so far, when that
  /// comes before the month ends; `null` when it lasts or is gone.
  final CivilDate? lastsUntil;

  /// The limit.
  CategoryLimit get limit => category.limit!;

  /// What is left of the limit, below zero once it is over.
  Money get left => limit.amount - spent;

  /// What part of the limit the month took, above 1 once it is over.
  double get share => limitShare(spent, limit.amount);

  /// Where the month stands.
  LimitState get state => limitStateOf(share);

  /// The share from which a limit is near its end.
  static const nearShare = 0.8;
}

/// What part of [limit] the month took when it [spent] that much, above 1
/// once it is over. Both are in the currency of the limit.
double limitShare(Money spent, Money limit) =>
    spent.minorUnits / limit.minorUnits;

/// Where a month that took [share] of its limit stands: near its end from
/// [LimitProgress.nearShare] and over once it took more than the whole.
LimitState limitStateOf(double share) => share > 1
    ? LimitState.over
    : share >= LimitProgress.nearShare
    ? LimitState.near
    : LimitState.ok;

/// The progress of the limit of [category] in the month that starts on
/// [month], counted on [today] from [rows]: the expenses of the month by day,
/// in the currencies of their accounts. Each row goes into the currency of
/// the limit at the rate of its day; a row without any rate is left out.
LimitProgress limitProgress(
  Category category,
  Iterable<CategoryDayTotal> rows,
  RateBook rates, {
  required CivilDate month,
  required CivilDate today,
}) {
  final limit = category.limit!;
  final currency = limit.amount.currency;
  final own = [
    for (final row in rows)
      if (row.category?.id == category.id &&
          row.day.compareTo(month) >= 0 &&
          row.day.compareTo(today) <= 0)
        row,
  ];
  final known = [
    for (final row in own)
      if (rates.convert(row.total, currency, on: row.day) != null) row,
  ];
  final spent = rates.sumOfDays(known, currency) ?? Money.zero(currency);
  final progress = LimitProgress(
    category: category,
    spent: spent,
    month: month,
    today: today,
    approximate: known.any((row) => row.total.currency != currency),
    unrated: known.length < own.length,
  );
  return LimitProgress(
    category: category,
    spent: spent,
    month: month,
    today: today,
    approximate: progress.approximate,
    unrated: progress.unrated,
    lastsUntil: _lastsUntil(progress),
  );
}

/// At the pace of the days so far, the day [progress] runs out, if that
/// comes before the last day of its month.
CivilDate? _lastsUntil(LimitProgress progress) {
  if (progress.state == LimitState.over || !progress.spent.isPositive) {
    return null;
  }
  final days = progress.month.daysUntil(progress.today) + 1;
  final perDay = progress.spent.minorUnits / days;
  final lasts = progress.left.minorUnits / perDay;
  final end = progress.month.addMonths(1).addDays(-1);
  final runsOut = progress.today.addDays(lasts.floor());
  return runsOut.compareTo(end) < 0 ? runsOut : null;
}

/// The progress of every category of [categories] that has a limit and is
/// not archived: those over their limits first, then the nearest to their
/// ends, each group by the share taken.
List<LimitProgress> limitsProgress(
  Iterable<Category> categories,
  Iterable<CategoryDayTotal> rows,
  RateBook rates, {
  required CivilDate month,
  required CivilDate today,
}) {
  final days = rows.toList();
  return [
    for (final category in categories)
      if (category.limit != null && !category.archived)
        limitProgress(category, days, rates, month: month, today: today),
  ]..sort((a, b) {
    final state = b.state.index.compareTo(a.state.index);
    return state != 0 ? state : b.share.compareTo(a.share);
  });
}

/// Why a suggested limit is offered checked or not.
enum SuggestionReason {
  /// Spending came in every month and the largest is at most twice the
  /// smallest: the limit is offered checked.
  steady,

  /// Spending came in every month but jumps.
  jumps,

  /// Some months had no spending.
  rare,

  /// The category has regular payments, which a limit does not steer.
  regular,
}

/// A limit that Birka offers from the spending of the three full months
/// before this one (ADR 0033).
@immutable
final class LimitSuggestion {
  /// Creates a suggestion for [category].
  const LimitSuggestion({
    required this.category,
    required this.months,
    required this.average,
    required this.offer,
    required this.reason,
  });

  /// The category.
  final Category category;

  /// What each of the three months took, the earliest first.
  final List<Money> months;

  /// What a month took on average.
  final Money average;

  /// [average] rounded up to the step of its currency.
  final Money offer;

  /// Why it comes checked or not.
  final SuggestionReason reason;

  /// Whether it comes checked.
  bool get picked => reason == SuggestionReason.steady;

  /// The smallest of [months].
  Money get least => months.reduce((a, b) => a.compareTo(b) <= 0 ? a : b);

  /// The largest of [months].
  Money get most => months.reduce((a, b) => a.compareTo(b) >= 0 ? a : b);

  /// In how many of the months there was spending.
  int get monthsWithSpending => months.where((m) => m.isPositive).length;
}

/// The three full months before the month that starts on [month]: their
/// first days, the earliest first.
List<CivilDate> fullMonthsBefore(CivilDate month) => [
  for (var back = 3; back >= 1; back--) month.addMonths(-back),
];

/// The limit Birka offers for [category] in [currency], from the expenses in
/// [rows] of the three full months before [month], or `null` when they spent
/// nothing. Pass [regular] for a category with regular payments.
LimitSuggestion? suggestLimit(
  Category category,
  Iterable<CategoryDayTotal> rows,
  RateBook rates, {
  required Currency currency,
  required CivilDate month,
  bool regular = false,
}) {
  final starts = fullMonthsBefore(month);
  final months = [
    for (final start in starts)
      spendingOf(
        category,
        rows,
        rates,
        currency,
        from: start,
        until: start.addMonths(1),
      ),
  ];
  final total = months.fold(0, (sum, m) => sum + m.minorUnits);
  if (total <= 0) return null;
  // The average is about a month, so it is in whole units of its currency.
  final unit = currency.minorUnitsPerMajor;
  final average = Money(
    (total / months.length / unit).round() * unit,
    currency,
  );
  final step = limitStep(rates, currency).minorUnits;
  final offer = Money((average.minorUnits / step).ceil() * step, currency);
  final spending = months.where((m) => m.isPositive).toList();
  final least = spending.fold(
    spending.first,
    (a, b) => a.compareTo(b) <= 0 ? a : b,
  );
  final most = spending.fold(
    spending.first,
    (a, b) => a.compareTo(b) >= 0 ? a : b,
  );
  final reason = regular
      ? SuggestionReason.regular
      : spending.length < months.length
      ? SuggestionReason.rare
      : most.minorUnits > least.minorUnits * 2
      ? SuggestionReason.jumps
      : SuggestionReason.steady;
  return LimitSuggestion(
    category: category,
    months: months,
    average: average,
    offer: offer,
    reason: reason,
  );
}

/// Limits for [categories] in [currency], those offered checked first, each
/// group by the largest average. Categories with a limit, archived ones and
/// those that spent nothing are left out.
List<LimitSuggestion> suggestLimits(
  Iterable<Category> categories,
  Iterable<CategoryDayTotal> rows,
  RateBook rates, {
  required Currency currency,
  required CivilDate month,
  Set<String> regular = const {},
}) {
  final days = rows.toList();
  return [
    for (final category in categories)
      if (category.limit == null &&
          !category.archived &&
          category.kind == CategoryKind.expense &&
          category.parentId == null)
        ?suggestLimit(
          category,
          days,
          rates,
          currency: currency,
          month: month,
          regular: regular.contains(category.id),
        ),
  ]..sort((a, b) {
    if (a.picked != b.picked) return a.picked ? -1 : 1;
    return b.average.compareTo(a.average);
  });
}

/// The step that limits in [currency] are rounded up to: 500 ₽, or the
/// roundest of 1, 2 or 5 times a power of ten not above 500 ₽ in another
/// currency, such as 5 € (ADR 0033).
Money limitStep(RateBook rates, Currency currency) {
  final rubles = Money(50000, Currency.rub);
  final there = rates.convert(rubles, currency);
  final unit = currency.minorUnitsPerMajor;
  if (there == null) return Money(unit, currency);
  final whole = there.minorUnits / unit;
  var step = 1.0;
  while (step * 10 <= whole) {
    step *= 10;
  }
  final nice = whole >= step * 5
      ? step * 5
      : whole >= step * 2
      ? step * 2
      : step;
  return Money((nice * unit).round(), currency);
}

/// What [category] spent in [rows] from [from] up to but not including
/// [until], in [currency] at the rate of each day; rows without any rate are
/// left out.
Money spendingOf(
  Category category,
  Iterable<CategoryDayTotal> rows,
  RateBook rates,
  Currency currency, {
  required CivilDate from,
  required CivilDate until,
}) {
  final known = [
    for (final row in rows)
      if (row.category?.id == category.id &&
          row.day.compareTo(from) >= 0 &&
          row.day.compareTo(until) < 0 &&
          rates.convert(row.total, currency, on: row.day) != null)
        row,
  ];
  return rates.sumOfDays(known, currency) ?? Money.zero(currency);
}

/// The progress of the limit of [category] in the month that starts on
/// [month] once an expense of [amount] on [day] comes in, counted over the
/// whole month: what quick add says the expense leaves (ADR 0033).
LimitProgress limitWith(
  Category category,
  Iterable<CategoryDayTotal> rows,
  RateBook rates, {
  required CivilDate month,
  required Money amount,
  required CivilDate day,
}) {
  final end = month.addMonths(1).addDays(-1);
  return limitProgress(
    category,
    [...rows, CategoryDayTotal(category, day, amount)],
    rates,
    month: month,
    today: end,
  );
}
