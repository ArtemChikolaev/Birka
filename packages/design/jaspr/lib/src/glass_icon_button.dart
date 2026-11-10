import 'dart:async';

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
    this.badge,
    this.glass = true,
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

  /// How many new things wait behind the button, such as the new notices
  /// behind the bell, on its corner: the count jumps once when it grows, and
  /// shrinks away at nought. A button that never counts leaves it `null`.
  /// [label] says the count itself.
  final int? badge;

  /// Whether the button stands on glass. A plain one, such as the cross on a
  /// row of a list, is only its mark.
  final bool glass;

  @override
  Component build(BuildContext context) {
    final classes = glass
        ? 'glass glass-icon-button'
        : 'glass-icon-button glass-icon-button--plain';
    final attributes = {'aria-label': label};
    final badge = this.badge;
    final content = [BirkaIcon(glyph), if (badge != null) _Count(badge)];
    if (href case final href?) {
      return a(classes: classes, href: href, attributes: attributes, content);
    }
    return button(
      classes: classes,
      type: ButtonType.button,
      onClick: onPressed,
      attributes: attributes,
      content,
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
        'position': 'relative',
        'width': 'var(--size-touch-target)',
      },
    ),
    css('.glass-icon-button--plain').styles(
      raw: {
        'align-items': 'center',
        'background': 'none',
        'border': '0',
        'border-radius': 'var(--radius-pill)',
        'color': 'var(--color-text-subtle)',
        'cursor': 'pointer',
        'display': 'flex',
        'flex': 'none',
        'height': 'var(--size-touch-target)',
        'justify-content': 'center',
        'padding': '0',
        'transition': 'color var(--duration-fast)',
        'width': 'var(--size-touch-target)',
      },
    ),
    css('.glass-icon-button--plain:hover').styles(
      raw: {'color': 'var(--color-text)'},
    ),
    css('.glass-icon-button--plain .birka-icon').styles(
      raw: {'height': '18px', 'width': '18px'},
    ),
    // A ring of the background keeps the count off the glass.
    css('.glass-icon-button__badge').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-accent)',
        'border': '2px solid var(--color-background)',
        'border-radius': 'var(--radius-pill)',
        'box-sizing': 'border-box',
        'color': 'var(--color-on-accent)',
        'display': 'flex',
        'font-variant-numeric': 'tabular-nums',
        'height': 'var(--size-badge)',
        'justify-content': 'center',
        'letter-spacing': '0',
        'line-height': '1',
        'min-width': 'var(--size-badge)',
        'padding': '0 var(--space-xxs)',
        'pointer-events': 'none',
        'position': 'absolute',
        'right': 'calc(-1 * var(--space-xxs))',
        'top': 'calc(-1 * var(--space-xxs))',
        'transition':
            'opacity var(--duration-base) var(--easing-fade), '
            'transform var(--duration-slow) var(--easing-spring)',
      },
    ),
    css('.glass-icon-button__badge--off').styles(
      raw: {'opacity': '0', 'transform': 'scale(0.4)'},
    ),
    // A count that grows jumps up for a moment and settles with a bounce.
    css('.glass-icon-button__badge--jump').styles(
      raw: {
        'transform': 'scale(1.3)',
        'transition':
            'opacity var(--duration-base) var(--easing-fade), '
            'transform var(--duration-fast) var(--easing-standard)',
      },
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css(
        '.glass-icon-button__badge, .glass-icon-button__badge--off, '
        '.glass-icon-button__badge--jump',
      ).styles(raw: {'transform': 'none'}),
    ]),
  ];
}

/// The count on the corner of a [GlassIconButton].
class _Count extends StatefulComponent {
  const _Count(this.count);

  final int count;

  @override
  State<_Count> createState() => _CountState();
}

class _CountState extends State<_Count> {
  /// How long the count stays up when it jumps, which is `duration.fast`.
  static const _jump = Duration(milliseconds: 150);

  // The figure stays while the count shrinks away at nought.
  late int _shown = component.count;
  var _jumping = false;
  Timer? _settle;

  @override
  void didUpdateComponent(_Count oldComponent) {
    super.didUpdateComponent(oldComponent);
    final count = component.count;
    if (count > 0) _shown = count;
    if (oldComponent.count > 0 && count > oldComponent.count) {
      _jumping = true;
      _settle?.cancel();
      _settle = Timer(_jump, () {
        if (mounted) setState(() => _jumping = false);
      });
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final classes = [
      'text-label glass-icon-button__badge',
      if (component.count <= 0) 'glass-icon-button__badge--off',
      if (_jumping) 'glass-icon-button__badge--jump',
    ].join(' ');
    return span(
      classes: classes,
      attributes: const {'aria-hidden': 'true'},
      [.text('$_shown')],
    );
  }
}
