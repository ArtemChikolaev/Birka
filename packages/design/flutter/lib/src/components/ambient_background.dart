import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Birka's backdrop: the background color with a faint glow of
/// [BirkaColors.ambient] in the top left and bottom right corners and on the
/// left edge.
///
/// It goes behind a whole screen, and glass on top of it picks up the glow.
/// It also makes the system bars see-through; the app has to draw edge to
/// edge for the glow to reach behind them.
class AmbientBackground extends StatelessWidget {
  /// Creates the backdrop behind [child].
  const AmbientBackground({required this.child, super.key});

  /// The content in front of the backdrop.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: BirkaTheme.systemBars,
      child: ColoredBox(
        color: colors.background,
        child: CustomPaint(
          painter: _GlowPainter(colors.ambient),
          // Content that repaints, such as a scrolling list, leaves the glow
          // as it is.
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }
}

/// The glows of the mockups, where CSS has `radial-gradient(62% 34% at 0% 0%,
/// ambient 0%, transparent 74%)` and so on: an ellipse around `center` with
/// `radii`, both as fractions of the size, that fades out at `fade` of its
/// radii.
const _glows = <({Offset center, Size radii, double fade})>[
  (center: Offset.zero, radii: Size(0.62, 0.34), fade: 0.74),
  (center: Offset(1, 1), radii: Size(0.66, 0.38), fade: 0.74),
  (center: Offset(0, 0.72), radii: Size(0.64, 0.2), fade: 0.72),
];

final class _GlowPainter extends CustomPainter {
  const _GlowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // A unit circle that fades from the color to nothing, which each glow
    // stretches into its ellipse.
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
    canvas.clipRect(Offset.zero & size);
    for (final glow in _glows) {
      canvas
        ..save()
        ..translate(glow.center.dx * size.width, glow.center.dy * size.height)
        ..scale(
          glow.radii.width * glow.fade * size.width,
          glow.radii.height * glow.fade * size.height,
        )
        ..drawCircle(Offset.zero, 1, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => oldDelegate.color != color;
}
