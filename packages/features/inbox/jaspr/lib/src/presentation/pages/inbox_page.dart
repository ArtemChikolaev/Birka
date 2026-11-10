import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:inbox_jaspr/src/presentation/components/inbox_bits.dart';
import 'package:inbox_jaspr/src/presentation/components/inbox_row.dart';
import 'package:inbox_jaspr/src/presentation/components/pair_card.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// The inbox, as the mockup draws it (ADR 0022): the transfers between one's
/// own accounts to link, and the operations without a category with the
/// hints of past choices, several picked at once; beside them where the
/// hints come from.
///
/// On a narrow screen the side goes under the list. It needs an
/// [InboxCubit] above it.
class InboxPage extends StatefulComponent {
  /// Creates the page.
  const InboxPage({
    required this.backHref,
    this.clock = DateTime.now,
    super.key,
  });

  /// Where the way back leads.
  final String backHref;

  /// What the time is now, which tests can fix.
  final DateTime Function() clock;

  /// How many operations the list shows at first, and more at a time.
  static const page = 30;

  @override
  State<InboxPage> createState() => _InboxPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.inbox').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
    css('.inbox__header').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-md)',
      },
    ),
    css('.inbox__heading').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': '2px',
        'min-width': '0',
      },
    ),
    css('.inbox__title').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.inbox__subtitle').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.inbox__filters').styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': 'var(--space-xs)'},
    ),
    css('.inbox__section').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.inbox__section-head').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'gap': 'var(--space-md)',
        'justify-content': 'space-between',
      },
    ),
    css('.inbox__list').styles(raw: {'padding': '0'}),
    css('.inbox__link').styles(
      raw: {
        'background': 'none',
        'border': '0',
        'color': 'var(--color-text)',
        'cursor': 'pointer',
        'padding': 'var(--space-xs) var(--space-sm)',
      },
    ),
    css('.inbox__more').styles(
      raw: {
        'background': 'none',
        'border': '0',
        'border-top': '1px solid var(--color-hairline)',
        'color': 'var(--color-text-secondary)',
        'cursor': 'pointer',
        'padding': 'var(--space-md)',
        'width': '100%',
      },
    ),
    // The action on the picked stays at the bottom of the screen.
    css('.inbox__picked').styles(
      raw: {
        'align-items': 'center',
        'animation': 'inbox-in var(--duration-base) var(--easing-fade)',
        'bottom': 'max(var(--space-md), env(safe-area-inset-bottom))',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
        'position': 'sticky',
        'z-index': '2',
      },
    ),
    css('.inbox__picked-count').styles(raw: {'color': 'var(--color-text)'}),
    css('.inbox__picked-actions').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.inbox__empty').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.inbox__empty-title').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.inbox__note').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
        'margin': '0',
      },
    ),
    css('.inbox__note-title').styles(raw: {'color': 'var(--color-text-muted)'}),
    css('.inbox__note-text').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.inbox__quiet').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css.keyframes('inbox-in', {
      'from': const Styles(
        raw: {'opacity': '0', 'transform': 'translateY(4px)'},
      ),
    }),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.inbox-pair, .inbox__picked').styles(raw: {'animation': 'none'}),
    ]),
  ];
}

class _InboxPageState extends State<InboxPage> {
  /// How many operations the list shows.
  int _shown = InboxPage.page;

  /// The transfer just made, if any, by its number.
  int? _made;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<InboxCubit>();
    final thisYear = component.clock().year;
    return BlocConsumer<InboxCubit, InboxState>(
      listenWhen: (previous, current) => current.transfers > previous.transfers,
      listener: (context, state) => setState(() => _made = state.transfers),
      builder: (context, state) {
        final made = _made;
        return div(classes: 'inbox', [
          div(classes: 'inbox__header', [
            GlassIconButton(
              glyph: BirkaGlyph.back,
              label: t.inbox.back,
              href: component.backHref,
            ),
            div(classes: 'inbox__heading', [
              h1(classes: 'text-title inbox__title', [.text(t.inbox.title)]),
              // An empty inbox says so in its card, not twice.
              if (!state.loading && state.count > 0)
                p(classes: 'text-caption inbox__subtitle', [
                  .text(waitingLabel(state)),
                ]),
            ]),
          ]),
          div(
            classes: 'inbox__filters',
            attributes: {'role': 'group', 'aria-label': t.inbox.filtersLabel},
            [
              for (final (filter, count) in [
                (InboxFilter.all, state.count),
                (InboxFilter.uncategorized, state.items.length),
                (InboxFilter.transfers, state.pairs.length),
              ])
                BirkaChip(
                  label: t.inbox.filters[filter.name] ?? filter.name,
                  selected: state.filter == filter,
                  count: state.loading ? null : count,
                  onTap: () => cubit.show(filter),
                ),
            ],
          ),
          if (state.failed) GlassNotice(text: t.inbox.failed),
          BirkaSplit(
            main: _main(cubit, state, thisYear),
            aside: [
              div(classes: 'glass inbox__note', [
                span(classes: 'text-label inbox__note-title', [
                  .text(t.inbox.sourceTitle),
                ]),
                p(classes: 'text-body inbox__note-text', [
                  .text(t.inbox.sourceText),
                ]),
                p(classes: 'text-body inbox__note-text', [
                  .text(t.inbox.learns),
                ]),
              ]),
              GlassSurface(
                child: p(classes: 'text-caption inbox__quiet', [
                  .text(t.inbox.stillCounted),
                ]),
              ),
            ],
          ),
          if (made != null)
            GlassToast(
              t.inbox.madeTransfer,
              key: ValueKey(made),
              onGone: () => setState(() => _made = null),
            ),
        ]);
      },
    );
  }

  List<Component> _main(InboxCubit cubit, InboxState state, int thisYear) {
    if (state.loading) return const [BirkaPlaceholder()];
    final pairs = state.shownPairs;
    final items = state.shownItems;
    if (pairs.isEmpty && items.isEmpty) {
      return [
        GlassSurface(
          child: div(classes: 'inbox__empty', [
            h2(classes: 'text-heading inbox__empty-title', [
              .text(t.inbox.emptyTitle),
            ]),
            p(classes: 'text-body inbox__quiet', [.text(t.inbox.emptyText)]),
          ]),
        ),
      ];
    }
    final picked = state.picked;
    final visible = [for (final item in items.take(_shown)) item.id];
    final all = visible.isNotEmpty && visible.every(state.selected.contains);
    return [
      for (final pair in pairs)
        PairCard(
          key: ValueKey(pair.key),
          pair: pair,
          state: state,
          thisYear: thisYear,
        ),
      if (items.isNotEmpty)
        section(classes: 'inbox__section', [
          div(classes: 'inbox__section-head', [
            SectionLabel(
              t.inbox.section(
                title: t.inbox.uncategorized,
                count: formatCount(items.length),
              ),
            ),
            button(
              classes: 'text-body-strong inbox__link',
              type: ButtonType.button,
              onClick: () => cubit.toggleAll(visible),
              [.text(all ? t.inbox.pickNone : t.inbox.pickAll)],
            ),
          ]),
          div(classes: 'glass inbox__list', [
            for (final item in items.take(_shown))
              InboxRow(
                key: ValueKey(item.id),
                item: item,
                state: state,
                thisYear: thisYear,
              ),
            if (items.length > _shown)
              button(
                classes: 'text-body inbox__more',
                type: ButtonType.button,
                onClick: () => setState(() => _shown += InboxPage.page),
                [
                  .text(
                    t.inbox.more(
                      n: items.length - _shown,
                      count: formatCount(items.length - _shown),
                    ),
                  ),
                ],
              ),
          ]),
        ]),
      if (picked.isNotEmpty) _picked(cubit, state, picked),
    ];
  }

  /// The action on the picked operations: one category for them together.
  Component _picked(
    InboxCubit cubit,
    InboxState state,
    List<InboxItem> picked,
  ) {
    final kinds = {for (final item in picked) kindOf(item.transaction)};
    final (:options, :nested) = categoryOptions(
      state,
      [
        for (final kind in CategoryKind.values)
          if (kinds.contains(kind)) kind,
      ],
      first: t.inbox.pickedCategory,
    );
    return div(classes: 'glass inbox__picked', [
      span(classes: 'text-body-strong inbox__picked-count', [
        .text(
          t.inbox.picked(n: picked.length, count: formatCount(picked.length)),
        ),
      ]),
      div(classes: 'inbox__picked-actions', [
        BirkaSelect<String>(
          label: t.inbox.pickedCategory,
          pill: true,
          options: options,
          nested: nested,
          selected: '',
          onChanged: (categoryId) {
            final category = state.categories
                .where((it) => it.id == categoryId)
                .firstOrNull;
            if (category != null) unawaited(cubit.choosePicked(category));
          },
        ),
        button(
          classes: 'text-body-strong inbox__link',
          type: ButtonType.button,
          onClick: cubit.pickNone,
          [.text(t.inbox.pickNone)],
        ),
      ]),
    ]);
  }
}
