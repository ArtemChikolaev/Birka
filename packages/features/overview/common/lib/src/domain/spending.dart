import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// What the month cost, as the first screen shows it.
@immutable
final class Spending {
  /// Creates a summary.
  const Spending({required this.categories, required this.others, this.total});

  /// Sorts [rows], the biggest first. Categories of one currency can share a
  /// ring: that of the [preferred] currency if anything was spent in it, or
  /// else that of the most categories. The rest stays in [others].
  factory Spending.of(List<CategoryTotal> rows, {Currency? preferred}) {
    final main = mainCurrencyOf(rows, preferred: preferred);
    if (main == null) return const Spending(categories: [], others: []);
    final others = <Currency, int>{};
    final categories = <CategoryTotal>[];
    var total = 0;
    for (final row in rows) {
      final amount = row.total;
      if (amount.currency == main) {
        categories.add(row);
        total += amount.minorUnits;
      } else {
        others[amount.currency] =
            (others[amount.currency] ?? 0) + amount.minorUnits;
      }
    }
    return Spending(
      categories: categories,
      total: _money(total, main),
      others: [
        for (final MapEntry(key: currency, value: sum) in others.entries)
          _money(sum, currency),
      ],
    );
  }

  /// How many categories stand by the name under the ring.
  static const shownCategories = 3;

  /// The categories of one currency, the biggest first.
  final List<CategoryTotal> categories;

  /// What they add up to, above zero.
  final Money? total;

  /// What was spent in other currencies.
  final List<Money> others;

  /// Whether nothing was spent.
  bool get isEmpty => categories.isEmpty;

  /// The categories that stand by their names.
  Iterable<CategoryTotal> get top => categories.take(shownCategories);

  static Money _money(int minorUnits, Currency currency) => Money(
    minorUnits.clamp(0, Money.maxMinorUnits),
    currency,
  );
}
