import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A round button of glass with an icon, such as the way back from a screen.
class GlassIconButton extends StatelessComponent {
  /// Creates a button with [glyph]. Screen readers read [label]. With [href]
  /// it is a link.
  const GlassIconButton({
    required this.glyph,
    required this.label,
    this.href,
    this.onPressed,
    super.key,
  });

  /// What the button shows.
  final BirkaGlyph glyph;

  /// What the button does, for screen readers.
  final String label;

  /// Where the button leads.
  final String? href;

  /// Called on a click.
  final VoidCallback? onPressed;

  @override
  Component build(BuildContext context) {
    const classes = 'glass glass-icon-button';
    final attributes = {'aria-label': label};
    final icon = [BirkaIcon(glyph)];
    if (href case final href?) {
      return a(classes: classes, href: href, attributes: attributes, icon);
    }
    return button(
      classes: classes,
      type: ButtonType.button,
      onClick: onPressed,
      attributes: attributes,
      icon,
    );
  }

  /// The styles of the button.
  @css
  static List<StyleRule> get styles => [
    css('.glass.glass-icon-button').styles(
      raw: {
        'align-items': 'center',
        'border-radius': 'var(--radius-pill)',
        'color': 'var(--color-text)',
        'cursor': 'pointer',
        'display': 'flex',
        'flex': 'none',
        'height': 'var(--size-touch-target)',
        'justify-content': 'center',
        'padding': '0',
        'width': 'var(--size-touch-target)',
      },
    ),
  ];
}
