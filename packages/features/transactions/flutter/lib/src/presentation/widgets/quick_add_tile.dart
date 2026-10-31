import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';

/// A square to pick a category or an account: a picture over a label.
class QuickAddTile extends StatelessWidget {
  /// Creates a tile.
  const QuickAddTile({
    required this.label,
    required this.picture,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// What the tile stands for.
  final String label;

  /// What stands over the label.
  final Widget picture;

  /// Whether it is picked.
  final bool selected;

  /// Called on a tap.
  final VoidCallback onTap;

  /// The height of a tile.
  static const double height = 68;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: BirkaTokens.durationFastMs),
          height: height,
          padding: const EdgeInsets.symmetric(
            horizontal: BirkaTokens.spaceXxs,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(BirkaTokens.radiusMd),
            ),
            border: Border.all(
              color: selected ? colors.accent : colors.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              picture,
              const SizedBox(height: BirkaTokens.spaceXxs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BirkaTextStyles.of(
                  context,
                ).caption.copyWith(color: colors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiles in rows of four, without a grid, so that the rows can size a page.
class QuickAddTiles extends StatelessWidget {
  /// Creates rows of [tiles].
  const QuickAddTiles({required this.tiles, super.key});

  /// The tiles.
  final List<Widget> tiles;

  static const _perRow = 4;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: BirkaTokens.spaceXs,
      children: [
        for (var start = 0; start < tiles.length; start += _perRow)
          Row(
            spacing: BirkaTokens.spaceXs,
            children: [
              for (var index = start; index < start + _perRow; index++)
                Expanded(
                  child: index < tiles.length
                      ? tiles[index]
                      : const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }
}
