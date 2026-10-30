import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// An icon in [color] on a faint tile of the same color.
class GlyphBadge extends StatelessWidget {
  /// Creates a badge.
  const GlyphBadge({
    required this.glyph,
    required this.color,
    this.size = 36,
    super.key,
  });

  /// What the badge shows.
  final BirkaGlyph glyph;

  /// The color of the icon and of its tile.
  final Color color;

  /// The width and the height.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusSm),
        ),
      ),
      child: BirkaIcon(glyph, size: size * 0.6, color: color),
    );
  }
}
