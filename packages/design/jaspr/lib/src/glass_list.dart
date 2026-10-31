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
/// with a [subtitle] under it and an optional [trailing] component.
class GlassListRow extends StatelessComponent {
  /// Creates a row. With [href] it is a link and with [onTap] a button.
  const GlassListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.href,
    this.onTap,
    this.indented = false,
    super.key,
  });

  /// The main line.
  final String title;

  /// The quieter line under [title].
  final String? subtitle;

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

  @override
  Component build(BuildContext context) {
    final subtitle = this.subtitle;
    final indent = indented ? ' glass-row--indented' : '';
    final content = [
      ?leading,
      span(classes: 'glass-row__text', [
        span(classes: 'text-body-strong glass-row__line', [.text(title)]),
        if (subtitle != null)
          span(classes: 'text-caption glass-row__line glass-row__subtitle', [
            .text(subtitle),
          ]),
      ]),
      ?trailing,
    ];
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
    css('.glass-row--indented').styles(
      raw: {'padding-left': 'calc(var(--space-md) + var(--space-xl))'},
    ),
    css('.glass-row--action').styles(
      raw: {
        'cursor': 'pointer',
        'transition': 'background var(--duration-fast)',
      },
    ),
    // Only where a pointer can hover: on a touch screen it would stay on.
    css.media(const MediaQuery.raw('(hover: hover)'), [
      css('.glass-row--action:hover').styles(
        raw: {'background': 'var(--color-glass-fill-bottom)'},
      ),
    ]),
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
  ];
}
