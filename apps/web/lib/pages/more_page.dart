import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';

/// The tab with everything that has no tab of its own.
class MorePage extends StatelessComponent {
  /// Creates the page.
  const MorePage({super.key});

  @override
  Component build(BuildContext context) {
    return BirkaColumn(
      children: [
        GlassPageHeader(title: t.app.more),
        div(classes: 'more__tiles', [
          _Tile(
            color: 'var(--color-palette-green)',
            label: t.accounts.title,
            href: 'accounts/',
          ),
          _Tile(
            color: 'var(--color-palette-amber)',
            label: t.categories.title,
            href: 'categories/',
          ),
          _Tile(color: 'var(--color-palette-sky)', label: t.app.import),
          _Tile(color: 'var(--color-palette-violet)', label: t.app.backup),
        ]),
      ],
    );
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.more__tiles').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'repeat(2, minmax(0, 1fr))',
      },
    ),
    css('.more__link').styles(
      raw: {
        'border-radius': 'var(--radius-lg)',
        'color': 'inherit',
        'display': 'block',
        'text-decoration': 'none',
      },
    ),
    css('.more__tile').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.more__mark').styles(
      raw: {
        'align-items': 'center',
        'border-radius': 'var(--radius-sm)',
        'display': 'flex',
        'height': '36px',
        'justify-content': 'center',
        'width': '36px',
      },
    ),
    css('.more__dot').styles(
      raw: {
        'border-radius': '50%',
        'height': 'var(--space-sm)',
        'width': 'var(--space-sm)',
      },
    ),
    css('.more__line').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.more__label').styles(
      raw: {
        'flex': '1',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.more__soon').styles(raw: {'color': 'var(--color-text-subtle)'}),
  ];
}

/// A square of glass with a colored mark. Without [href] it waits for its
/// feature and says so.
class _Tile extends StatelessComponent {
  const _Tile({required this.color, required this.label, this.href});

  final String color;
  final String label;
  final String? href;

  @override
  Component build(BuildContext context) {
    final tile = GlassSurface(
      child: div(classes: 'more__tile', [
        span(
          classes: 'more__mark',
          styles: Styles(
            raw: {'background': 'color-mix(in srgb, $color 18%, transparent)'},
          ),
          [
            span(
              classes: 'more__dot',
              styles: Styles(raw: {'background': color}),
              const [],
            ),
          ],
        ),
        span(classes: 'more__line', [
          span(classes: 'text-body-strong more__label', [.text(label)]),
          if (href == null)
            span(classes: 'text-label more__soon', [.text(t.app.soon)]),
        ]),
      ]),
    );
    if (href case final href?) {
      return a(classes: 'more__link', href: href, [tile]);
    }
    return tile;
  }
}
