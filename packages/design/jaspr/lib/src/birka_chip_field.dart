import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A field in the shape of a chip, with a dashed outline while it is empty,
/// for something that is rarely filled in.
class BirkaChipField extends StatelessComponent {
  /// Creates a field that shows [value].
  const BirkaChipField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// What the field is for, which it says while it is empty.
  final String label;

  /// The text of the field.
  final String value;

  /// Called on every change.
  final ValueChanged<String> onChanged;

  @override
  Component build(BuildContext context) {
    return input<String>(
      classes: 'text-body-strong birka-chip-field',
      type: InputType.text,
      value: value,
      onInput: onChanged,
      attributes: {
        'aria-label': label,
        'autocapitalize': 'sentences',
        'autocomplete': 'off',
        'placeholder': label,
      },
    );
  }

  /// The styles of the field.
  @css
  static List<StyleRule> get styles => [
    css('.birka-chip-field').styles(
      raw: {
        'background': 'none',
        'border': '1px dashed var(--color-text-subtle)',
        'border-radius': 'var(--radius-pill)',
        'box-sizing': 'border-box',
        'caret-color': 'var(--color-accent)',
        'color': 'var(--color-text)',
        'flex': '1 1 120px',
        // Below 16px Safari on iPhone zooms the page into the field.
        'font-size': 'max(1em, 16px)',
        'height': 'var(--size-touch-target)',
        'min-width': '0',
        'padding': '0 var(--space-md)',
        'transition':
            'background var(--duration-fast), '
            'border-color var(--duration-fast)',
      },
    ),
    css('.birka-chip-field::placeholder').styles(
      raw: {'color': 'var(--color-text-secondary)', 'opacity': '1'},
    ),
    css('.birka-chip-field:not(:placeholder-shown)').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'border-color': 'transparent',
      },
    ),
    css('.birka-chip-field:focus').styles(
      raw: {'border': '1px solid var(--color-accent)', 'outline': 'none'},
    ),
  ];
}
