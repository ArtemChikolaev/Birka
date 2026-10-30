import 'package:design_flutter/src/theme/birka_colors.dart';
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
class CardArtSurface extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? colors.glassBorder),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(
          painter: _ArtPainter(art: art, base: colors.surface),
          child: child,
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
  const _ArtPainter({required this.art, required this.base});

  final CardArt art;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
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
      art != oldDelegate.art || base != oldDelegate.base;
}
