import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// A civil day with recorded activity and its totals in original currencies.
typedef ReportDay = ({CivilDate day, List<Money> amounts});

/// The latest active days shown before opening the full month.
const reportDayPreviewCount = 3;

/// Groups the selected month's category allocations by civil date and currency.
List<ReportDay> reportDays(Iterable<CategoryDayTotal> rows) {
  final amountsByDay = <CivilDate, List<Money>>{};
  for (final row in rows) {
    if (row.total.isPositive) (amountsByDay[row.day] ??= []).add(row.total);
  }
  final dates = amountsByDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in dates)
      (
        day: day,
        amounts: sumByCurrency(amountsByDay[day]!)
          ..sort((a, b) {
            final code = a.currency.code.compareTo(b.currency.code);
            return code == 0
                ? a.currency.decimalDigits.compareTo(b.currency.decimalDigits)
                : code;
          }),
      ),
  ];
}

/// A category of a report.
@immutable
final class ReportLine {
  /// Creates a line.
  const ReportLine({
    required this.category,
    required this.total,
    required this.share,
    this.change,
  });

  /// The category, or `null` for what waits for one.
  final Category? category;

  /// What went through it this month.
  final Money total;

  /// How long its bar is against the biggest category, from 0 to 1.
  final double share;

  /// How it changed against the month before in percent, or `null` when there
  /// was nothing to compare with.
  final int? change;
}

/// A category's signed change in the currency of the report.
typedef CategoryChange = ({Category? category, Money delta});

/// The three largest changes by magnitude. A category with money that could
/// not be converted in either period cannot be compared as a whole.
List<CategoryChange> biggestCategoryChanges({
  required List<CategoryTotal> current,
  required List<CategoryTotal> previous,
  required Currency currency,
}) {
  final incomplete = {
    for (final row in [...current, ...previous])
      if (row.total.currency != currency) categoryKey(row.category),
  };
  Map<String, CategoryTotal> comparable(List<CategoryTotal> rows) => {
    for (final row in rows)
      if (!incomplete.contains(categoryKey(row.category)))
        categoryKey(row.category): row,
  };
  final before = comparable(previous);
  if (before.isEmpty) return const [];
  final after = comparable(current);
  final zero = Money.zero(currency);
  final changes = <CategoryChange>[];
  for (final id in {...after.keys, ...before.keys}) {
    final now = after[id];
    final then = before[id];
    final delta = (now?.total ?? zero) - (then?.total ?? zero);
    if (!delta.isZero) {
      changes.add((category: (now ?? then!).category, delta: delta));
    }
  }
  changes.sort((a, b) {
    final size = b.delta.minorUnits.abs().compareTo(a.delta.minorUnits.abs());
    return size != 0
        ? size
        : categoryKey(a.category).compareTo(categoryKey(b.category));
  });
  return changes.take(3).toList();
}

/// A month in the row of bars of a report.
@immutable
final class ReportMonth {
  /// Creates a month.
  const ReportMonth(this.month, this.total);

  /// The first day of the month.
  final CivilDate month;

  /// What went through it.
  final Money total;
}

/// What a month took or brought. Amounts in different currencies stay apart
/// until exchange rates can add them up, so a report follows one currency.
@immutable
final class Report {
  /// Creates a report.
  const Report({
    this.total,
    this.change,
    this.lines = const [],
    this.others = const [],
    this.months = const [],
    this.average,
  });

  /// Builds the report of the month that starts on [month] from what went
  /// through it, what to compare it with and the totals of months.
  /// The report follows the currency of [rows], or [preferred] when they are
  /// empty.
  factory Report.of({
    required CivilDate month,
    required List<CategoryTotal> rows,
    required List<CategoryTotal> previousRows,
    required List<MonthTotal> monthTotals,
    Currency? preferred,
  }) {
    final currency =
        mainCurrencyOf(rows, preferred: preferred) ??
        preferred ??
        monthTotals.lastOrNull?.total.currency;
    if (currency == null) return const Report();

    final kept = [
      for (final row in rows)
        if (row.total.currency == currency) row,
    ];
    final before = {
      for (final row in previousRows)
        if (row.total.currency == currency)
          categoryKey(row.category): row.total.minorUnits,
    };
    final biggest = kept.firstOrNull?.total.minorUnits ?? 0;
    final history = ReportHistory.of(month, monthTotals, currency);

    return Report(
      total: kept.isEmpty
          ? null
          : _money(_sum(kept.map((row) => row.total.minorUnits)), currency),
      change: _change(
        _sum(kept.map((row) => row.total.minorUnits)),
        _sum(before.values),
      ),
      lines: [
        for (final CategoryTotal(:category, :total) in kept)
          ReportLine(
            category: category,
            total: total,
            share: total.minorUnits / biggest,
            change: _change(
              total.minorUnits,
              before[categoryKey(category)] ?? 0,
            ),
          ),
      ],
      others: _others(rows, currency),
      months: history.months,
      average: history.average,
    );
  }

  /// How many months stand in the row of bars.
  static const monthCount = 6;

  /// What the month came to in the currency of the report.
  final Money? total;

  /// How [total] changed against the month before in percent, or `null` when
  /// there was nothing to compare with.
  final int? change;

  /// The categories, the biggest first.
  final List<ReportLine> lines;

  /// What went through other currencies this month.
  final List<Money> others;

  /// The last [monthCount] months in the currency of the report, the earliest
  /// first. The last one is the month of the report.
  final List<ReportMonth> months;

  /// What a month with anything in it comes to on average.
  final Money? average;

  /// Whether nothing went through the month in the currency of the report.
  bool get isEmpty => lines.isEmpty;

  static List<Money> _others(List<CategoryTotal> rows, Currency currency) {
    final sums = <Currency, int>{};
    for (final CategoryTotal(:total) in rows) {
      if (total.currency == currency) continue;
      sums[total.currency] = (sums[total.currency] ?? 0) + total.minorUnits;
    }
    return [
      for (final MapEntry(key: other, value: sum) in sums.entries)
        _money(sum, other),
    ];
  }

  static int? _change(int now, int before) =>
      before == 0 ? null : ((now - before) * 100 / before).round();

  static int _sum(Iterable<int> values) =>
      values.fold(0, (sum, value) => sum + value);

  static Money _money(int minorUnits, Currency currency) => Money(
    minorUnits.clamp(0, Money.maxMinorUnits),
    currency,
  );
}

/// The six bars and the average over months with activity in one currency.
@immutable
final class ReportHistory {
  /// Creates a series with its average.
  const ReportHistory(this.months, this.average);

  /// Pads missing months with zero and averages the months with activity.
  factory ReportHistory.of(
    CivilDate month,
    List<MonthTotal> totals,
    Currency currency,
  ) {
    final byMonth = {
      for (final row in totals)
        if (row.total.currency == currency) row.month: row.total,
    };
    final months = [
      for (var back = Report.monthCount - 1; back >= 0; back--)
        monthsBefore(month, back),
    ];
    final bars = [
      for (final date in months)
        ReportMonth(date, byMonth[date] ?? Money.zero(currency)),
    ];
    final filled = bars.where((bar) => bar.total.isPositive);
    // Six valid amounts can sum beyond the exact integer range in JavaScript.
    final sum = filled.fold(
      BigInt.zero,
      (n, bar) => n + BigInt.from(bar.total.minorUnits),
    );
    return ReportHistory(
      bars,
      filled.isEmpty
          ? null
          : Money((sum ~/ BigInt.from(filled.length)).toInt(), currency),
    );
  }

  /// One bar per month, the earliest first.
  final List<ReportMonth> months;

  /// Average over months with activity, or null for six empty months.
  final Money? average;
}

/// The first day of the month [count] months before the one of [month].
CivilDate monthsBefore(CivilDate month, int count) => month.addMonths(-count);

/// The last day of the month of [month].
CivilDate lastDayOf(CivilDate month) => month.addMonths(1).addDays(-1);
