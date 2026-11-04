import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// One of a few options as a card of glass: a mark at its start, a title with
/// a tag and a badge, a line under it, a value at its end and the round mark
/// of the choice. A group of them stands in an element of the role
/// `radiogroup`.
class GlassOption extends StatelessComponent {
  /// Creates an option.
  const GlassOption({
    required this.title,
    required this.selected,
    required this.onTap,
    this.leading,
    this.tag,
    this.badge,
    this.subtitle,
    this.trailing,
    this.dimmed = false,
    super.key,
  });

  /// What the option is.
  final String title;

  /// Whether it is the chosen one.
  final bool selected;

  /// Chooses it.
  final VoidCallback onTap;

  /// The mark at its start, such as the badge of a bank.
  final Component? leading;

  /// A quiet word after the title, such as `CSV`.
  final String? tag;

  /// A word of the accent after the title, such as «совпал номер карты».
  final String? badge;

  /// The line under the title.
  final String? subtitle;

  /// The value at its end, such as a balance.
  final Component? trailing;

  /// Whether it fits worse than the others, such as an account of another
  /// currency.
  final bool dimmed;

  @override
  Component build(BuildContext context) {
    final tag = this.tag;
    final badge = this.badge;
    final subtitle = this.subtitle;
    return button(
      classes: [
        'glass-option',
        if (selected) 'glass-option--selected',
        if (dimmed) 'glass-option--dimmed',
      ].join(' '),
      type: ButtonType.button,
      attributes: {'role': 'radio', 'aria-checked': '$selected'},
      onClick: onTap,
      [
        ?leading,
        span(classes: 'glass-option__text', [
          span(classes: 'glass-option__title', [
            span(classes: 'text-body-strong glass-option__name', [
              .text(title),
            ]),
            if (tag != null)
              span(classes: 'text-label glass-option__tag', [.text(tag)]),
            if (badge != null)
              span(classes: 'text-caption glass-option__badge', [.text(badge)]),
          ]),
          if (subtitle != null)
            span(classes: 'text-caption glass-option__subtitle', [
              .text(subtitle),
            ]),
        ]),
        if (trailing case final trailing?)
          span(classes: 'glass-option__end', [trailing]),
        const span(classes: 'glass-option__mark', []),
      ],
    );
  }

  /// The styles of the option.
  @css
  static List<StyleRule> get styles => [
    css('.glass-option').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-surface)',
        'border': '1px solid var(--color-hairline)',
        'border-radius': 'var(--radius-lg)',
        'box-sizing': 'border-box',
        'color': 'inherit',
        'cursor': 'pointer',
        'display': 'flex',
        'font': 'inherit',
        'gap': 'var(--space-sm)',
        'min-height': '72px',
        'padding': 'var(--space-sm) var(--space-md)',
        'text-align': 'start',
        'transition':
            'background var(--duration-base) var(--easing-fade), '
            'border-color var(--duration-base) var(--easing-fade)',
        'width': '100%',
      },
    ),
    css('.glass-option--selected').styles(
      raw: {
        'background': 'var(--color-accent-soft)',
        'border-color': 'var(--color-accent)',
      },
    ),
    css('.glass-option:focus-visible').styles(
      raw: {
        'outline': '2px solid var(--color-accent)',
        'outline-offset': '2px',
      },
    ),
    css('.glass-option__text').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': '2px',
        'min-width': '0',
      },
    ),
    css('.glass-option__title').styles(
      raw: {
        'align-items': 'baseline',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xxs) var(--space-xs)',
      },
    ),
    css('.glass-option__name').styles(raw: {'color': 'var(--color-text)'}),
    css('.glass-option--dimmed .glass-option__name').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.glass-option__tag').styles(
      raw: {'color': 'var(--color-text-subtle)', 'font-size': '11px'},
    ),
    css('.glass-option__badge').styles(
      raw: {
        'background': 'var(--color-accent-soft)',
        'border-radius': 'var(--radius-pill)',
        'color': 'var(--color-accent)',
        'font-weight': 'var(--font-weight-semibold)',
        'padding': '1px var(--space-xs)',
      },
    ),
    css('.glass-option__subtitle').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.glass-option__end').styles(
      raw: {'color': 'var(--color-text)', 'flex': 'none'},
    ),
    css('.glass-option--dimmed .glass-option__end').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.glass-option__mark').styles(
      raw: {
        'border': '2px solid var(--color-text-subtle)',
        'border-radius': '50%',
        'box-sizing': 'border-box',
        'flex': 'none',
        'height': '22px',
        'transition': 'border var(--duration-fast) var(--easing-fade)',
        'width': '22px',
      },
    ),
    css('.glass-option--selected .glass-option__mark').styles(
      raw: {'border': '6px solid var(--color-accent)'},
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.glass-option, .glass-option__mark').styles(
        raw: {'transition': 'none'},
      ),
    ]),
  ];
}
