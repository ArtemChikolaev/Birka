import 'dart:ui' show ImageFilter;

import 'package:design_flutter/src/components/ambient_background.dart';
import 'package:design_flutter/src/components/glass_filter.dart';
import 'package:design_flutter/src/components/glass_painter.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A panel of Liquid Glass. It blurs what lies behind it and makes its
/// colors richer, fills itself with a faint white gradient and draws a
/// hairline border with a light line along the top edge.
///
/// Glass needs something behind it to show, such as an [AmbientBackground].
/// Inside a [BackdropGroup], glass surfaces share one backdrop, which is
/// cheaper for a list of cards. A surface that floats over other glass, such
/// as a navigation bar, stays out of the group: grouped filters do not see
/// each other.
class GlassSurface extends StatelessWidget {
  /// Creates a glass panel around [child].
  const GlassSurface({
    required this.child,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(BirkaTokens.radiusLg),
    ),
    this.padding = const EdgeInsets.all(BirkaTokens.spaceMd),
    super.key,
  });

  /// The content of the panel.
  final Widget child;

  /// The corners of the panel.
  final BorderRadius borderRadius;

  /// The space between the border and [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return CustomPaint(
      painter: OuterShadowPainter(
        borderRadius: borderRadius,
        shadows: BirkaTokens.shadowGlass,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter.grouped(
          filter: _filter,
          child: CustomPaint(
            painter: GlassPainter(
              borderRadius: borderRadius,
              fillTop: colors.glassFillTop,
              fillBottom: colors.glassFillBottom,
              highlight: colors.glassHighlight,
              border: colors.glassBorder,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

final ImageFilter _filter = glassFilter(
  blur: BirkaTokens.blurGlass,
  saturation: BirkaTokens.saturationGlass,
);
