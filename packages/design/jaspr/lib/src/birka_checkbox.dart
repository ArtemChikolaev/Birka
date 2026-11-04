import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A box to tick, such as to pick a row of a list for one action on several.
class BirkaCheckbox extends StatelessComponent {
  /// Creates a box that [checked] says is ticked.
  const BirkaCheckbox({
    required this.checked,
    required this.label,
    required this.onChanged,
    super.key,
  });

  /// Whether the box is ticked.
  final bool checked;

  /// What the box picks, for screen readers.
  final String label;

  /// Called with the new state on a click.
  final ValueChanged<bool> onChanged;

  @override
  Component build(BuildContext context) {
    return button(
      classes: checked
          ? 'birka-checkbox birka-checkbox--checked'
          : 'birka-checkbox',
      type: ButtonType.button,
      attributes: {
        'role': 'checkbox',
        'aria-checked': '$checked',
        'aria-label': label,
      },
      onClick: () => onChanged(!checked),
      [
        span(classes: 'birka-checkbox__box', [
          if (checked) const BirkaIcon(BirkaGlyph.check),
        ]),
      ],
    );
  }

  /// The styles of the box.
  @css
  static List<StyleRule> get styles => [
    // The box is small; the button around it is big enough for a finger.
    css('.birka-checkbox').styles(
      raw: {
        'align-items': 'center',
        'background': 'none',
        'border': '0',
        'cursor': 'pointer',
        'display': 'inline-flex',
        'flex': 'none',
        'height': 'var(--size-touch-target)',
        'justify-content': 'center',
        'margin': 'calc(-1 * var(--space-xs))',
        'padding': '0',
        'width': 'var(--size-touch-target)',
      },
    ),
    css('.birka-checkbox__box').styles(
      raw: {
        'align-items': 'center',
        'border': '2px solid var(--color-text-subtle)',
        'border-radius': 'var(--radius-xs)',
        'box-sizing': 'border-box',
        'color': 'var(--color-on-accent)',
        'display': 'flex',
        'height': '24px',
        'justify-content': 'center',
        'transition':
            'background var(--duration-fast) var(--easing-fade), '
            'border-color var(--duration-fast) var(--easing-fade)',
        'width': '24px',
      },
    ),
    css('.birka-checkbox--checked .birka-checkbox__box').styles(
      raw: {
        'background': 'var(--color-accent)',
        'border-color': 'var(--color-accent)',
      },
    ),
    css('.birka-checkbox__box .birka-icon').styles(
      raw: {'height': '16px', 'width': '16px'},
    ),
    css('.birka-checkbox:focus-visible .birka-checkbox__box').styles(
      raw: {
        'outline': '2px solid var(--color-accent)',
        'outline-offset': '2px',
      },
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.birka-checkbox__box').styles(raw: {'transition': 'none'}),
    ]),
  ];
}
