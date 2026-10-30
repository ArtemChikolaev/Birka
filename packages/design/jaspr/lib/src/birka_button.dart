import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The main action of a screen: an emerald pill with a label in capitals.
class BirkaButton extends StatelessComponent {
  /// Creates a button. With [href] it is a link, and with no [href],
  /// [onPressed] or [submits] it is disabled.
  const BirkaButton({
    required this.label,
    this.onPressed,
    this.href,
    this.submits = false,
    this.quiet = false,
    super.key,
  });

  /// The label as written, not in capitals.
  final String label;

  /// Called on a click.
  final VoidCallback? onPressed;

  /// Where the button leads.
  final String? href;

  /// Whether the button submits the form around it.
  final bool submits;

  /// Whether this is the second choice next to a main action, with no
  /// emerald.
  final bool quiet;

  @override
  Component build(BuildContext context) {
    final classes =
        'text-label birka-button${quiet ? ' birka-button--quiet' : ''}';
    if (href case final href?) {
      return a(classes: classes, href: href, [.text(label)]);
    }
    return button(
      classes: classes,
      type: submits ? ButtonType.submit : ButtonType.button,
      disabled: !submits && onPressed == null,
      onClick: onPressed,
      [.text(label)],
    );
  }

  /// The styles of the button.
  @css
  static List<StyleRule> get styles => [
    css('.birka-button').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-accent)',
        'border': '0',
        'border-radius': 'var(--radius-pill)',
        'box-sizing': 'border-box',
        'color': 'var(--color-on-accent)',
        'cursor': 'pointer',
        'display': 'flex',
        'height': '56px',
        'justify-content': 'center',
        'padding': '0 var(--space-lg)',
        'text-decoration': 'none',
        'transition': 'opacity var(--duration-fast)',
        'width': '100%',
      },
    ),
    css('.birka-button:disabled').styles(
      raw: {'cursor': 'default', 'opacity': '0.5'},
    ),
    css('.birka-button--quiet').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'color': 'var(--color-text)',
      },
    ),
  ];
}
