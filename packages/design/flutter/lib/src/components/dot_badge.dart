import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A glowing dot of [color] on a faint tile of the same color: the mark of a
/// place to go, such as a tile of Ещё or a way to write to the developer.
class DotBadge extends StatelessWidget {
  /// Creates a badge.
  const DotBadge({required this.color, super.key});

  /// The color of the dot and of its tile.
  final Color color;

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusSm),
        ),
      ),
      child: Container(
        width: BirkaTokens.spaceSm,
        height: BirkaTokens.spaceSm,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: BirkaTokens.spaceSm),
          ],
        ),
      ),
    );
  }
}
