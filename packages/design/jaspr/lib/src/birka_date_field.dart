import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
// The field `label` of the component hides the element of the same name.
import 'package:jaspr/dom.dart' as dom show label;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// A field of glass that shows a date in words and opens the calendar of the
/// browser, with a label over it, as `BirkaTextField` stands.
class BirkaDateField extends StatelessComponent {
  /// Creates a field on [value]. The dates are `YYYY-MM-DD`, as HTML has
  /// them.
  const BirkaDateField({
    required this.label,
    required this.text,
    required this.value,
    required this.first,
    required this.last,
    required this.onChanged,
    super.key,
  });

  /// What the field is for, over it.
  final String label;

  /// The date in words, such as `20 ноября`.
  final String text;

  /// The date the calendar opens on.
  final String value;

  /// The earliest date of the calendar.
  final String first;

  /// The latest date of the calendar.
  final String last;

  /// Called with a new date. A date that is typed by hand can lie outside
  /// [first] and [last], or be empty.
  final ValueChanged<String> onChanged;

  @override
  Component build(BuildContext context) {
    return dom.label(classes: 'birka-field', [
      span(classes: 'text-caption birka-field__label', [.text(label)]),
      div(classes: 'glass birka-field__box birka-date-field', [
        span(classes: 'text-body birka-date-field__text', [.text(text)]),
        const BirkaIcon(BirkaGlyph.calendar),
        input(
          classes: 'birka-date-field__input',
          type: InputType.date,
          value: value,
          attributes: {'max': last, 'min': first},
          events: {
            'change': (event) =>
                onChanged((event.target! as web.HTMLInputElement).value),
          },
        ),
      ]),
    ]);
  }

  /// The styles of the field, over those of `BirkaTextField`.
  @css
  static List<StyleRule> get styles => [
    css('.glass.birka-date-field').styles(
      raw: {'cursor': 'pointer', 'position': 'relative'},
    ),
    css('.birka-date-field__text').styles(
      raw: {
        'color': 'var(--color-text)',
        'flex': '1 1 0',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.birka-date-field .birka-icon').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'flex': 'none',
        'height': '20px',
        'width': '20px',
      },
    ),
    // The field stays over the box, unseen, and takes the click.
    css('.birka-date-field__input').styles(
      raw: {
        'border': '0',
        'cursor': 'pointer',
        'height': '100%',
        'inset': '0',
        'margin': '0',
        'opacity': '0',
        'padding': '0',
        'position': 'absolute',
        'width': '100%',
      },
    ),
    // Chrome opens the calendar only from its icon, so that fills the field.
    css('.birka-date-field__input::-webkit-calendar-picker-indicator').styles(
      raw: {
        'cursor': 'pointer',
        'height': '100%',
        'inset': '0',
        'margin': '0',
        'padding': '0',
        'position': 'absolute',
        'width': '100%',
      },
    ),
    css('.glass.birka-date-field:has(input:focus-visible)').styles(
      raw: {'border-color': 'var(--color-accent)'},
    ),
  ];
}
