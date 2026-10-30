import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The abstract art of a card: a dark base with a glow of one color.
enum CardArt {
  /// Green.
  emerald,

  /// Gray with a light stripe.
  graphite,

  /// Blue.
  sapphire,

  /// Warm brown, which glows from the top.
  amber,

  /// Violet.
  violet,

  /// Pink.
  rose,
}

/// A card with [art] behind [child].
class CardArtSurface extends StatelessComponent {
  /// Creates a card.
  const CardArtSurface({required this.art, this.child, super.key});

  /// What the card shows.
  final CardArt art;

  /// What stands on the art.
  final Component? child;

  @override
  Component build(BuildContext context) {
    return div(classes: 'card-art card-art--${art.name}', [?child]);
  }

  /// The styles of the art.
  @css
  static List<StyleRule> get styles => [
    css('.card-art').styles(
      raw: {
        '--art-reach': '238px',
        'border': '1px solid var(--color-glass-border)',
        'border-radius': 'var(--radius-xl)',
        'box-sizing': 'border-box',
        'overflow': 'hidden',
      },
    ),
    for (final art in CardArt.values)
      css('.card-art--${art.name}').styles(raw: {'background': _paint(art)}),
  ];

  static String _paint(CardArt art) {
    final color = 'var(--color-art-${art.name})';
    String tint(int percent) =>
        'color-mix(in srgb, $color $percent%, transparent)';
    final corner = art == CardArt.amber ? '0% 0%' : '100% 100%';
    final stripe =
        'linear-gradient(33deg, transparent 42%, ${tint(55)} 50%, '
        'transparent 58%)';
    // The glow, which sits in a corner and fills most of the card.
    final glow =
        'radial-gradient(circle var(--art-reach) at $corner, ${tint(95)}, '
        'transparent)';
    // A faint wash from the top left corner.
    final wash = 'linear-gradient(135deg, ${tint(28)}, transparent 50%)';
    return [
      if (art == CardArt.graphite) stripe,
      glow,
      wash,
      'var(--color-surface)',
    ].join(', ');
  }
}

/// A small [CardArtSurface] for a row of a list.
class CardArtThumbnail extends StatelessComponent {
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

  @override
  Component build(BuildContext context) {
    final accent = highlighted ? ' card-art--highlighted' : '';
    return div(
      classes: 'card-art card-art--${art.name} card-art--thumbnail$accent',
      const [],
    );
  }

  /// The styles of the thumbnail.
  @css
  static List<StyleRule> get styles => [
    css('.card-art--thumbnail').styles(
      raw: {
        '--art-reach': '43px',
        'border-radius': 'var(--radius-xs)',
        'flex': 'none',
        'height': '34px',
        'width': '48px',
      },
    ),
    css('.card-art--highlighted').styles(
      raw: {'border-color': 'var(--color-accent)'},
    ),
  ];
}
