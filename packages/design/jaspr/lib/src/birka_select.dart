import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A field that opens the list of the system to pick one of [options], with
/// a dot of color before the value when [dot] gives one.
///
/// The field is as wide as the picked value, not as the longest option: the
/// value stands in it as text, and the list of the system lies over it,
/// unseen, and takes the click.
class BirkaSelect<T> extends StatelessComponent {
  /// Creates a field on [selected].
  const BirkaSelect({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.dot,
    this.quiet = false,
    this.pill = false,
    super.key,
  });

  /// What the field picks, for screen readers.
  final String label;

  /// The options and their labels, in their order.
  final Map<T, String> options;

  /// The picked option.
  final T selected;

  /// Called with the option that was picked.
  final ValueChanged<T> onChanged;

  /// The color of the dot before the value, as a CSS value.
  final String? dot;

  /// Whether the value is the quiet one, such as «Не брать».
  final bool quiet;

  /// Whether the field is a pill as wide as its value rather than as wide as
  /// its place.
  final bool pill;

  @override
  Component build(BuildContext context) {
    final values = options.keys.toList();
    final dot = this.dot;
    return div(
      classes: [
        'birka-select',
        if (pill) 'birka-select--pill',
        if (quiet) 'birka-select--quiet',
      ].join(' '),
      [
        if (dot != null)
          span(
            classes: 'birka-select__dot',
            styles: Styles(raw: {'background': dot}),
            const [],
          ),
        span(classes: 'text-body-strong birka-select__value', [
          .text(options[selected] ?? ''),
        ]),
        const span(classes: 'birka-select__chevron', [
          BirkaIcon(BirkaGlyph.chevron),
        ]),
        select(
          classes: 'birka-select__field',
          attributes: {'aria-label': label},
          value: '${values.indexOf(selected)}',
          onChange: (picked) {
            final index = int.tryParse(picked.firstOrNull ?? '');
            if (index != null && index >= 0 && index < values.length) {
              onChanged(values[index]);
            }
          },
          [
            for (final (index, value) in values.indexed)
              option(
                value: '$index',
                selected: value == selected,
                [.text(options[value]!)],
              ),
          ],
        ),
      ],
    );
  }

  /// The styles of the field.
  @css
  static List<StyleRule> get styles => [
    css('.birka-select').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-surface)',
        'border': '1px solid var(--color-hairline)',
        'border-radius': 'var(--radius-md)',
        'box-sizing': 'border-box',
        'display': 'flex',
        'gap': 'var(--space-xs)',
        'min-height': 'var(--size-touch-target)',
        'min-width': '0',
        'padding': '0 var(--space-sm)',
        'position': 'relative',
        'transition': 'border-color var(--duration-fast)',
      },
    ),
    css('.birka-select--pill').styles(
      raw: {
        'border-radius': 'var(--radius-pill)',
        'display': 'inline-flex',
        'max-width': '100%',
      },
    ),
    css('.birka-select:hover').styles(
      raw: {'border-color': 'var(--color-glass-border)'},
    ),
    css('.birka-select:has(select:focus-visible)').styles(
      raw: {
        'outline': '2px solid var(--color-accent)',
        'outline-offset': '2px',
      },
    ),
    css('.birka-select__dot').styles(
      raw: {
        'border-radius': '50%',
        'flex': 'none',
        'height': '8px',
        'width': '8px',
      },
    ),
    css('.birka-select__value').styles(
      raw: {
        'color': 'var(--color-text)',
        'flex': '1',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.birka-select--quiet .birka-select__value').styles(
      raw: {'color': 'var(--color-text-subtle)'},
    ),
    css('.birka-select__chevron').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'flex': 'none',
        'transform': 'rotate(90deg)',
      },
    ),
    css('.birka-select__chevron .birka-icon').styles(
      raw: {'height': '16px', 'width': '16px'},
    ),
    // The list of the system lies over the whole field, unseen.
    css('.birka-select__field').styles(
      raw: {
        'appearance': 'none',
        'border': '0',
        'cursor': 'pointer',
        'font': 'inherit',
        'height': '100%',
        'inset': '0',
        'margin': '0',
        'opacity': '0',
        'position': 'absolute',
        'width': '100%',
      },
    ),
    css('.birka-select__field option').styles(
      raw: {
        'background': 'var(--color-background)',
        'color': 'var(--color-text)',
      },
    ),
  ];
}
