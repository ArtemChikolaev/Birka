import 'dart:async';

import 'package:design_jaspr/src/birka_icon.dart';
import 'package:design_jaspr/src/glass_surface.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// What a toast offers to do about what it says, such as «Вернуть» after
/// something was taken away.
typedef ToastAction = ({String label, VoidCallback onPressed});

/// A short message on glass over the bottom of the page: what came of an
/// action, after a check mark, or what went wrong, after a cross, with an
/// [action] at its end when there is one.
///
/// It comes up from below with a little bounce over `duration.spring`, stays
/// four seconds, then goes a little down as it fades over `duration.base` and
/// calls [onGone]; when the system asks for less motion, it only fades. A
/// screen reader reads it out. A new message takes a new key, so that it
/// comes up again. Its [action] makes it go at once, as the action happens.
class GlassToast extends StatefulComponent {
  /// Creates a message that says [text].
  const GlassToast(
    this.text, {
    required this.onGone,
    this.trouble = false,
    this.action,
    super.key,
  });

  /// What it says.
  final String text;

  /// Whether it says that something went wrong.
  final bool trouble;

  /// Called once it has gone.
  final VoidCallback onGone;

  /// What it offers to do.
  final ToastAction? action;

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
    css('.glass-toast__text').styles(
      raw: {'color': 'var(--color-text)', 'flex': '1', 'min-width': '0'},
    ),
    // The button keeps the toast as tall as its text would.
    css('.glass-toast--action > .glass').styles(
      raw: {
        'padding':
            'var(--space-xs) var(--space-xs) var(--space-xs) var(--space-md)',
      },
    ),
    css('.glass-toast__action').styles(
      raw: {
        'background': 'var(--color-accent-soft)',
        'border': '0',
        'border-radius': 'var(--radius-pill)',
        'color': 'var(--color-accent)',
        'cursor': 'pointer',
        'flex': 'none',
        'padding': 'var(--space-xs) var(--space-sm)',
        'transition': 'background var(--duration-fast)',
      },
    ),
    css('.glass-toast__action:hover').styles(
      raw: {
        'background':
            'color-mix(in srgb, var(--color-accent) 24%, transparent)',
      },
    ),
    css('.glass-toast__action:focus-visible').styles(
      raw: {
        'outline': '2px solid var(--color-accent)',
        'outline-offset': '2px',
      },
    ),
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

  // The toast goes as the action happens.
  void _act(ToastAction action) {
    if (!_leaving) {
      _timer?.cancel();
      setState(() => _leaving = true);
      _timer = Timer(GlassToast.leave, component.onGone);
    }
    action.onPressed();
  }

  @override
  Component build(BuildContext context) {
    final action = component.action;
    final trouble = component.trouble ? ' glass-toast--trouble' : '';
    final leaving = _leaving ? ' glass-toast--leaving' : '';
    final acts = action == null ? '' : ' glass-toast--action';
    return div(
      classes: 'glass-toast$trouble$acts$leaving',
      attributes: const {'role': 'status', 'aria-live': 'polite'},
      [
        GlassSurface(
          child: div(classes: 'glass-toast__row', [
            BirkaIcon(component.trouble ? BirkaGlyph.close : BirkaGlyph.check),
            span(classes: 'text-body glass-toast__text', [
              .text(component.text),
            ]),
            if (action != null)
              button(
                classes: 'text-body-strong glass-toast__action',
                type: ButtonType.button,
                onClick: () => _act(action),
                [.text(action.label)],
              ),
          ]),
        ),
      ],
    );
  }
}
