import 'dart:ui' show ImageFilter;

import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/glass_filter.dart';
import 'package:design_flutter/src/components/glass_painter.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A tab of a [GlassNavBar].
final class GlassNavDestination {
  /// Creates a tab.
  const GlassNavDestination({required this.glyph, required this.label});

  /// The icon.
  final BirkaGlyph glyph;

  /// The label.
  final String label;
}

/// A floating pill of glass with tabs, a bubble that springs to the selected
/// one, and the main action in the middle.
///
/// It floats over the content, so it stays out of any `BackdropGroup`: it has
/// to blur the glass beneath it too.
class GlassNavBar extends StatelessWidget {
  /// Creates a bar with [destinations] around the action.
  const GlassNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  /// The tabs, half of them on each side of the action.
  final List<GlassNavDestination> destinations;

  /// The selected tab.
  final int selectedIndex;

  /// Called with the index of a tab when it is tapped.
  final ValueChanged<int> onSelected;

  /// What the action does, for screen readers.
  final String actionLabel;

  /// Called when the action is tapped.
  final VoidCallback onAction;

  // The gap between the edge of the bar and the bubble.
  static const double _inset = 6;
  static const _actionSize = 50.0;
  static const _radius = BorderRadius.all(
    Radius.circular(BirkaTokens.sizeNavBar / 2),
  );
  static const _bubbleRadius = BorderRadius.all(
    Radius.circular((BirkaTokens.sizeNavBar - _inset * 2) / 2),
  );

  static final ImageFilter _filter = glassFilter(
    blur: BirkaTokens.blurNav,
    saturation: BirkaTokens.saturationNav,
  );

  static final Curve _spring = Cubic(
    BirkaTokens.easingSpring[0],
    BirkaTokens.easingSpring[1],
    BirkaTokens.easingSpring[2],
    BirkaTokens.easingSpring[3],
  );

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final actionSlot = destinations.length ~/ 2;
    return SizedBox(
      height: BirkaTokens.sizeNavBar,
      child: CustomPaint(
        painter: const OuterShadowPainter(
          borderRadius: _radius,
          shadows: BirkaTokens.shadowNav,
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: BackdropFilter(
            filter: _filter,
            child: CustomPaint(
              painter: GlassPainter(
                borderRadius: _radius,
                fillTop: colors.navFill,
                fillBottom: colors.navFill,
                highlight: colors.navHighlight,
                lowlight: colors.navLowlight,
                border: colors.glassBorder,
              ),
              child: Padding(
                padding: const EdgeInsets.all(_inset),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final slot =
                        constraints.maxWidth / (destinations.length + 1);
                    final selectedSlot = selectedIndex < actionSlot
                        ? selectedIndex
                        : selectedIndex + 1;
                    return Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(
                            milliseconds: BirkaTokens.durationSpringMs,
                          ),
                          curve: _spring,
                          left: slot * selectedSlot,
                          top: 0,
                          bottom: 0,
                          width: slot,
                          child: _Bubble(colors: colors),
                        ),
                        Row(
                          children: [
                            for (final (index, destination)
                                in destinations.indexed) ...[
                              if (index == actionSlot)
                                Expanded(
                                  child: _Action(
                                    label: actionLabel,
                                    colors: colors,
                                    onTap: onAction,
                                  ),
                                ),
                              Expanded(
                                child: _Tab(
                                  destination: destination,
                                  selected: index == selectedIndex,
                                  colors: colors,
                                  onTap: () => onSelected(index),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.colors});

  final BirkaColors colors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const OuterShadowPainter(
        borderRadius: GlassNavBar._bubbleRadius,
        shadows: BirkaTokens.shadowNavBubble,
      ),
      child: CustomPaint(
        painter: GlassPainter(
          borderRadius: GlassNavBar._bubbleRadius,
          fillTop: colors.navBubble,
          fillBottom: colors.navBubble,
          highlight: colors.navBubbleHighlight,
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.destination,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool selected;
  final BirkaColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? colors.accent : colors.navLabel;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BirkaIcon(destination.glyph, color: color),
            const SizedBox(height: 3),
            Text(
              destination.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: BirkaTextStyles.of(context).tab.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final BirkaColors colors;
  final VoidCallback onTap;

  static const _radius = BorderRadius.all(
    Radius.circular(GlassNavBar._actionSize / 2),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: SizedBox.square(
            dimension: GlassNavBar._actionSize,
            child: CustomPaint(
              painter: const OuterShadowPainter(
                borderRadius: _radius,
                shadows: BirkaTokens.shadowAccentGlow,
              ),
              child: CustomPaint(
                painter: GlassPainter(
                  borderRadius: _radius,
                  fillTop: colors.accent,
                  fillBottom: colors.accent,
                  highlight: colors.accentHighlight,
                ),
                child: Center(
                  child: BirkaIcon(
                    BirkaGlyph.plus,
                    size: 24,
                    color: colors.onAccent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
