import 'package:ledger/src/category.dart';
import 'package:ledger/src/civil_date.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// How much one day changed the accounts that count, in one currency.
@immutable
final class DayChange {
  /// Creates a change of [day].
  const DayChange(this.day, this.change);

  /// The day.
  final CivilDate day;

  /// What the day added, or took away when it is below zero.
  final Money change;
}

/// What went through a category and its subcategories, in one currency.
@immutable
final class CategoryTotal {
  /// Creates a total of [category].
  const CategoryTotal(this.category, this.total);

  /// The category, never a subcategory.
  final Category category;

  /// The amount above zero.
  final Money total;
}

/// What went through the categories of one kind in a month, in one currency.
@immutable
final class MonthTotal {
  /// Creates a total of [month].
  const MonthTotal(this.month, this.total);

  /// The first day of the month.
  final CivilDate month;

  /// The amount above zero.
  final Money total;
}

/// The currency that a report of [rows] follows: [preferred] if anything went
/// through it, or else the one with the most categories. Amounts in different
/// currencies say nothing about each other until there are rates, so only a
/// count decides, and on a tie the code does. Without rows there is none.
Currency? mainCurrencyOf(List<CategoryTotal> rows, {Currency? preferred}) {
  final categories = <Currency, int>{};
  for (final row in rows) {
    categories.update(
      row.total.currency,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }
  if (categories.containsKey(preferred)) return preferred;
  final byCount = categories.keys.toList()
    ..sort((a, b) {
      final order = categories[b]!.compareTo(categories[a]!);
      return order != 0 ? order : a.code.compareTo(b.code);
    });
  return byCount.firstOrNull;
}
