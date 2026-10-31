import 'package:categories_common/categories_common.dart';
import 'package:design_jaspr/design_jaspr.dart';

/// The badge of [category].
GlyphBadge categoryBadge(Category category, {int size = 36}) => GlyphBadge(
  glyph: BirkaGlyph.named(category.iconName),
  color: category.colorHex,
  size: size,
);
