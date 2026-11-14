import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A big glass button with its icon over its label, such as the actions
/// under an operation or on the card of a debt. With [href] it is a link,
/// with [onTap] a button, and without either it fades and does nothing.
/// Tiles stand side by side in a `div` of the class `glass-action-tiles`.
class GlassActionTile extends StatelessComponent {
  /// Creates a tile.
  const GlassActionTile({
    required this.glyph,
    required this.label,
    this.href,
    this.onTap,
    this.danger = false,
    this.accent = false,
    this.expanded,
    super.key,
  });

  /// The icon.
  final BirkaGlyph glyph;

  /// What the tile does.
  final String label;

  /// Where the tile leads.
  final String? href;

  /// Called on a click.
  final VoidCallback? onTap;

  /// Whether the action deletes or undoes something.
  final bool danger;

  /// Whether the action is the main one, in the accent.
  final bool accent;

  /// Whether what the tile opens under it is open, for a tile that opens a
  /// fold.
  final bool? expanded;

  @override
  Component build(BuildContext context) {
    final classes = [
      'glass text-body-strong glass-action-tile',
      if (danger) 'glass-action-tile--danger',
      if (accent) 'glass-action-tile--accent',
    ].join(' ');
    final content = [BirkaIcon(glyph), Component.text(label)];
    final href = this.href;
    if (href != null) return a(classes: classes, href: href, content);
    final onTap = this.onTap;
    return button(
      classes: classes,
      type: ButtonType.button,
      disabled: onTap == null,
      attributes: {
        if (expanded case final expanded?) 'aria-expanded': '$expanded',
      },
      onClick: onTap,
      content,
    );
  }

  /// The styles of the tiles.
  @css
  static List<StyleRule> get styles => [
    css('.glass-action-tiles').styles(
      raw: {'display': 'flex', 'gap': 'var(--space-sm)'},
    ),
    css('.glass.glass-action-tile').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text)',
        'cursor': 'pointer',
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        // Narrow sides leave room for three tiles in a row.
        'padding-left': 'var(--space-xs)',
        'padding-right': 'var(--space-xs)',
        'text-align': 'center',
        'text-decoration': 'none',
        'transition': 'opacity var(--duration-fast)',
      },
    ),
    css('.glass.glass-action-tile--danger').styles(
      raw: {'color': 'var(--color-negative)'},
    ),
    css('.glass.glass-action-tile--accent').styles(
      raw: {'color': 'var(--color-accent)'},
    ),
    css('.glass.glass-action-tile:disabled').styles(
      raw: {'cursor': 'default', 'opacity': '0.4'},
    ),
  ];
}
