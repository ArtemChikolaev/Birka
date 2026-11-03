import 'dart:async';

import 'package:design_flutter/src/components/in_sight.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// The abstract art of a card: a dark base with a glow of one color.
enum CardArt {
  /// Green.
  emerald(BirkaTokens.colorArtEmerald),

  /// Gray with a light stripe.
  graphite(BirkaTokens.colorArtGraphite),

  /// Blue.
  sapphire(BirkaTokens.colorArtSapphire),

  /// Warm brown, which glows from the top.
  amber(BirkaTokens.colorArtAmber),

  /// Violet.
  violet(BirkaTokens.colorArtViolet),

  /// Pink.
  rose(BirkaTokens.colorArtRose)
  ;

  const CardArt(this._color);

  final int _color;

  /// The color of the glow.
  Color get color => Color(_color);
}

/// A card with [art] behind [child].
///
/// A new art fades in over the old one over `duration.slow`, once the card
/// is in sight, and takes its place at once when the system asks for less
/// motion.
class CardArtSurface extends StatefulWidget {
  /// Creates a card.
  const CardArtSurface({
    required this.art,
    this.child,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(BirkaTokens.radiusXl),
    ),
    this.borderColor,
    super.key,
  });

  /// What the card shows.
  final CardArt art;

  /// What stands on the art.
  final Widget? child;

  /// The corners of the card.
  final BorderRadius borderRadius;

  /// The color of the border, by default that of glass.
  final Color? borderColor;

  @override
  State<CardArtSurface> createState() => _CardArtSurfaceState();
}

class _CardArtSurfaceState extends State<CardArtSurface>
    with SingleTickerProviderStateMixin, InSight {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: BirkaMotion.slow,
    value: 1,
  );
  late final Animation<double> _shown = _fade.drive(
    CurveTween(curve: BirkaMotion.standardCurve),
  );

  /// The art that the new one fades in over.
  late CardArt _under = widget.art;

  @override
  void didUpdateWidget(CardArtSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.art == oldWidget.art) return;
    if (BirkaMotion.reduced(context)) {
      forgetHeld();
      _under = widget.art;
      _fade.value = 1;
      return;
    }
    // A change halfway through fades from the art that shows the most.
    if (_fade.value >= 0.5) _under = oldWidget.art;
    _fade.value = 0;
    whenInSight(() => unawaited(_fade.forward()));
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final borderRadius = widget.borderRadius;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: widget.borderColor ?? colors.glassBorder),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(
          painter: _ArtPainter(
            under: _under,
            art: widget.art,
            shown: _shown,
            base: colors.surface,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A small [CardArtSurface] for a row of a list.
class CardArtThumbnail extends StatelessWidget {
  /// Creates a thumbnail of [art]. A [highlighted] one has an accent border.
  const CardArtThumbnail({
    required this.art,
    this.highlighted = false,
    super.key,
  });

  /// What the thumbnail shows.
  final CardArt art;

  /// Whether the thumbnail stands out, such as for the main account.
  final bool highlighted;

  /// The size of a thumbnail.
  static const Size size = Size(48, 34);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: CardArtSurface(
        art: art,
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusXs),
        ),
        borderColor: highlighted ? BirkaColors.of(context).accent : null,
      ),
    );
  }
}

class _ArtPainter extends CustomPainter {
  _ArtPainter({
    required this.under,
    required this.art,
    required this.shown,
    required this.base,
  }) : super(repaint: shown);

  /// The art that [art] fades in over.
  final CardArt under;
  final CardArt art;

  /// How far [art] has come in, from 0 to 1.
  final Animation<double> shown;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shown = this.shown.value;
    if (shown >= 1) {
      _paintArt(canvas, rect, art);
      return;
    }
    _paintArt(canvas, rect, under);
    if (shown <= 0) return;
    canvas.saveLayer(
      rect,
      Paint()..color = Color.fromRGBO(0, 0, 0, shown),
    );
    _paintArt(canvas, rect, art);
    canvas.restore();
  }

  void _paintArt(Canvas canvas, Rect rect, CardArt art) {
    final color = art.color;
    canvas
      ..drawRect(rect, Paint()..color = base)
      // A faint wash from the top left corner.
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.center,
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ).createShader(rect),
      )
      // The glow, which sits in a corner and fills most of the card.
      ..drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: art == CardArt.amber
                ? Alignment.topLeft
                : Alignment.bottomRight,
            radius: 1.25,
            colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0)],
          ).createShader(rect),
      );
    if (art == CardArt.graphite) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: const Alignment(-0.2, 1),
            end: const Alignment(0.5, -1),
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: 0.55),
              color.withValues(alpha: 0),
            ],
            stops: const [0.42, 0.5, 0.58],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_ArtPainter oldDelegate) =>
      under != oldDelegate.under ||
      art != oldDelegate.art ||
      shown != oldDelegate.shown ||
      base != oldDelegate.base;
}
