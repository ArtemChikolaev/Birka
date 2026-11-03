import 'dart:async';

import 'package:design_jaspr/src/birka_icon.dart';
import 'package:design_jaspr/src/glass_surface.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A short message on glass over the bottom of the page: what came of an
/// action, after a check mark, or what went wrong, after a cross.
///
/// It comes up from below with a little bounce over `duration.spring`, stays
/// four seconds, then goes a little down as it fades over `duration.base` and
/// calls [onGone]; when the system asks for less motion, it only fades. A
/// screen reader reads it out. A new message takes a new key, so that it
/// comes up again.
class GlassToast extends StatefulComponent {
  /// Creates a message that says [text].
  const GlassToast(
    this.text, {
    required this.onGone,
    this.trouble = false,
    super.key,
  });

  /// What it says.
  final String text;

  /// Whether it says that something went wrong.
  final bool trouble;

  /// Called once it has gone.
  final VoidCallback onGone;

  /// How long the message stays.
  static const stay = Duration(seconds: 4);

  /// How long it takes to go, which is `duration.base`.
  static const leave = Duration(milliseconds: 220);

  @override
  State<GlassToast> createState() => _GlassToastState();

  /// The styles of the message.
  @css
  static List<StyleRule> get styles => [
    // It stands over the tabs, as wide as they are. The glass fades by
    // itself: an ancestor that fades would keep it from blurring the page.
    css('.glass-toast').styles(
      raw: {
        'animation':
            'glass-toast-rise var(--duration-spring) var(--easing-spring) '
            'both',
        'bottom':
            'calc(max(var(--space-xl), env(safe-area-inset-bottom)) + '
            'var(--size-nav-bar) + var(--space-sm))',
        'left': 'var(--space-lg)',
        'margin': '0 auto',
        'max-width': '456px',
        'position': 'fixed',
        'right': 'var(--space-lg)',
        'z-index': '2',
      },
    ),
    css('.glass-toast > .glass').styles(
      raw: {
        'animation':
            'glass-toast-show var(--duration-base) var(--easing-fade) both',
      },
    ),
    css('.glass-toast--leaving').styles(
      raw: {
        'animation':
            'glass-toast-sink var(--duration-base) var(--easing-standard) '
            'forwards',
      },
    ),
    css('.glass-toast--leaving > .glass').styles(
      raw: {
        'animation':
            'glass-toast-hide var(--duration-base) var(--easing-fade) forwards',
      },
    ),
    css('.glass-toast__row').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.glass-toast__row .birka-icon').styles(
      raw: {
        'color': 'var(--color-accent)',
        'flex': 'none',
        'height': '20px',
        'width': '20px',
      },
    ),
    css('.glass-toast--trouble .birka-icon').styles(
      raw: {'color': 'var(--color-negative)'},
    ),
    css('.glass-toast__text').styles(raw: {'color': 'var(--color-text)'}),
    css.keyframes('glass-toast-rise', {
      'from': const Styles(raw: {'transform': 'translateY(120px)'}),
      'to': const Styles(raw: {'transform': 'none'}),
    }),
    css.keyframes('glass-toast-show', {
      'from': const Styles(raw: {'opacity': '0'}),
      'to': const Styles(raw: {'opacity': '1'}),
    }),
    css.keyframes('glass-toast-sink', {
      'to': const Styles(raw: {'transform': 'translateY(var(--space-md))'}),
    }),
    css.keyframes('glass-toast-hide', {
      'to': const Styles(raw: {'opacity': '0'}),
    }),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.glass-toast, .glass-toast--leaving').styles(
        raw: {'animation': 'none'},
      ),
    ]),
  ];
}

class _GlassToastState extends State<GlassToast> {
  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(GlassToast.stay, () {
      setState(() => _leaving = true);
      _timer = Timer(GlassToast.leave, component.onGone);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final trouble = component.trouble ? ' glass-toast--trouble' : '';
    final leaving = _leaving ? ' glass-toast--leaving' : '';
    return div(
      classes: 'glass-toast$trouble$leaving',
      attributes: const {'role': 'status', 'aria-live': 'polite'},
      [
        GlassSurface(
          child: div(classes: 'glass-toast__row', [
            BirkaIcon(component.trouble ? BirkaGlyph.close : BirkaGlyph.check),
            span(classes: 'text-body glass-toast__text', [
              .text(component.text),
            ]),
          ]),
        ),
      ],
    );
  }
}
