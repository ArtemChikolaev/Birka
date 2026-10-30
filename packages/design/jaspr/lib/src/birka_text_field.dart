import 'package:jaspr/dom.dart';
// The field `label` of the component hides the element of the same name.
import 'package:jaspr/dom.dart' as dom show label;
import 'package:jaspr/jaspr.dart';

/// A field of glass with a label over it and an error under it.
class BirkaTextField extends StatelessComponent {
  /// Creates a field that shows [value].
  const BirkaTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.error,
    this.inputMode,
    this.maxLength,
    this.sentence = false,
    this.textClass = 'text-body',
    super.key,
  });

  /// What the field is for.
  final String label;

  /// The text of the field.
  final String value;

  /// Called on every change.
  final ValueChanged<String> onChanged;

  /// What an empty field shows.
  final String? hint;

  /// What is wrong with the text.
  final String? error;

  /// The keyboard of the field: `decimal`, `numeric` and so on.
  final String? inputMode;

  /// How many characters the field takes.
  final int? maxLength;

  /// Whether the keyboard starts with a capital letter.
  final bool sentence;

  /// The text style from the tokens, such as `text-amount`.
  final String textClass;

  @override
  Component build(BuildContext context) {
    final error = this.error;
    return dom.label(
      classes: 'birka-field',
      [
        span(classes: 'text-caption birka-field__label', [.text(label)]),
        div(classes: 'glass birka-field__box', [
          input<String>(
            classes: '$textClass birka-field__input',
            type: InputType.text,
            value: value,
            onInput: onChanged,
            attributes: {
              'autocomplete': 'off',
              'placeholder': ?hint,
              'inputmode': ?inputMode,
              'maxlength': ?maxLength?.toString(),
              if (sentence) 'autocapitalize': 'sentences',
              if (error != null) 'aria-invalid': 'true',
            },
          ),
        ]),
        if (error != null)
          span(classes: 'text-caption birka-field__error', [.text(error)]),
      ],
    );
  }

  /// The styles of the field.
  @css
  static List<StyleRule> get styles => [
    css('.birka-field').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.birka-field__label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.glass.birka-field__box').styles(
      raw: {
        'border-radius': 'var(--radius-md)',
        'padding': 'var(--space-sm) var(--space-md)',
        'transition': 'border-color var(--duration-fast)',
      },
    ),
    css('.glass.birka-field__box:focus-within').styles(
      raw: {'border-color': 'var(--color-accent)'},
    ),
    css('.birka-field__input').styles(
      raw: {
        'background': 'none',
        'border': '0',
        'box-sizing': 'border-box',
        'caret-color': 'var(--color-accent)',
        'color': 'var(--color-text)',
        // Below 16px Safari on iPhone zooms the page into the field.
        'font-size': 'max(1em, 16px)',
        'outline': 'none',
        'padding': '0',
        'width': '100%',
      },
    ),
    css('.birka-field__input::placeholder').styles(
      raw: {'color': 'var(--color-text-subtle)'},
    ),
    css('.birka-field__error').styles(raw: {'color': 'var(--color-negative)'}),
  ];
}
