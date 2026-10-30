import 'package:categories_common/src/domain/category_looks.dart';
import 'package:ledger/ledger.dart';
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
  });

  /// The key of the name.
  final String key;

  /// Whether it is for spending or for earning.
  final CategoryKind kind;

  /// The place of its color in [categoryColors].
  final int colorIndex;

  /// The name of the icon.
  final String icon;

  /// The color as `#rrggbb`.
  String get color => categoryColors[colorIndex];
}

/// The ready set of categories.
const List<CategoryPreset> categoryPresets = [
  CategoryPreset(
    key: 'groceries',
    kind: CategoryKind.expense,
    colorIndex: 0,
    icon: 'cart',
  ),
  CategoryPreset(
    key: 'cafe',
    kind: CategoryKind.expense,
    colorIndex: 1,
    icon: 'cup',
  ),
  CategoryPreset(
    key: 'transport',
    kind: CategoryKind.expense,
    colorIndex: 2,
    icon: 'bus',
  ),
  CategoryPreset(
    key: 'home',
    kind: CategoryKind.expense,
    colorIndex: 3,
    icon: 'home',
  ),
  CategoryPreset(
    key: 'health',
    kind: CategoryKind.expense,
    colorIndex: 4,
    icon: 'heart',
  ),
  CategoryPreset(
    key: 'leisure',
    kind: CategoryKind.expense,
    colorIndex: 5,
    icon: 'ticket',
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
