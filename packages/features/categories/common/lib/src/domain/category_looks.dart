import 'package:design_tokens/design_tokens.dart';
import 'package:ledger/ledger.dart';

/// The colors a category can take, as `#rrggbb`.
final List<String> categoryColors = paletteColors;

/// The names of the icons a category can take.
const List<String> categoryIcons = [
  'cart',
  'cup',
  'bus',
  'home',
  'heart',
  'ticket',
  'repeat',
  'shirt',
  'plane',
  'book',
  'gift',
  'briefcase',
  'wallet',
  'percent',
];

/// The look of a category, with a default for what it does not have.
extension CategoryLook on Category {
  /// The name of the icon.
  String get iconName => icon ?? categoryIcons.first;

  /// The color as `#rrggbb`.
  String get colorHex => color ?? categoryColors.first;
}

/// The look of a category of the ready set.
extension CategoryPresetLook on CategoryPreset {
  /// The color as `#rrggbb`.
  String get color => categoryColors[colorIndex];
}
