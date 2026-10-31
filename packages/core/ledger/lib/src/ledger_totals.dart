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
