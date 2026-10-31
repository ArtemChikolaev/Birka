import 'package:design_tokens/design_tokens.dart';
import 'package:ledger/ledger.dart';

/// The colors a category can take, as `#rrggbb`.
final List<String> categoryColors = [
  for (final color in const [
    BirkaTokens.colorPaletteGreen,
    BirkaTokens.colorPaletteAmber,
    BirkaTokens.colorPaletteSky,
    BirkaTokens.colorPaletteViolet,
    BirkaTokens.colorPaletteRose,
    BirkaTokens.colorPaletteOrange,
    BirkaTokens.colorPaletteCyan,
  ])
    '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
];

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
