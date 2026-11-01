import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';

/// A category of a ready set, already in the language of the user.
@immutable
final class ReadyCategory {
  /// Creates a category.
  const ReadyCategory({
    required this.kind,
    required this.name,
    required this.icon,
    required this.color,
  });

  /// Whether it is for spending or for earning.
  final CategoryKind kind;

  /// The name of the category.
  final String name;

  /// The name of the icon.
  final String icon;

  /// The color as `#rrggbb`.
  final String color;
}
