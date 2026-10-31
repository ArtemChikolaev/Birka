import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A row of a few options of equal width with one picked, such as expenses
/// and income.
class GlassSegmented<T> extends StatelessComponent {
  /// Creates a control. [segments] maps every option to its label.
  const GlassSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// The options and their labels, as written, not in capitals.
  final Map<T, String> segments;

  /// The picked option.
  final T selected;

  /// Called with the option that was clicked.
  final ValueChanged<T> onChanged;

  @override
  Component build(BuildContext context) {
    return div(classes: 'glass-segmented', [
      for (final MapEntry(key: value, value: label) in segments.entries)
        button(
          classes: value == selected
              ? 'text-label glass-segmented__option '
                    'glass-segmented__option--selected'
              : 'text-label glass-segmented__option',
          type: ButtonType.button,
          onClick: () => onChanged(value),
          attributes: {'aria-pressed': '${value == selected}'},
          [.text(label)],
        ),
    ]);
  }

  /// The styles of the control.
  @css
  static List<StyleRule> get styles => [
    css('.glass-segmented').styles(
      raw: {
        'background': 'var(--color-surface)',
        'border': '1px solid var(--color-hairline)',
        'border-radius': 'var(--radius-lg)',
        'box-sizing': 'border-box',
        'display': 'flex',
        'height': '52px',
        'padding': 'var(--space-xxs)',
        'width': '100%',
      },
    ),
    css('.glass-segmented__option').styles(
      raw: {
        'background': 'none',
        'border': '0',
        'border-radius': 'var(--radius-md)',
        'color': 'var(--color-text-subtle)',
        'cursor': 'pointer',
        'flex': '1',
        'min-width': '0',
        'transition':
            'background var(--duration-fast), color var(--duration-fast)',
      },
    ),
    css('.glass-segmented__option--selected').styles(
      raw: {
        'background': 'var(--color-surface-selected)',
        'color': 'var(--color-text)',
      },
    ),
  ];
}
