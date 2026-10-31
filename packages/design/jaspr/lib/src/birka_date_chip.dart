import 'package:design_jaspr/src/birka_chip.dart';
import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
// The field `label` of the component hides the element of the same name.
import 'package:jaspr/dom.dart' as dom show label;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// A chip that opens the calendar of the browser. It is only an icon until
/// there is a [label] to show, and then it stands as picked.
class BirkaDateChip extends StatelessComponent {
  /// Creates a chip on [value]. The dates are `YYYY-MM-DD`, as HTML has them.
  const BirkaDateChip({
    required this.fieldLabel,
    required this.value,
    required this.first,
    required this.last,
    required this.onChanged,
    this.label,
    super.key,
  });

  /// What the chip does, for screen readers.
  final String fieldLabel;

  /// The date the calendar opens on.
  final String value;

  /// The earliest date of the calendar.
  final String first;

  /// The latest date of the calendar.
  final String last;

  /// Called with a new date. A date that is typed by hand can lie outside
  /// [first] and [last], or be empty.
  final ValueChanged<String> onChanged;

  /// What the chip says.
  final String? label;

  @override
  Component build(BuildContext context) {
    final label = this.label;
    return dom.label(
      classes: [
        'text-body-strong birka-chip birka-date-chip',
        if (label == null) 'birka-date-chip--icon' else 'birka-chip--selected',
      ].join(' '),
      [
        const BirkaIcon(BirkaGlyph.calendar),
        if (label != null) span(classes: 'birka-chip__label', [.text(label)]),
        input(
          classes: 'birka-date-chip__input',
          type: InputType.date,
          value: value,
          attributes: {'aria-label': fieldLabel, 'max': last, 'min': first},
          events: {
            'change': (event) =>
                onChanged((event.target! as web.HTMLInputElement).value),
          },
        ),
      ],
    );
  }

  /// The styles of the chip, over those of [BirkaChip].
  @css
  static List<StyleRule> get styles => [
    css('.birka-date-chip').styles(raw: {'position': 'relative'}),
    css('.birka-date-chip--icon').styles(
      raw: {
        'justify-content': 'center',
        'padding': '0',
        'width': 'var(--size-touch-target)',
      },
    ),
    // The field stays over the chip, unseen, and takes the click.
    css('.birka-date-chip__input').styles(
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
    css('.birka-date-chip__input::-webkit-calendar-picker-indicator').styles(
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
    css('.birka-date-chip:has(input:focus-visible)').styles(
      raw: {
        'outline': '2px solid var(--color-accent)',
        'outline-offset': '2px',
      },
    ),
  ];
}
