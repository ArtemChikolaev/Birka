import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A square to pick a category or an account: a picture over a label.
class QuickAddTile extends StatelessComponent {
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
  final Component picture;

  /// Whether it is picked.
  final bool selected;

  /// Called on a click.
  final VoidCallback onTap;

  @override
  Component build(BuildContext context) {
    return button(
      classes: selected
          ? 'text-caption quick-add-tile quick-add-tile--selected'
          : 'text-caption quick-add-tile',
      type: ButtonType.button,
      onClick: onTap,
      attributes: {'aria-pressed': '$selected'},
      [
        picture,
        span(classes: 'quick-add-tile__label', [.text(label)]),
      ],
    );
  }

  /// The styles of the tile.
  @css
  static List<StyleRule> get styles => [
    css('.quick-add-tile').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-surface)',
        'border': '1px solid var(--color-hairline)',
        'border-radius': 'var(--radius-md)',
        'box-sizing': 'border-box',
        'color': 'var(--color-text)',
        'cursor': 'pointer',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'height': '68px',
        'justify-content': 'center',
        'min-width': '0',
        'padding': '0 var(--space-xxs)',
        'transition':
            'border-color var(--duration-fast), '
            'box-shadow var(--duration-fast)',
      },
    ),
    css('.quick-add-tile--selected').styles(
      raw: {
        'border-color': 'var(--color-accent)',
        'box-shadow': 'inset 0 0 0 1px var(--color-accent)',
      },
    ),
    css('.quick-add-tile__label').styles(
      raw: {
        'max-width': '100%',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
  ];
}

/// Tiles in rows of four.
class QuickAddTiles extends StatelessComponent {
  /// Creates rows of [tiles].
  const QuickAddTiles({required this.tiles, super.key});

  /// The tiles.
  final List<Component> tiles;

  @override
  Component build(BuildContext context) {
    return div(classes: 'quick-add-tiles', tiles);
  }

  /// The styles of the rows.
  @css
  static List<StyleRule> get styles => [
    css('.quick-add-tiles').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-xs)',
        'grid-template-columns': 'repeat(4, minmax(0, 1fr))',
      },
    ),
  ];
}
