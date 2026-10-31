import 'package:categories_common/categories_common.dart';
import 'package:design_flutter/design_flutter.dart';

/// The badge of [category].
GlyphBadge categoryBadge(Category category, {double size = 36}) => GlyphBadge(
  glyph: BirkaGlyph.named(category.iconName),
  color: BirkaColors.fromHex(category.colorHex),
  size: size,
);
