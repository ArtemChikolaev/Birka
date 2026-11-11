import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:notifications_common/notifications_common.dart';

/// The color of a payment, as on the tile of a reminder.
const _payments = 'var(--color-palette-amber)';

/// The color of an import of a statement.
const _imports = 'var(--color-palette-sky)';

/// The color of what waits for the person.
const _waits = 'var(--color-palette-amber)';

/// Where a notice of [place] leads on the site, with the id of its payment
/// when it has one, or `null` where the site has no page for it.
typedef NoticeHref = String? Function(NoticePlace place, String? id);

/// The feed of notices on the site, as its board draws it (ADR 0026): the new
/// ones on top with a dot, which a click reads and opens where they lead, and
/// «Прочитать все» in the header closes them into the history; the history
/// below by days, each line in the color of what became of its notice. Chips
/// narrow the feed to one source while it has two or more. It needs a
/// [NotificationsCubit] above it.
class NotificationsPage extends StatefulComponent {
  /// Creates the page.
  const NotificationsPage({
    required this.backHref,
    required this.hrefOf,
    required this.onOpen,
    this.wide = false,
    super.key,
  });

  /// Where the way back leads.
  final String backHref;

  /// Whether the page is wide, with what comes here told at the side.
  final bool wide;

  /// Where a notice leads on the site.
  final NoticeHref hrefOf;

  /// Goes to the page of a new notice once it is read, as its link would.
  final void Function(String href) onOpen;

  /// How long the new ones take to close into the history: their dots go
  /// out, their group folds and the days they go to open.
  static const closing = Duration(milliseconds: 600);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.notifications').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
    css('.notifications__header').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-md)',
      },
    ),
    css('.notifications__heading').styles(
      raw: {
        'display': 'flex',
        'flex': '1 1 200px',
        'flex-direction': 'column',
        'gap': '2px',
        'min-width': '0',
      },
    ),
    css('.notifications__title').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.notifications__subtitle').styles(
      raw: {'color': 'var(--color-text-muted)', 'margin': '0'},
    ),
    // It acts where it stands, so it is a pill like the chips, in the accent.
    css('.notifications__read-all').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-surface-raised)',
        'border': '0',
        'border-radius': 'var(--radius-pill)',
        'color': 'var(--color-accent)',
        'cursor': 'pointer',
        'display': 'inline-flex',
        'flex': 'none',
        'height': 'var(--size-touch-target)',
        'padding': '0 var(--space-md)',
        'transition': 'opacity var(--duration-base) var(--easing-fade)',
      },
    ),
    css('.notifications__read-all:disabled').styles(
      raw: {'cursor': 'default', 'opacity': '0'},
    ),
    css('.notifications__filters').styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': 'var(--space-xs)'},
    ),
    css('.notifications__feed').styles(
      raw: {'display': 'flex', 'flex-direction': 'column'},
    ),
    // A group folds to nothing and opens from nothing: the room it takes
    // goes with it, the space under it included. Its label and its glass
    // fade by themselves: glass under a parent that fades stops blurring.
    css('.notifications__fold').styles(
      raw: {
        'display': 'grid',
        'grid-template-rows': '1fr',
        'padding-bottom': 'var(--space-lg)',
        'transition':
            'grid-template-rows var(--duration-slow) var(--easing-standard) '
            'var(--duration-fast), '
            'padding-bottom var(--duration-slow) var(--easing-standard) '
            'var(--duration-fast)',
      },
    ),
    css('.notifications__fold-inner').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'min-height': '0',
      },
    ),
    css('.notifications__fold-inner > *').styles(
      raw: {
        'transition':
            'opacity var(--duration-base) var(--easing-fade) '
            'var(--duration-fast)',
      },
    ),
    css('.notifications__fold--closing').styles(
      raw: {
        'grid-template-rows': '0fr',
        'overflow': 'hidden',
        'padding-bottom': '0',
      },
    ),
    css('.notifications__fold--closing .notifications__fold-inner > *').styles(
      raw: {'opacity': '0'},
    ),
    css('.notifications__fold--opening').styles(
      raw: {
        'animation':
            'notifications-open var(--duration-slow) var(--easing-standard) '
            'var(--duration-base) both',
        'overflow': 'hidden',
      },
    ),
    css('.notifications__fold--opening .notifications__fold-inner > *').styles(
      raw: {
        'animation':
            'notifications-show var(--duration-base) var(--easing-fade) '
            'var(--duration-slow) both',
      },
    ),
    css('.notifications__feed .glass-row--entering').styles(
      raw: {'animation-delay': 'var(--duration-base)'},
    ),
    css.keyframes('notifications-open', {
      'from': const Styles(
        raw: {'grid-template-rows': '0fr', 'padding-bottom': '0'},
      ),
      'to': const Styles(
        raw: {
          'grid-template-rows': '1fr',
          'padding-bottom': 'var(--space-lg)',
        },
      ),
    }),
    css.keyframes('notifications-show', {
      'from': const Styles(raw: {'opacity': '0'}),
      'to': const Styles(raw: {'opacity': '1'}),
    }),
    css('.notifications__label').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'padding': '0 var(--space-xxs)',
      },
    ),
    css('.notifications__lead').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex': 'none',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.notifications__dot').styles(
      raw: {
        'background': 'var(--color-accent)',
        'border-radius': '50%',
        'box-shadow':
            '0 0 var(--space-xs) '
            'color-mix(in srgb, var(--color-accent) 70%, transparent)',
        'flex': 'none',
        'height': 'var(--space-xs)',
        'transition': 'opacity var(--duration-base) var(--easing-fade)',
        'width': 'var(--space-xs)',
      },
    ),
    css('.notifications__fold--closing .notifications__dot').styles(
      raw: {'opacity': '0'},
    ),
    css('.notifications__moment').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'flex': 'none',
        'font-variant-numeric': 'tabular-nums',
        'font-weight': 'var(--font-weight-semibold)',
        'white-space': 'nowrap',
      },
    ),
    css('.notifications__moment--new').styles(
      raw: {'color': 'var(--color-accent)'},
    ),
    css('.notifications__trail').styles(
      raw: {
        'align-items': 'flex-end',
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'flex': 'none',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
      },
    ),
    css('.notifications__trail .birka-icon').styles(
      raw: {'height': '16px', 'width': '16px'},
    ),
    css('.notifications__keeps').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'margin': '0',
        'text-align': 'center',
      },
    ),
    css('.notifications__empty').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'padding-top': 'calc(3 * var(--space-xxl))',
        'text-align': 'center',
      },
    ),
    css('.notifications__empty .glyph-badge').styles(
      raw: {'margin-bottom': 'var(--space-xs)'},
    ),
    css('.notifications__empty-title').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.notifications__empty-text').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'margin': '0',
        'max-width': '290px',
      },
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css(
        '.notifications__fold, .notifications__fold-inner > *, '
        '.notifications__dot, .notifications__read-all',
      ).styles(raw: {'transition': 'none'}),
      css(
        '.notifications__fold--opening, '
        '.notifications__fold--opening .notifications__fold-inner > *',
      ).styles(raw: {'animation': 'none'}),
    ]),
  ];
}

class _NotificationsPageState extends State<NotificationsPage> {
  /// The new notices as they stood while their group folds into the
  /// history, or none.
  List<Notice> _folding = const [];

  /// The days of the history before read notices went into it, while the
  /// days they go to open, or `null`.
  Set<CivilDate>? _daysBefore;

  /// The notices in the history before more went into it, while those open
  /// in the days that were there, or `null`.
  Set<String>? _readBefore;

  Timer? _settle;

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  /// Moves what is new on [state] into the history: every new notice when
  /// [all], with their group folding, and otherwise one, while the days that
  /// they go to open.
  void _toHistory(NotificationsState state, {required bool all}) {
    _settle?.cancel();
    setState(() {
      if (all) _folding = state.fresh;
      _daysBefore = {for (final day in state.days) day.day};
      _readBefore = {
        for (final day in state.days)
          for (final notice in day.notices) notice.id,
      };
    });
    _settle = Timer(NotificationsPage.closing, () {
      if (!mounted) return;
      setState(() {
        _folding = const [];
        _daysBefore = null;
        _readBefore = null;
      });
    });
  }

  void _readAll(NotificationsCubit cubit) {
    _toHistory(cubit.state, all: true);
    unawaited(cubit.readAll());
  }

  Future<void> _open(NotificationsCubit cubit, Notice notice) async {
    final state = cubit.state;
    final href = _hrefOf(state, notice);
    // One that leads nowhere goes into the history before the eyes, and the
    // last one takes its group with it.
    if (href == null && notice.isNew) {
      _toHistory(state, all: state.fresh.length == 1);
    }
    await cubit.open(notice);
    if (href != null) component.onOpen(href);
  }

  /// Whether [day] has just come into the history, which it opens into.
  bool _opens(CivilDate day) => _daysBefore?.contains(day) == false;

  String? _hrefOf(NotificationsState state, Notice notice) {
    final place = state.placeOf(notice);
    return place == null ? null : component.hrefOf(place.place, place.id);
  }

  @override
  Component build(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final body = switch (state.status) {
          NotificationsStatus.loading => const [BirkaPlaceholder()],
          NotificationsStatus.failed => [
            GlassNotice(text: t.notifications.failed),
          ],
          _ when state.notices.isEmpty => [_empty()],
          _ => _feed(cubit, state),
        };
        return div(classes: 'notifications', [
          _header(cubit, state),
          if (component.wide)
            BirkaSplit(
              asideWidth: 340,
              main: body,
              aside: [
                GlassSteps(
                  title: t.notifications.howTitle,
                  points: t.notifications.how,
                ),
              ],
            )
          else
            ...body,
        ]);
      },
    );
  }

  Component _header(NotificationsCubit cubit, NotificationsState state) {
    final count = state.newOf(null);
    final folding = _folding.isNotEmpty;
    final told =
        state.status == NotificationsStatus.ready && state.notices.isNotEmpty;
    return div(classes: 'notifications__header', [
      GlassIconButton(
        glyph: BirkaGlyph.back,
        label: t.notifications.back,
        href: component.backHref,
      ),
      div(classes: 'notifications__heading', [
        h1(classes: 'text-title notifications__title', [
          .text(t.notifications.title),
        ]),
        if (told)
          p(classes: 'text-caption notifications__subtitle', [
            .text(
              count > 0
                  ? t.notifications.subtitleNew(
                      n: count,
                      count: formatCount(count),
                    )
                  : t.notifications.subtitleRead,
            ),
          ]),
      ]),
      // It fades out with the dots, then leaves.
      if (count > 0 || folding)
        button(
          classes: 'text-body-strong notifications__read-all',
          type: ButtonType.button,
          disabled: count == 0 || folding,
          onClick: () => _readAll(cubit),
          [.text(t.notifications.readAll)],
        ),
    ]);
  }

  List<Component> _feed(NotificationsCubit cubit, NotificationsState state) {
    final folding = _folding.isNotEmpty;
    final fresh = folding ? _folding : state.fresh;
    return [
      if (state.sources.isNotEmpty)
        div(
          classes: 'notifications__filters',
          attributes: {
            'role': 'group',
            'aria-label': t.notifications.filtersLabel,
          },
          [
            for (final source in <NoticeSource?>[null, ...state.sources])
              BirkaChip(
                label: t.notifications.filters[source?.name ?? 'all'] ?? '',
                selected: state.source == source,
                // A source with nothing new shows no count.
                count: switch (state.newOf(source)) {
                  0 => null,
                  final count => count,
                },
                onTap: () => cubit.pick(source),
              ),
          ],
        ),
      div(classes: 'notifications__feed', [
        if (fresh.isNotEmpty)
          _fold(
            key: const ValueKey('fresh'),
            label: t.notifications.fresh(count: formatCount(fresh.length)),
            classes: folding ? ' notifications__fold--closing' : '',
            rows: [
              for (final notice in fresh) _freshRow(cubit, state, notice),
            ],
          ),
        for (final day in state.days)
          _fold(
            key: ValueKey(day.day),
            label: noticeDayHeading(day.day, today: state.today),
            classes: _opens(day.day) ? ' notifications__fold--opening' : '',
            rows: [
              for (final notice in day.notices)
                _row(
                  state,
                  notice,
                  // A new day opens with its rows, and a day that was there
                  // takes the new ones in one by one.
                  entering:
                      !_opens(day.day) &&
                      _readBefore?.contains(notice.id) == false,
                ),
            ],
          ),
        p(classes: 'text-caption notifications__keeps', [
          .text(t.notifications.keeps),
        ]),
      ]),
    ];
  }

  /// A group of notices under its label: the new ones or one day.
  Component _fold({
    required Key key,
    required String label,
    required String classes,
    required List<Component> rows,
  }) {
    return section(key: key, classes: 'notifications__fold$classes', [
      div(classes: 'notifications__fold-inner', [
        div(classes: 'notifications__label', [SectionLabel(label)]),
        GlassListGroup(children: rows),
      ]),
    ]);
  }

  /// A new notice: a dot, the tile of its source, what it is about and when
  /// its time comes, and when it came over a chevron if it leads somewhere.
  Component _freshRow(
    NotificationsCubit cubit,
    NotificationsState state,
    Notice notice,
  ) {
    final today = state.today;
    final (line, _) = noticeLine(notice, today: today, fresh: true);
    final moment = span(
      classes: 'text-caption notifications__moment notifications__moment--new',
      [.text(noticeMoment(notice, today: today))],
    );
    return GlassListRow(
      key: ValueKey(notice.id),
      title: noticeTitle(notice, thisYear: today.year),
      subtitle: line,
      subtitleColor: 'var(--color-text-secondary)',
      leading: span(classes: 'notifications__lead', [
        const span(
          classes: 'notifications__dot',
          attributes: {'aria-hidden': 'true'},
          [],
        ),
        _tile(notice),
      ]),
      trailing: _hrefOf(state, notice) == null
          ? moment
          : span(classes: 'notifications__trail', [
              moment,
              const BirkaIcon(BirkaGlyph.chevron),
            ]),
      onTap: () => unawaited(_open(cubit, notice)),
    );
  }

  /// A read notice: the tile of its source, what it is about and, under it,
  /// what became of it in the color of the news, and the time it came. One
  /// that is [entering] has just been read.
  Component _row(
    NotificationsState state,
    Notice notice, {
    bool entering = false,
  }) {
    final today = state.today;
    final (line, tone) = noticeLine(notice, today: today);
    return GlassListRow(
      key: ValueKey(notice.id),
      title: noticeTitle(notice, thisYear: today.year),
      subtitle: line,
      subtitleLines: 2,
      subtitleColor: switch (tone) {
        NoticeTone.done => 'var(--color-positive)',
        NoticeTone.waits => _waits,
        NoticeTone.left => 'var(--color-text-subtle)',
        NoticeTone.plain => null,
      },
      leading: _tile(notice),
      trailing: span(classes: 'text-caption notifications__moment', [
        .text(clockOf(notice.at)),
      ]),
      href: _hrefOf(state, notice),
      entering: entering,
    );
  }

  static Component _tile(Notice notice) => switch (notice.source) {
    NoticeSource.payment => const GlyphBadge(
      glyph: BirkaGlyph.calendar,
      color: _payments,
    ),
    NoticeSource.import => const GlyphBadge(
      glyph: BirkaGlyph.download,
      color: _imports,
    ),
  };

  /// What the feed says while nothing has come.
  Component _empty() {
    return div(classes: 'notifications__empty', [
      const GlyphBadge(
        glyph: BirkaGlyph.bell,
        color: 'var(--color-accent)',
        size: 56,
      ),
      h2(classes: 'text-heading notifications__empty-title', [
        .text(t.notifications.emptyTitle),
      ]),
      p(classes: 'text-body notifications__empty-text', [
        .text(t.notifications.emptyImports),
      ]),
    ]);
  }
}
