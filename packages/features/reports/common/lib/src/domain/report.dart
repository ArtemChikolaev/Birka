import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

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

  /// The category.
  final Category category;

  /// What went through it this month.
  final Money total;

  /// How long its bar is against the biggest category, from 0 to 1.
  final double share;

  /// How it changed against the month before in percent, or `null` when there
  /// was nothing to compare with.
  final int? change;
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
          row.category.id: row.total.minorUnits,
    };
    final biggest = kept.firstOrNull?.total.minorUnits ?? 0;
    final months = _monthsUpTo(month, monthTotals, currency);
    final filled = months.where((it) => it.total.isPositive).toList();

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
            change: _change(total.minorUnits, before[category.id] ?? 0),
          ),
      ],
      others: _others(rows, currency),
      months: months,
      average: filled.isEmpty
          ? null
          : _money(
              _sum(filled.map((it) => it.total.minorUnits)) ~/ filled.length,
              currency,
            ),
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

  static List<ReportMonth> _monthsUpTo(
    CivilDate month,
    List<MonthTotal> totals,
    Currency currency,
  ) {
    final byMonth = {
      for (final total in totals)
        if (total.total.currency == currency) total.month: total.total,
    };
    return [
      for (var back = monthCount - 1; back >= 0; back--)
        ReportMonth(
          monthsBefore(month, back),
          byMonth[monthsBefore(month, back)] ?? Money.zero(currency),
        ),
    ];
  }

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

/// The first day of the month [count] months before the one of [month].
CivilDate monthsBefore(CivilDate month, int count) =>
    CivilDate.of(DateTime.utc(month.year, month.month - count));

/// The last day of the month of [month].
CivilDate lastDayOf(CivilDate month) =>
    CivilDate.of(DateTime.utc(month.year, month.month + 1, 0));
