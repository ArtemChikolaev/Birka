import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A panel of glass with rows and thin lines between them.
class GlassListGroup extends StatelessComponent {
  /// Creates a group of [children], usually [GlassListRow]s.
  const GlassListGroup({required this.children, super.key});

  /// The rows.
  final List<Component> children;

  @override
  Component build(BuildContext context) {
    return div(classes: 'glass glass-list', children);
  }

  /// The styles of the group.
  @css
  static List<StyleRule> get styles => [
    css('.glass.glass-list').styles(
      raw: {'overflow': 'hidden', 'padding': '0'},
    ),
  ];
}

/// A row of a [GlassListGroup]: an optional [leading] component, a [title]
/// with a [subtitle] under it and an optional [trailing] component. An
/// [action] stands after a row that leads somewhere, outside its link, such
/// as the cross that takes the row away.
class GlassListRow extends StatelessComponent {
  /// Creates a row. With [href] it is a link and with [onTap] a button.
  const GlassListRow({
    required this.title,
    this.subtitle,
    this.subtitleLines = 1,
    this.subtitleColor,
    this.leading,
    this.trailing,
    this.href,
    this.onTap,
    this.indented = false,
    this.danger = false,
    this.entering = false,
    this.picked = false,
    this.action,
    super.key,
  });

  /// The main line.
  final String title;

  /// The quieter line under [title].
  final String? subtitle;

  /// How many lines [subtitle] takes before it is cut.
  final int subtitleLines;

  /// The color of [subtitle] as CSS, such as what became of a notice in the
  /// color of the news; the quiet color of the kit without it.
  final String? subtitleColor;

  /// What stands before the text, such as a small picture.
  final Component? leading;

  /// What stands after the text, such as an amount or a switch.
  final Component? trailing;

  /// Where the row leads.
  final String? href;

  /// Called on a click.
  final VoidCallback? onTap;

  /// Whether the row stands under the row before it, such as a subcategory.
  final bool indented;

  /// Whether the row does what cannot be taken back, with its title in the
  /// color of a loss.
  final bool danger;

  /// Whether the row has just come into its group, which it opens into from
  /// nothing.
  final bool entering;

  /// Whether the row is the one whose card stands beside the list on a wide
  /// page, which marks it with the accent at its edge.
  final bool picked;

  /// A button of its own after a row with [href] or [onTap].
  final Component? action;

  @override
  Component build(BuildContext context) {
    final subtitle = this.subtitle;
    final indent =
        '${indented ? ' glass-row--indented' : ''}'
        '${danger ? ' glass-row--danger' : ''}'
        '${entering ? ' glass-row--entering' : ''}'
        '${picked ? ' glass-row--picked' : ''}';
    final color = subtitleColor;
    final lines = subtitleLines > 1;
    final subtitleStyles = lines || color != null
        ? Styles(
            raw: {
              if (lines) '-webkit-line-clamp': '$subtitleLines',
              'color': ?color,
            },
          )
        : null;
    final content = [
      ?leading,
      span(classes: 'glass-row__text', [
        span(classes: 'text-body-strong glass-row__line', [.text(title)]),
        if (subtitle != null)
          span(
            classes: lines
                ? 'text-caption glass-row__lines glass-row__subtitle'
                : 'text-caption glass-row__line glass-row__subtitle',
            styles: subtitleStyles,
            [.text(subtitle)],
          ),
      ]),
      ?trailing,
    ];
    final action = this.action;
    if (action != null && (href != null || onTap != null)) {
      return div(classes: 'glass-row glass-row--split$indent', [
        if (href case final href?)
          a(classes: 'glass-row__link', href: href, content)
        else
          button(
            classes: 'glass-row__link',
            type: ButtonType.button,
            onClick: onTap,
            content,
          ),
        action,
      ]);
    }
    if (href case final href?) {
      return a(
        classes: 'glass-row glass-row--action$indent',
        href: href,
        content,
      );
    }
    if (onTap case final onTap?) {
      return button(
        classes: 'glass-row glass-row--action$indent',
        type: ButtonType.button,
        onClick: onTap,
        content,
      );
    }
    return div(classes: 'glass-row$indent', content);
  }

  /// The styles of the row.
  @css
  static List<StyleRule> get styles => [
    css('.glass-row').styles(
      raw: {
        'align-items': 'center',
        'background': 'none',
        'border': '0',
        'box-sizing': 'border-box',
        'color': 'var(--color-text)',
        'display': 'flex',
        'font': 'inherit',
        'gap': 'var(--space-sm)',
        'min-height': 'var(--size-touch-target)',
        'padding': 'var(--space-md)',
        'position': 'relative',
        'text-align': 'left',
        'text-decoration': 'none',
        'width': '100%',
      },
    ),
    // The thin line between rows, which stops short of the edges.
    css('.glass-row + .glass-row::before').styles(
      raw: {
        'background': 'var(--color-hairline)',
        'content': '""',
        'height': '1px',
        'left': 'var(--space-md)',
        'position': 'absolute',
        'right': 'var(--space-md)',
        'top': '0',
      },
    ),
    // A row with a button of its own: the link takes the row but the button.
    css('.glass-row--split').styles(
      raw: {'gap': '0', 'padding': '0 var(--space-xs) 0 0'},
    ),
    css('.glass-row__link').styles(
      raw: {
        'align-items': 'center',
        'align-self': 'stretch',
        'background': 'none',
        'border': '0',
        'color': 'inherit',
        'cursor': 'pointer',
        'display': 'flex',
        'flex': '1',
        'font': 'inherit',
        'gap': 'var(--space-sm)',
        'min-width': '0',
        'padding':
            'var(--space-md) var(--space-xs) var(--space-md) var(--space-md)',
        'text-align': 'left',
        'text-decoration': 'none',
        'transition':
            'background var(--duration-fast), '
            'box-shadow var(--duration-fast)',
      },
    ),
    css('.glass-row--indented').styles(
      raw: {'padding-left': 'calc(var(--space-md) + var(--space-xl))'},
    ),
    css('.glass-row--action').styles(
      raw: {
        'cursor': 'pointer',
        'transition':
            'background var(--duration-fast), '
            'box-shadow var(--duration-fast)',
      },
    ),
    // Only where a pointer can hover: on a touch screen it would stay on.
    css.media(const MediaQuery.raw('(hover: hover)'), [
      css('.glass-row--action:hover, .glass-row__link:hover').styles(
        raw: {'background': 'var(--color-glass-fill-bottom)'},
      ),
    ]),
    // The row whose card is open beside the list, hovered or not.
    css('.glass-row.glass-row--picked').styles(
      raw: {
        'background': 'var(--color-surface-selected)',
        'box-shadow': 'inset 3px 0 0 var(--color-accent)',
      },
    ),
    css('.glass-row__text').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'min-width': '0',
      },
    ),
    css('.glass-row__line').styles(
      raw: {
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.glass-row__subtitle').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.glass-row__lines').styles(
      raw: {
        '-webkit-box-orient': 'vertical',
        'display': '-webkit-box',
        'overflow': 'hidden',
      },
    ),
    css('.glass-row--danger').styles(raw: {'color': 'var(--color-negative)'}),
    // A row that has just come opens from nothing and pushes the rows after
    // it down.
    css('.glass-row--entering').styles(
      raw: {
        'animation':
            'glass-row-open var(--duration-slow) var(--easing-standard) both',
        'overflow': 'hidden',
      },
    ),
    css.keyframes('glass-row-open', {
      'from': const Styles(
        raw: {
          'max-height': '0',
          'min-height': '0',
          'opacity': '0',
          'padding-bottom': '0',
          'padding-top': '0',
        },
      ),
      'to': const Styles(
        raw: {
          'max-height': '160px',
          'min-height': 'var(--size-touch-target)',
          'opacity': '1',
          'padding-bottom': 'var(--space-md)',
          'padding-top': 'var(--space-md)',
        },
      ),
    }),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.glass-row--entering').styles(raw: {'animation': 'none'}),
    ]),
  ];
}
