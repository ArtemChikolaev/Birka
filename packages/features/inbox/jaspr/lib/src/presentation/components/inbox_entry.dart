import 'package:design_jaspr/design_jaspr.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The color of what waits for the person.
const _waits = 'var(--color-palette-amber)';

/// The way to the inbox on the overview, as its board draws it (ADR 0022,
/// point 9): a strip that says how much waits and after which import and
/// leads to [href]. With nothing waiting it leaves no trace in the page. It
/// needs an [InboxSummaryCubit] above it.
class InboxCard extends StatelessComponent {
  /// Creates the strip.
  const InboxCard({required this.href, super.key});

  /// Where the inbox opens.
  final String href;

  @override
  Component build(BuildContext context) {
    return BlocBuilder<InboxSummaryCubit, InboxState>(
      builder: (context, state) {
        final count = state.count;
        if (count == 0) return const Component.empty();
        return a(classes: 'inbox-card', href: href, [
          const GlyphBadge(glyph: BirkaGlyph.inbox, color: _waits, size: 40),
          span(classes: 'inbox-card__text', [
            span(classes: 'text-body-strong', [
              .text(t.inbox.entryTitle(n: count, count: formatCount(count))),
            ]),
            span(classes: 'text-caption inbox-card__line', [
              .text(entryLine(state)),
            ]),
          ]),
          const span(classes: 'inbox-card__end', [
            BirkaIcon(BirkaGlyph.chevron),
          ]),
        ]);
      },
    );
  }

  /// The styles of the strip.
  @css
  static List<StyleRule> get styles => [
    css('.inbox-card').styles(
      raw: {
        'align-items': 'center',
        'background':
            'linear-gradient(90deg, '
            'color-mix(in srgb, $_waits 14%, transparent), '
            'color-mix(in srgb, $_waits 3%, transparent))',
        'border': '1px solid color-mix(in srgb, $_waits 26%, transparent)',
        'border-radius': 'var(--radius-lg)',
        'color': 'var(--color-text)',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'padding': 'var(--space-sm) var(--space-md)',
        'text-decoration': 'none',
      },
    ),
    css('.inbox-card__text').styles(
      raw: {
        'display': 'flex',
        'flex': '1 1 auto',
        'flex-direction': 'column',
        'min-width': '0',
      },
    ),
    css('.inbox-card__line').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.inbox-card__end').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'flex': 'none',
      },
    ),
    css('.inbox-card__end .birka-icon').styles(
      raw: {'height': '18px', 'width': '18px'},
    ),
  ];
}

/// The way to the inbox in More, as its board draws it (ADR 0022, point 9):
/// a row of glass that says how much waits and after which import, or that
/// all is sorted, with the count at its end, and leads to [href]. Without
/// [state], such as while another tab holds the data, it says nothing of
/// what waits.
class InboxTile extends StatelessComponent {
  /// Creates the row.
  const InboxTile({required this.href, this.state, super.key});

  /// Where the inbox opens.
  final String href;

  /// What waits, once it is counted.
  final InboxState? state;

  @override
  Component build(BuildContext context) {
    final counted = switch (state) {
      final state? when !state.loading && !state.failed => state,
      _ => null,
    };
    final count = counted?.count;
    return GlassListGroup(
      children: [
        GlassListRow(
          title: t.inbox.title,
          subtitle: switch (counted) {
            null => null,
            _ when count! > 0 => waitingLabel(counted),
            _ => t.inbox.emptyTitle,
          },
          subtitleLines: 2,
          leading: const GlyphBadge(
            glyph: BirkaGlyph.inbox,
            color: _waits,
            size: 34,
          ),
          trailing: span(classes: 'inbox-tile__end', [
            if (count != null)
              span(
                classes: count > 0
                    ? 'text-caption inbox-tile__count inbox-tile__count--waits'
                    : 'text-caption inbox-tile__count',
                [.text(formatCount(count))],
              ),
            const BirkaIcon(BirkaGlyph.chevron),
          ]),
          href: href,
        ),
      ],
    );
  }

  /// The styles of the row.
  @css
  static List<StyleRule> get styles => [
    css('.inbox-tile__end').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-subtle)',
        'display': 'flex',
        'flex': 'none',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.inbox-tile__end .birka-icon').styles(
      raw: {'height': '18px', 'width': '18px'},
    ),
    css('.inbox-tile__count').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-surface-raised)',
        'border-radius': 'var(--radius-pill)',
        'box-sizing': 'border-box',
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'font-variant-numeric': 'tabular-nums',
        'font-weight': '700',
        'height': '24px',
        'justify-content': 'center',
        'min-width': '24px',
        'padding': '0 var(--space-xs)',
        'transition':
            'background var(--duration-fast) var(--easing-fade), '
            'color var(--duration-fast) var(--easing-fade)',
      },
    ),
    css('.inbox-tile__count--waits').styles(
      raw: {
        'background': 'color-mix(in srgb, $_waits 18%, transparent)',
        'color': _waits,
      },
    ),
  ];
}
