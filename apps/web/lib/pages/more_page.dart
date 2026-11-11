import 'package:birka_web/app/site_version.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:help_common/help_common.dart' show codePage;
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';
import 'package:rates/rates.dart' show CbrMirror;
import 'package:settings_jaspr/settings_jaspr.dart';

/// The tab with everything that has no tab of its own, and the settings. A
/// [wide] page has the tiles on one half and the settings on the other.
class MorePage extends StatelessComponent {
  /// Creates the page, with [inbox] as the way to the inbox over the tiles.
  const MorePage({this.inbox, this.wide = false, super.key});

  /// The way to the inbox, as wide as the tiles.
  final Component? inbox;

  /// Whether the page is wide.
  final bool wide;

  @override
  Component build(BuildContext context) {
    final inbox = this.inbox;
    final tiles = div(classes: 'more__tiles', [
      if (inbox != null) div(classes: 'more__wide', [inbox]),
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
      _Tile(
        color: 'var(--color-palette-sky)',
        label: t.app.import,
        href: 'import/',
      ),
      _Tile(
        color: 'var(--color-palette-violet)',
        label: t.app.data,
        href: 'data/',
      ),
    ]);
    final settings = [
      const SettingsSection(),
      section(classes: 'more__group', [
        div(classes: 'more__label', [SectionLabel(t.app.support)]),
        GlassListGroup(
          children: [
            GlassListRow(
              title: t.app.help,
              href: 'help/',
              trailing: const span(classes: 'more__end', [
                BirkaIcon(BirkaGlyph.chevron),
              ]),
            ),
          ],
        ),
      ]),
      // The end of the page: the version, where the records live, the
      // code and where the rates come from.
      footer(classes: 'text-caption more__footer', [
        p([.text('Birka $siteVersion · ${t.app.keptInBrowser}')]),
        p([_away(codePage.toString(), t.app.sourceCode)]),
        p([_away(CbrMirror.address, t.settings.ratesCredit)]),
      ]),
    ];
    final header = GlassPageHeader(title: t.app.more);
    if (!wide) return BirkaColumn(children: [header, tiles, ...settings]);
    return BirkaColumn(
      children: [
        header,
        BirkaSplit(halves: true, main: [tiles], aside: settings),
      ],
    );
  }

  /// A link that opens in a tab of its own, which gets no hold on the site.
  static Component _away(String href, String label) => a(
    href: href,
    target: Target.blank,
    attributes: const {'rel': 'noopener'},
    [.text(label)],
  );

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
    css('.more__wide').styles(raw: {'grid-column': '1 / -1'}),
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
    // On a narrow phone the mark takes its own line and the label stays whole.
    css('.more__line').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xxs) var(--space-xs)',
        'justify-content': 'space-between',
      },
    ),
    css('.more__soon').styles(raw: {'color': 'var(--color-text-subtle)'}),
    css('.more__group').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.more__label').styles(raw: {'color': 'var(--color-text-muted)'}),
    css('.more__end').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'display': 'flex',
        'flex': 'none',
      },
    ),
    css('.more__end .birka-icon').styles(
      raw: {'height': '18px', 'width': '18px'},
    ),
    css('.more__footer').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'margin-top': 'var(--space-sm)',
        'text-align': 'center',
      },
    ),
    css('.more__footer p').styles(raw: {'margin': '0'}),
    css('.more__footer a').styles(raw: {'color': 'var(--color-text-muted)'}),
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
        DotBadge(color: color),
        span(classes: 'more__line', [
          span(classes: 'text-body-strong', [.text(label)]),
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
