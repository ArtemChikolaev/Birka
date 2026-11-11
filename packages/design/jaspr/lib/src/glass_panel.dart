import 'package:design_tokens/design_tokens.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// A pane of glass that holds a view beside a list on a wide page, such as
/// the card of an operation picked in the list or the form of a new one. It
/// comes in with a short rise; given a key of the view it holds, it comes in
/// anew with each view. When the system asks for less motion, it is there at
/// once.
///
/// It stays within the window above the tabs of the site, so that a form
/// keeps its button in reach in a low window: what does not fit scrolls in
/// the panel, and its top edge fades in over the first `size.scrollEdge` of
/// the way down, as the scrolling forms of the app do.
class GlassPanel extends StatefulComponent {
  /// Creates a panel around [child].
  const GlassPanel({required this.child, super.key});

  /// The view in the panel.
  final Component child;

  @override
  State<GlassPanel> createState() => _GlassPanelState();

  /// The styles of the panel.
  @css
  static List<StyleRule> get styles => [
    css('.glass.glass-panel').styles(
      raw: {
        'animation':
            'glass-panel-in var(--duration-base) var(--easing-standard) both',
        'display': 'flex',
        'flex-direction': 'column',
        // The side sticks at --space-lg from the top, and the tabs take
        // --size-nav-bar at --space-xl from the bottom.
        'max-height':
            'calc(100dvh - var(--space-lg) - var(--size-nav-bar) '
            '- var(--space-xl) - var(--space-md))',
        'padding': '0',
      },
    ),
    css('.glass-panel__body').styles(
      raw: {
        'min-height': '0',
        'overflow-y': 'auto',
        'overscroll-behavior': 'contain',
        'padding': 'var(--space-md)',
      },
    ),
    css('.glass-panel__body--scrolled').styles(
      raw: {
        '-webkit-mask-image': _edgeMask,
        'mask-image': _edgeMask,
      },
    ),
    css.keyframes('glass-panel-in', {
      'from': const Styles(
        raw: {'opacity': '0', 'transform': 'translateY(var(--space-xs))'},
      ),
      'to': const Styles(raw: {'opacity': '1', 'transform': 'none'}),
    }),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.glass.glass-panel').styles(raw: {'animation': 'none'}),
    ]),
  ];

  /// The view fades out at the top edge as much as `--glass-panel-edge` says.
  static const _edgeMask =
      'linear-gradient(to bottom, '
      'rgb(0 0 0 / calc(1 - var(--glass-panel-edge, 0))) 0, '
      '#000 var(--size-scroll-edge))';
}

class _GlassPanelState extends State<GlassPanel> {
  /// How far the top edge has faded in: 0 at the top, and 1 once the view
  /// has scrolled by `size.scrollEdge`.
  var _edge = 0.0;

  void _scrolled(web.Event event) {
    final top = (event.target! as web.HTMLElement).scrollTop;
    final edge = (top / BirkaTokens.sizeScrollEdge).clamp(0.0, 1.0);
    if (edge != _edge) setState(() => _edge = edge);
  }

  @override
  Component build(BuildContext context) {
    final scrolled = _edge > 0;
    return div(classes: 'glass glass-panel', [
      div(
        classes: scrolled
            ? 'glass-panel__body glass-panel__body--scrolled'
            : 'glass-panel__body',
        styles: scrolled
            ? Styles(raw: {'--glass-panel-edge': _edge.toStringAsFixed(2)})
            : null,
        events: {'scroll': _scrolled},
        [component.child],
      ),
    ]);
  }
}
