import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A pill to pick one option out of a few.
class BirkaChip extends StatelessComponent {
  /// Creates a chip. With [href] it is a link.
  const BirkaChip({
    required this.label,
    required this.selected,
    this.onTap,
    this.href,
    this.glyph,
    this.compact = false,
    this.count,
    super.key,
  });

  /// What the chip says.
  final String label;

  /// Whether this option is picked.
  final bool selected;

  /// Called on a click. Without it the chip cannot change.
  final VoidCallback? onTap;

  /// Where the chip leads.
  final String? href;

  /// What stands before the label.
  final BirkaGlyph? glyph;

  /// Whether the chip leaves less room around its label, for a row of many.
  final bool compact;

  /// How many things the option holds, after its label.
  final int? count;

  @override
  Component build(BuildContext context) {
    final classes = [
      'text-body-strong birka-chip',
      if (selected) 'birka-chip--selected',
      if (compact) 'birka-chip--compact',
    ].join(' ');
    final glyph = this.glyph;
    final count = this.count;
    final content = [
      if (glyph != null) BirkaIcon(glyph),
      span(classes: 'birka-chip__label', [.text(label)]),
      if (count != null)
        span(classes: 'text-caption birka-chip__count', [.text('$count')]),
    ];
    if (href case final href?) {
      return a(classes: classes, href: href, content);
    }
    return button(
      classes: classes,
      type: ButtonType.button,
      disabled: onTap == null,
      onClick: onTap,
      attributes: {'aria-pressed': '$selected'},
      content,
    );
  }

  /// The styles of the chip.
  @css
  static List<StyleRule> get styles => [
    css('.birka-chip').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-surface-raised)',
        'border': '0',
        'border-radius': 'var(--radius-pill)',
        'box-sizing': 'border-box',
        'color': 'var(--color-text-secondary)',
        'cursor': 'pointer',
        'display': 'inline-flex',
        'gap': 'var(--space-xs)',
        'height': 'var(--size-touch-target)',
        'max-width': '100%',
        'padding': '0 var(--space-md)',
        'text-decoration': 'none',
        'transition':
            'background var(--duration-fast), color var(--duration-fast)',
      },
    ),
    css('.birka-chip:disabled').styles(raw: {'cursor': 'default'}),
    css('.birka-chip--selected').styles(
      raw: {
        'background': 'var(--color-text)',
        'color': 'var(--color-background)',
      },
    ),
    css('.birka-chip--compact').styles(raw: {'padding': '0 var(--space-sm)'}),
    css('.birka-chip__count').styles(
      raw: {
        'background': 'var(--color-surface)',
        'border-radius': 'var(--radius-pill)',
        'font-weight': 'var(--font-weight-bold)',
        'min-width': '22px',
        'padding': '1px var(--space-xs)',
        'text-align': 'center',
      },
    ),
    css('.birka-chip--selected .birka-chip__count').styles(
      raw: {
        'background':
            'color-mix(in srgb, var(--color-background) 12%, transparent)',
      },
    ),
    css('.birka-chip .birka-icon').styles(
      raw: {'height': '20px', 'width': '20px'},
    ),
    css('.birka-chip__label').styles(
      raw: {
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
  ];
}
