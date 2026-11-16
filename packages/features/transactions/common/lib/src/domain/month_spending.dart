import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:rates/rates.dart';

/// The expenses of a month by top category and day, with the rates that
/// count them in the currency of a limit (ADR 0033).
@immutable
final class MonthSpending {
  /// Creates the spending of the month that starts on [month].
  const MonthSpending({
    required this.month,
    this.rows = const [],
    this.rates = const RateBook.empty(),
  });

  /// The first day of the month.
  final CivilDate month;

  /// The expenses by top category and day.
  final List<CategoryDayTotal> rows;

  /// The rates of the Bank of Russia by day.
  final RateBook rates;

  /// Whether [day] falls in this month.
  bool covers(CivilDate day) =>
      day.compareTo(month) >= 0 && day.compareTo(month.addMonths(1)) < 0;
}
