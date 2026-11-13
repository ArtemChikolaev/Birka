import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:tags_common/tags_common.dart';

/// The list of метки (ADR 0027): the trip that goes on, the other trips and
/// the метки without days, each with what it took. On a wide page a [side]
/// stands beside the list, such as the report of the [picked] метка.
///
/// It needs a [TagsCubit] above it.
class TagsPage extends StatelessComponent {
  /// Creates the page.
  const TagsPage({
    required this.addHref,
    required this.hrefOf,
    this.picked,
    this.side,
    super.key,
  });

  /// Where the form of a new метка opens.
  final String addHref;

  /// Where the report of the метка with this id opens.
  final String Function(String id) hrefOf;

  /// The метка whose report or form stands beside the list.
  final String? picked;

  /// What stands beside the list on a wide page.
  final Component? side;

  @override
  Component build(BuildContext context) {
    return BlocBuilder<TagsCubit, TagsState>(
      builder: (context, state) {
        final header = GlassPageHeader(
          title: t.tags.title,
          trailing: GlassIconButton(
            glyph: BirkaGlyph.plus,
            label: t.tags.add,
            href: addHref,
          ),
        );
        final body = switch (state.status) {
          TagsStatus.loading => const <Component>[],
          TagsStatus.failed => [GlassNotice(text: t.tags.failed)],
          TagsStatus.ready when state.isEmpty => [_empty()],
          TagsStatus.ready => _shelves(state),
        };
        final side = this.side;
        if (side == null) return BirkaColumn(children: [header, ...body]);
        return BirkaColumn(
          children: [
            header,
            BirkaSplit(asideWidth: 420, main: body, aside: [side]),
          ],
        );
      },
    );
  }

  List<Component> _shelves(TagsState state) => [
    for (final (shelf, title) in [
      (TagShelf.now, t.tags.now),
      (TagShelf.trips, t.tags.trips),
      (TagShelf.plain, t.tags.plain),
    ])
      if (state.on(shelf) case final summaries when summaries.isNotEmpty)
        section(classes: 'tags__shelf', [
          SectionLabel(title),
          GlassListGroup(
            children: [
              for (final summary in summaries)
                GlassListRow(
                  key: ValueKey(summary.tag.id),
                  leading: GlyphBadge(
                    glyph: summary.tag.isTrip
                        ? BirkaGlyph.plane
                        : BirkaGlyph.tag,
                    color: 'var(--color-accent)',
                  ),
                  title: summary.tag.name,
                  subtitle: wideShelfLine(summary, today: state.today),
                  trailing: AmountText(
                    formatMoney(summary.total),
                    textClass: 'text-body-strong',
                  ),
                  href: hrefOf(summary.tag.id),
                  picked: summary.tag.id == picked,
                ),
            ],
          ),
        ]),
    p(classes: 'text-caption tags__note', [.text(t.tags.note)]),
  ];

  Component _empty() {
    return div(classes: 'tags__empty', [
      const GlyphBadge(
        glyph: BirkaGlyph.tag,
        color: 'var(--color-accent)',
        size: 72,
      ),
      h2(classes: 'text-heading tags__empty-title', [
        .text(t.tags.emptyTitle),
      ]),
      p(classes: 'text-body tags__empty-text', [.text(t.tags.emptyText)]),
      BirkaButton(label: t.tags.add, href: addHref),
    ]);
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.tags__shelf').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.tags__shelf .section-label').styles(
      raw: {'padding': '0 var(--space-xs)'},
    ),
    css('.tags__note').styles(
      raw: {'color': 'var(--color-text-subtle)', 'margin': '0'},
    ),
    // A wide page keeps the welcome as narrow as the column of a phone.
    css('.tags__empty').styles(
      raw: {
        'align-items': 'center',
        'align-self': 'center',
        'box-sizing': 'border-box',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
        'max-width': '480px',
        'padding-top': 'var(--space-xxl)',
        'text-align': 'center',
        'width': '100%',
      },
    ),
    css('.tags__empty-title').styles(raw: {'margin': 'var(--space-xs) 0 0'}),
    css('.tags__empty-text').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'margin': '0 0 var(--space-sm)',
        'max-width': '420px',
      },
    ),
    css('.tags__empty .birka-button').styles(raw: {'align-self': 'stretch'}),
  ];
}
