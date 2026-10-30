import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';

/// What the form hands over to create or change a category.
@immutable
final class CategoryDraft {
  /// Creates a draft.
  const CategoryDraft({
    required this.kind,
    required this.name,
    this.parentId,
    this.icon,
    this.color,
  });

  /// Whether it is for spending or for earning.
  final CategoryKind kind;

  /// The name the user sees.
  final String name;

  /// The parent, for a subcategory.
  final String? parentId;

  /// The name of the icon.
  final String? icon;

  /// The color as `#rrggbb`.
  final String? color;
}
