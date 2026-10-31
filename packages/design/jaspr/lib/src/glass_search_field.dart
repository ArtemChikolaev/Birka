import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A field of glass that searches as it is typed in, with a cross that clears
/// it.
class GlassSearchField extends StatelessComponent {
  /// Creates a field that shows [value]. Screen readers read [label].
  const GlassSearchField({
    required this.label,
    required this.clearLabel,
    required this.value,
    required this.onChanged,
    this.hint,
    super.key,
  });

  /// What the field is for, for screen readers.
  final String label;

  /// What the cross does, for screen readers.
  final String clearLabel;

  /// The text of the field.
  final String value;

  /// Called on every change, and when the cross clears the text.
  final ValueChanged<String> onChanged;

  /// What an empty field shows.
  final String? hint;

  @override
  Component build(BuildContext context) {
    return div(classes: 'glass glass-search', [
      const BirkaIcon(BirkaGlyph.search),
      input<String>(
        classes: 'text-body glass-search__input',
        type: InputType.text,
        value: value,
        onInput: onChanged,
        attributes: {
          'aria-label': label,
          'autocapitalize': 'sentences',
          'autocomplete': 'off',
          'enterkeyhint': 'search',
          'placeholder': ?hint,
        },
      ),
      if (value.isNotEmpty)
        button(
          classes: 'glass-search__clear',
          type: ButtonType.button,
          onClick: () => onChanged(''),
          // Leaves the focus in the field, so that the keyboard stays for a
          // new word.
          events: {'mousedown': (event) => event.preventDefault()},
          attributes: {'aria-label': clearLabel},
          const [BirkaIcon(BirkaGlyph.close)],
        ),
    ]);
  }

  /// The styles of the field.
  @css
  static List<StyleRule> get styles => [
    css('.glass.glass-search').styles(
      raw: {
        'align-items': 'center',
        'border-radius': 'var(--radius-pill)',
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'height': 'var(--size-touch-target)',
        'padding': '0 var(--space-xs) 0 var(--space-md)',
        'transition': 'border-color var(--duration-fast)',
      },
    ),
    css('.glass.glass-search:focus-within').styles(
      raw: {'border-color': 'var(--color-accent)'},
    ),
    css('.glass-search .birka-icon').styles(
      raw: {'height': '20px', 'width': '20px'},
    ),
    css('.glass-search__input').styles(
      raw: {
        'background': 'none',
        'border': '0',
        'caret-color': 'var(--color-accent)',
        'color': 'var(--color-text)',
        'flex': '1',
        // Below 16px Safari on iPhone zooms the page into the field.
        'font-size': 'max(1em, 16px)',
        'min-width': '0',
        'outline': 'none',
        'padding': '0',
      },
    ),
    css('.glass-search__input::placeholder').styles(
      raw: {'color': 'var(--color-text-subtle)'},
    ),
    css('.glass-search__clear').styles(
      raw: {
        'background': 'none',
        'border': '0',
        'color': 'inherit',
        'cursor': 'pointer',
        'flex': 'none',
        'padding': 'var(--space-xs)',
      },
    ),
    css('.glass-search__clear .birka-icon').styles(
      raw: {'height': '18px', 'width': '18px'},
    ),
  ];
}
