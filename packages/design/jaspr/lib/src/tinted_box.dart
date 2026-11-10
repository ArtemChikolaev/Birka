import 'package:design_jaspr/src/birka_icon.dart';
import 'package:design_jaspr/src/glyph_badge.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A box tinted with [color], as a [TintedNotice] is, around [children],
/// such as a payment that waits for the person with its buttons.
class TintedBox extends StatelessComponent {
  /// Creates a box.
  const TintedBox({required this.color, required this.children, super.key});

  /// The color of the tint, as CSS.
  final String color;

  /// What the box holds.
  final List<Component> children;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'tinted-box',
      styles: Styles(raw: {'--tint': color}),
      children,
    );
  }

  /// The styles of the box.
  @css
  static List<StyleRule> get styles => [
    css('.tinted-box').styles(
      raw: {
        // The box of a component sets its own color over this one.
        '--tint': 'var(--color-accent)',
        'background': 'color-mix(in srgb, var(--tint) 10%, transparent)',
        'border': '1px solid color-mix(in srgb, var(--tint) 28%, transparent)',
        'border-radius': 'var(--radius-md)',
        'box-sizing': 'border-box',
        'display': 'flex',
        'flex-direction': 'column',
        'padding': 'var(--space-md)',
      },
    ),
  ];
}

/// A box tinted with [color] that says what the person should know before
/// going on, such as a payment that a statement brought: an optional [title]
/// in that color over the [text], and the mark of [glyph] before them.
class TintedNotice extends StatelessComponent {
  /// Creates a notice.
  const TintedNotice({
    required this.color,
    required this.text,
    this.title,
    this.glyph,
    super.key,
  });

  /// The color of the tint, of the title and of the mark, as CSS.
  final String color;

  /// What the notice says.
  final String text;

  /// The heading over [text], which then gets quieter.
  final String? title;

  /// The mark before the words.
  final BirkaGlyph? glyph;

  @override
  Component build(BuildContext context) {
    final title = this.title;
    final glyph = this.glyph;
    return TintedBox(
      color: color,
      children: [
        div(classes: 'tinted-notice', [
          if (glyph != null) GlyphBadge(glyph: glyph, color: color),
          div(classes: 'tinted-notice__words', [
            if (title != null)
              span(classes: 'text-body-strong tinted-notice__title', [
                .text(title),
              ]),
            span(
              classes: title == null
                  ? 'text-body tinted-notice__text'
                  : 'text-body tinted-notice__text tinted-notice__text--quiet',
              [.text(text)],
            ),
          ]),
        ]),
      ],
    );
  }

  /// The styles of the notice.
  @css
  static List<StyleRule> get styles => [
    css('.tinted-notice').styles(
      raw: {
        'align-items': 'flex-start',
        'display': 'flex',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.tinted-notice__words').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
      },
    ),
    css('.tinted-notice__title').styles(raw: {'color': 'var(--tint)'}),
    css('.tinted-notice__text').styles(raw: {'color': 'var(--color-text)'}),
    css('.tinted-notice__text--quiet').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
  ];
}
