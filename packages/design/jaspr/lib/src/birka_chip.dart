import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A pill to pick one option out of a few.
class BirkaChip extends StatelessComponent {
  /// Creates a chip.
  const BirkaChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// What the chip says.
  final String label;

  /// Whether this option is picked.
  final bool selected;

  /// Called on a click. Without it the chip cannot change.
  final VoidCallback? onTap;

  @override
  Component build(BuildContext context) {
    final state = selected ? ' birka-chip--selected' : '';
    return button(
      classes: 'text-body-strong birka-chip$state',
      type: ButtonType.button,
      disabled: onTap == null,
      onClick: onTap,
      attributes: {'aria-pressed': '$selected'},
      [.text(label)],
    );
  }

  /// The styles of the chip.
  @css
  static List<StyleRule> get styles => [
    css('.birka-chip').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'border': '0',
        'border-radius': 'var(--radius-pill)',
        'color': 'var(--color-text-secondary)',
        'cursor': 'pointer',
        'height': 'var(--size-touch-target)',
        'padding': '0 var(--space-md)',
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
  ];
}
