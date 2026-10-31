import 'package:categories_common/categories_common.dart';
import 'package:design_jaspr/design_jaspr.dart';

/// The glyph called [name], or a neutral one for a name from a newer version.
BirkaGlyph glyphOf(String name) =>
    BirkaGlyph.values.asNameMap()[name] ?? BirkaGlyph.more;

/// The badge of [category].
GlyphBadge categoryBadge(Category category, {int size = 36}) => GlyphBadge(
  glyph: glyphOf(category.iconName),
  color: category.colorHex,
  size: size,
);
