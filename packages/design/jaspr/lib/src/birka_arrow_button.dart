import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The way forward on a screen of its own: a light pill with its label at the
/// start and an arrow in a dark circle at the end.
class BirkaArrowButton extends StatelessComponent {
  /// Creates a button. With no [onPressed] or [submits] it is disabled.
  const BirkaArrowButton({
    required this.label,
    this.onPressed,
    this.submits = false,
    super.key,
  });

  /// What the button says.
  final String label;

  /// Called on a click.
  final VoidCallback? onPressed;

  /// Whether the button submits the form around it.
  final bool submits;

  @override
  Component build(BuildContext context) {
    return button(
      classes: 'text-body-strong birka-arrow-button',
      type: submits ? ButtonType.submit : ButtonType.button,
      disabled: !submits && onPressed == null,
      onClick: onPressed,
      [
        span(classes: 'birka-arrow-button__label', [.text(label)]),
        const span(classes: 'birka-arrow-button__arrow', [
          BirkaIcon(BirkaGlyph.rise),
        ]),
      ],
    );
  }

  /// The styles of the button.
  @css
  static List<StyleRule> get styles => [
    css('.birka-arrow-button').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-text)',
        'border': '0',
        'border-radius': 'var(--radius-pill)',
        'box-sizing': 'border-box',
        'color': 'var(--color-background)',
        'cursor': 'pointer',
        'display': 'flex',
        'gap': 'var(--space-xs)',
        'height': '60px',
        'padding': '8px 8px 8px var(--space-xl)',
        'text-align': 'start',
        'transition': 'opacity var(--duration-fast)',
        'width': '100%',
      },
    ),
    css('.birka-arrow-button:disabled').styles(
      raw: {'cursor': 'default', 'opacity': '0.5'},
    ),
    css('.birka-arrow-button__label').styles(
      raw: {
        'flex': '1',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.birka-arrow-button__arrow').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-background)',
        'border-radius': '50%',
        'color': 'var(--color-text)',
        'display': 'flex',
        'flex': 'none',
        'height': 'var(--size-touch-target)',
        'justify-content': 'center',
        'width': 'var(--size-touch-target)',
      },
    ),
    css('.birka-arrow-button__arrow .birka-icon').styles(
      raw: {'height': '20px', 'width': '20px'},
    ),
  ];
}
