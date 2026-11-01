import 'package:ledger/src/category.dart';
import 'package:meta/meta.dart';

/// A category of the ready set. Its name comes from the strings by [key], in
/// the language of the user when the set is added.
@immutable
final class CategoryPreset {
  /// Creates a preset.
  const CategoryPreset({
    required this.key,
    required this.kind,
    required this.colorIndex,
    required this.icon,
    this.basic = false,
  });

  /// The key of the name.
  final String key;

  /// Whether it is for spending or for earning.
  final CategoryKind kind;

  /// The place of its color in the palette of the design tokens.
  final int colorIndex;

  /// The name of the icon.
  final String icon;

  /// Whether it belongs to the short set, which is enough to start with.
  final bool basic;
}

/// The ready set of categories.
const List<CategoryPreset> categoryPresets = [
  CategoryPreset(
    key: 'groceries',
    kind: CategoryKind.expense,
    colorIndex: 0,
    icon: 'cart',
    basic: true,
  ),
  CategoryPreset(
    key: 'cafe',
    kind: CategoryKind.expense,
    colorIndex: 1,
    icon: 'cup',
    basic: true,
  ),
  CategoryPreset(
    key: 'transport',
    kind: CategoryKind.expense,
    colorIndex: 2,
    icon: 'bus',
    basic: true,
  ),
  CategoryPreset(
    key: 'home',
    kind: CategoryKind.expense,
    colorIndex: 3,
    icon: 'home',
    basic: true,
  ),
  CategoryPreset(
    key: 'health',
    kind: CategoryKind.expense,
    colorIndex: 4,
    icon: 'heart',
    basic: true,
  ),
  CategoryPreset(
    key: 'leisure',
    kind: CategoryKind.expense,
    colorIndex: 5,
    icon: 'ticket',
    basic: true,
  ),
  CategoryPreset(
    key: 'subscriptions',
    kind: CategoryKind.expense,
    colorIndex: 6,
    icon: 'repeat',
  ),
  CategoryPreset(
    key: 'clothes',
    kind: CategoryKind.expense,
    colorIndex: 3,
    icon: 'shirt',
  ),
  CategoryPreset(
    key: 'travel',
    kind: CategoryKind.expense,
    colorIndex: 2,
    icon: 'plane',
  ),
  CategoryPreset(
    key: 'education',
    kind: CategoryKind.expense,
    colorIndex: 6,
    icon: 'book',
  ),
  CategoryPreset(
    key: 'gifts',
    kind: CategoryKind.expense,
    colorIndex: 4,
    icon: 'gift',
  ),
  CategoryPreset(
    key: 'salary',
    kind: CategoryKind.income,
    colorIndex: 0,
    icon: 'briefcase',
    basic: true,
  ),
  CategoryPreset(
    key: 'freelance',
    kind: CategoryKind.income,
    colorIndex: 2,
    icon: 'wallet',
  ),
  CategoryPreset(
    key: 'interest',
    kind: CategoryKind.income,
    colorIndex: 3,
    icon: 'percent',
  ),
  CategoryPreset(
    key: 'giftsReceived',
    kind: CategoryKind.income,
    colorIndex: 4,
    icon: 'gift',
  ),
];
