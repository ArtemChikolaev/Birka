import 'dart:math' as math;

import 'package:design_tokens/design_tokens.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
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
/// the way down, as the scrolling forms of the app do. It measures where it
/// starts as the page scrolls: under the header of the page at the top, and
/// at `space.lg` from the top of the window once the side sticks there.
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
        // The panel starts at --glass-panel-top, and the tabs take
        // --size-nav-bar at --space-xl from the bottom. Until it has measured
        // its top, it takes the place where the side sticks.
        'max-height':
            'calc(100dvh - var(--glass-panel-top, var(--space-lg)) '
            '- var(--size-nav-bar) - var(--space-xl) - var(--space-md))',
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
  final _panel = GlobalNodeKey<web.HTMLElement>();
  late final JSFunction _placeListener = _onPlaceChanged.toJS;

  /// How far below the top of the window the panel starts, in whole pixels,
  /// once it has measured it. It is never above where the side sticks: past
  /// the end of the list the side goes up with the page, and the panel keeps
  /// its height.
  int? _top;

  /// How far the top edge has faded in: 0 at the top, and 1 once the view
  /// has scrolled by `size.scrollEdge`.
  var _edge = 0.0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    web.window
      ..addEventListener('scroll', _placeListener)
      ..addEventListener('resize', _placeListener);
    context.binding.addPostFrameCallback(_measure);
  }

  @override
  void dispose() {
    if (kIsWeb) {
      web.window
        ..removeEventListener('scroll', _placeListener)
        ..removeEventListener('resize', _placeListener);
    }
    super.dispose();
  }

  void _onPlaceChanged(web.Event event) => _measure();

  void _measure() {
    final node = _panel.currentNode;
    if (node == null) return;
    final top = math.max(
      _layoutTop(node).round(),
      BirkaTokens.spaceLg.round(),
    );
    if (top != _top) setState(() => _top = top);
  }

  /// Where [node] starts below the top of the window without the rise it
  /// comes in with: its place in the parent that places it, such as the side
  /// that sticks, which does not move with the rise.
  static double _layoutTop(web.HTMLElement node) {
    final parent = node.offsetParent;
    if (parent == null) return node.getBoundingClientRect().top;
    return parent.getBoundingClientRect().top +
        parent.clientTop +
        node.offsetTop;
  }

  void _scrolled(web.Event event) {
    final top = (event.target! as web.HTMLElement).scrollTop;
    final edge = (top / BirkaTokens.sizeScrollEdge).clamp(0.0, 1.0);
    if (edge != _edge) setState(() => _edge = edge);
  }

  @override
  Component build(BuildContext context) {
    final top = _top;
    final scrolled = _edge > 0;
    return div(
      key: _panel,
      classes: 'glass glass-panel',
      styles: top == null
          ? null
          : Styles(raw: {'--glass-panel-top': '${top}px'}),
      [
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
      ],
    );
  }
}
