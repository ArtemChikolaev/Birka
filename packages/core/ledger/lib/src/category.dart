import 'package:meta/meta.dart';

/// Whether a category is for spending or for earning.
enum CategoryKind {
  /// For expenses.
  expense,

  /// For income.
  income,
}

/// What money is spent on or earned from.
@immutable
final class Category {
  /// Creates a category.
  const Category({
    required this.id,
    required this.kind,
    required this.name,
    required this.archived,
    required this.sortOrder,
    this.parentId,
    this.icon,
    this.color,
  });

  /// The id.
  final String id;

  /// The parent category, for subcategories.
  final String? parentId;

  /// Whether it is for spending or for earning.
  final CategoryKind kind;

  /// The name the user sees.
  final String name;

  /// The name of the icon.
  final String? icon;

  /// The color as `#rrggbb`.
  final String? color;

  /// Whether the category is hidden from pickers.
  final bool archived;

  /// The place of the category in lists.
  final int sortOrder;
}
