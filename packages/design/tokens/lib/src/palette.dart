import 'package:design_tokens/src/tokens.g.dart';

/// The colors of the palette as `#rrggbb`, for what keeps a color as text.
final List<String> paletteColors = [
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
