import 'package:categories_common/categories_common.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';

/// The color of `#rrggbb` [hex].
Color colorOf(String hex) =>
    Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

/// The glyph called [name], or a neutral one for a name from a newer version.
BirkaGlyph glyphOf(String name) =>
    BirkaGlyph.values.asNameMap()[name] ?? BirkaGlyph.more;

/// The badge of [category].
GlyphBadge categoryBadge(Category category, {double size = 36}) => GlyphBadge(
  glyph: glyphOf(category.iconName),
  color: colorOf(category.colorHex),
  size: size,
);
