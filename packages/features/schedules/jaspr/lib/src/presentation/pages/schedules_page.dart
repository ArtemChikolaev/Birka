import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_jaspr/src/presentation/components/schedule_bits.dart';

/// The color of a payment that waits for the person.
const _waits = 'var(--color-palette-amber)';

/// What a toast of the page says, and what it offers to do.
typedef _Toast = ({String text, ToastAction? action});

/// The list of regular payments on the site (ADR 0023), as the boards
/// «Регулярные платежи на сайте» draw it: the ones that wait for the person,
/// the operations that look like payments, the next 30 days and every
/// payment. On a wide screen a side says what the days may spend and how a
/// payment works; on a narrow one the page is the list alone.
///
/// It needs a [SchedulesCubit] above it.
class SchedulesPage extends StatefulComponent {
  /// Creates the page.
  const SchedulesPage({
    required this.backHref,
    required this.addHref,
    required this.paydayHref,
    required this.hrefOf,
    required this.findHref,
    super.key,
  });

  /// Where the way back leads.
  final String backHref;

  /// Where the form of a new payment opens.
  final String addHref;

  /// Where the money until the salary opens.
  final String paydayHref;

  /// Where the form of a payment opens, by its id.
  final String Function(String id) hrefOf;

  /// Where the form of a new payment made from an operation opens, by its id:
  /// the latest of an operation that came every month.
  final String Function(String operationId) findHref;

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.schedules').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
    // A narrow page adds with a round button, a wide one with a word.
    css('.schedules__add').styles(raw: {'display': 'flex', 'flex': 'none'}),
    css('.schedules__add--wide').styles(raw: {'display': 'none'}),
    css.media(const MediaQuery.raw('(min-width: 901px)'), [
      css('.schedules__add--narrow').styles(raw: {'display': 'none'}),
      css('.schedules__add--wide').styles(raw: {'display': 'flex'}),
    ]),
    css('.schedules__section').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.schedules__section .section-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.schedules__head').styles(
      raw: {
        'align-items': 'baseline',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
      },
    ),
    css('.schedules__total').styles(
      raw: {'color': 'var(--color-text-subtle)', 'white-space': 'nowrap'},
    ),
    css('.schedules__note').styles(
      raw: {'color': 'var(--color-text-muted)', 'margin': '0'},
    ),
    css('.schedules__lead').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex': 'none',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.schedules__trail').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex': 'none',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.schedules__trail .birka-icon').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'height': '16px',
        'width': '16px',
      },
    ),
    css('.schedules-waiting').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.schedules-waiting__label').styles(raw: {'color': _waits}),
    css('.schedules-waiting__row').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.schedules-waiting__words').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'min-width': '0',
      },
    ),
    css('.schedules-waiting__where').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.schedules-waiting__actions').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'repeat(2, minmax(0, 1fr))',
        'margin-top': 'var(--space-xxs)',
      },
    ),
    css('.schedules-waiting__note').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.schedules__empty').styles(
      raw: {
        'align-items': 'center',
        'align-self': 'center',
        'box-sizing': 'border-box',
        'display': 'flex',
        'max-width': '480px',
        'width': '100%',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'padding-top': 'var(--space-xxl)',
        'text-align': 'center',
      },
    ),
    css('.schedules__empty-title').styles(
      raw: {
        'color': 'var(--color-text)',
        'margin': 'var(--space-xs) 0 0',
      },
    ),
    css('.schedules__empty-text').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'margin': '0 0 var(--space-md)',
        'max-width': '380px',
      },
    ),
    css('.schedules__empty .birka-button').styles(raw: {'width': '100%'}),
    css('.glass.schedules-day').styles(
      raw: {
        'color': 'var(--color-text)',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'text-decoration': 'none',
        'transition': 'border-color var(--duration-fast)',
      },
    ),
    css('.glass.schedules-day:hover').styles(
      raw: {'border-color': 'var(--color-text-subtle)'},
    ),
    css('.schedules-day__head').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'justify-content': 'space-between',
      },
    ),
    css('.schedules-day__head .birka-icon').styles(
      raw: {'height': '16px', 'width': '16px'},
    ),
    css('.schedules-day__amount').styles(
      raw: {'font-variant-numeric': 'tabular-nums', 'margin-top': '4px'},
    ),
    css('.schedules-day__period').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.schedules-day__paid').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'margin-top': 'var(--space-xs)',
      },
    ),
  ];
}

class _SchedulesPageState extends State<SchedulesPage> {
  _Toast? _toast;
  var _toasts = 0;

  /// The payments that wait while their post or skip is on its way.
  final _busy = <String>{};

  void _say(String text, {ToastAction? action}) => setState(() {
    _toast = (text: text, action: action);
    _toasts++;
  });

  Future<void> _act(
    SchedulesCubit cubit,
    SchedulesView view,
    Schedule schedule, {
    required bool post,
  }) async {
    if (!_busy.add(schedule.id)) return;
    // The card closes once the payment moves on, so the toast comes first.
    _say(
      post
          ? postedLabel(schedule, schedule.amountOn(schedule.next))
          : skippedLabel(schedule, view.today),
    );
    try {
      await (post ? cubit.post(schedule) : cubit.skip(schedule));
    } finally {
      _busy.remove(schedule.id);
    }
  }

  void _dismiss(SchedulesCubit cubit, RepeatFind find) {
    _say(
      t.schedules.findDismissed(name: find.name),
      action: (
        label: t.schedules.findRestore,
        onPressed: () => unawaited(cubit.restore(find.key)),
      ),
    );
    unawaited(cubit.dismiss(find));
  }

  @override
  Component build(BuildContext context) {
    final cubit = context.read<SchedulesCubit>();
    return BlocBuilder<SchedulesCubit, SchedulesState>(
      builder: (context, state) {
        final toast = _toast;
        return div(classes: 'schedules', [
          _header(state),
          switch (state) {
            SchedulesLoading() => const BirkaPlaceholder(),
            SchedulesFailed() => GlassNotice(
              text: t.schedules.failed,
              actions: [
                BirkaButton(
                  label: t.app.retry,
                  onPressed: () => unawaited(cubit.retry()),
                ),
              ],
            ),
            SchedulesLoaded(:final view) => BirkaSplit(
              asideWhenNarrow: false,
              main: _main(context, cubit, view),
              aside: _aside(context, view),
            ),
          },
          if (toast != null)
            GlassToast(
              toast.text,
              key: ValueKey(_toasts),
              action: toast.action,
              onGone: () => setState(() => _toast = null),
            ),
        ]);
      },
    );
  }

  Component _header(SchedulesState state) {
    return GlassPageHeader(
      leading: GlassIconButton(
        glyph: BirkaGlyph.back,
        label: t.schedules.back,
        href: component.backHref,
      ),
      title: t.schedules.title,
      subtitle: switch (state) {
        SchedulesLoaded(:final view) => _subtitle(view),
        _ => null,
      },
      trailing: div(classes: 'schedules__add', [
        div(classes: 'schedules__add--narrow', [
          GlassIconButton(
            glyph: BirkaGlyph.plus,
            label: t.schedules.add,
            href: component.addHref,
          ),
        ]),
        div(classes: 'schedules__add--wide', [
          BirkaButton(
            label: t.schedules.add,
            href: component.addHref,
            compact: true,
          ),
        ]),
      ]),
    );
  }

  /// `Ближайший 25 ноября · 6 платежей`, or what waits today.
  static String _subtitle(SchedulesView view) {
    if (view.schedules.isEmpty) return t.schedules.subtitleNone;
    final today = view.today;
    if (view.waiting.isNotEmpty) {
      return t.schedules.subtitleToday(
        n: view.waiting.length,
        date: fullDate(today, today),
      );
    }
    final next = [
      for (final schedule in view.schedules) schedule.next,
    ].reduce((one, other) => one.compareTo(other) <= 0 ? one : other);
    return t.schedules.subtitleNext(
      date: fullDate(next, today),
      count: t.schedules.paymentsCount(n: view.schedules.length),
    );
  }

  List<Component> _main(
    BuildContext context,
    SchedulesCubit cubit,
    SchedulesView view,
  ) {
    if (view.schedules.isEmpty) {
      // Before the first payment, what came every month stands over the
      // empty page.
      return [
        if (view.finds.isNotEmpty) _finds(context, cubit, view, empty: true),
        _empty(),
      ];
    }
    final plan = view.plan;
    return [
      for (final it in view.found)
        TintedNotice(
          key: ValueKey('found ${it.schedule.id}'),
          color: 'var(--color-positive)',
          glyph: BirkaGlyph.check,
          title: foundTitle(it.schedule, it.import),
          text: HiddenAmounts.mask(
            context,
            foundText(it.schedule, view.today),
          ),
        ),
      for (final schedule in view.waiting)
        _waiting(context, cubit, view, schedule),
      if (view.finds.isNotEmpty) _finds(context, cubit, view),
      // The next 30 days go while no time comes in them and no salary is
      // counted, as when the only payment waits today.
      if (view.ahead.isNotEmpty || plan != null) _ahead(context, view, plan),
      _all(context, view),
    ];
  }

  Component _waiting(
    BuildContext context,
    SchedulesCubit cubit,
    SchedulesView view,
    Schedule schedule,
  ) {
    final busy = _busy.contains(schedule.id);
    return TintedBox(
      key: ValueKey(schedule.id),
      color: _waits,
      children: [
        section(
          classes: 'schedules-waiting',
          attributes: {'aria-label': t.schedules.waitingTitle},
          [
            span(classes: 'text-label schedules-waiting__label', [
              .text(t.schedules.waitingTitle),
            ]),
            div(classes: 'schedules-waiting__row', [
              const GlyphBadge(glyph: BirkaGlyph.calendar, color: _waits),
              div(classes: 'schedules-waiting__words', [
                span(classes: 'text-body-strong', [
                  .text(
                    t.schedules.waitingDay(
                      name: occurrenceName(schedule, schedule.next),
                      day: dayLabel(schedule.next, view.today),
                    ),
                  ),
                ]),
                span(classes: 'text-caption schedules-waiting__where', [
                  .text(scheduleWhere(view, schedule)),
                ]),
              ]),
              span(classes: amountClasses(schedule.kind), [
                .text(
                  HiddenAmounts.mask(
                    context,
                    occurrenceAmount(schedule, schedule.next),
                  ),
                ),
              ]),
            ]),
            div(classes: 'schedules-waiting__actions', [
              BirkaButton(
                label: t.schedules.post,
                onPressed: busy
                    ? null
                    : () => unawaited(_act(cubit, view, schedule, post: true)),
              ),
              BirkaButton(
                label: t.schedules.skip,
                quiet: true,
                onPressed: busy
                    ? null
                    : () => unawaited(_act(cubit, view, schedule, post: false)),
              ),
            ]),
            span(classes: 'text-caption schedules-waiting__note', [
              .text(t.schedules.waitingNote),
            ]),
          ],
        ),
      ],
    );
  }

  /// The operations that came every month and have no payment yet: a click
  /// makes one of the latest, ✕ keeps a find away, and «Вернуть» on the
  /// toast brings it back (ADR 0023, point 23).
  Component _finds(
    BuildContext context,
    SchedulesCubit cubit,
    SchedulesView view, {
    bool empty = false,
  }) {
    final finds = view.finds;
    return section(
      classes: 'schedules__section',
      key: const ValueKey('finds'),
      [
        SectionLabel(
          t.schedules.section(
            title: empty ? t.schedules.findsTitleEmpty : t.schedules.findsTitle,
            count: formatCount(finds.length),
          ),
        ),
        GlassListGroup(
          children: [
            for (final find in finds)
              GlassListRow(
                key: ValueKey(find.key),
                leading: const GlyphBadge(
                  glyph: BirkaGlyph.repeat,
                  color: 'var(--color-accent)',
                ),
                title: find.name,
                subtitle: findLine(find),
                trailing: span(classes: amountClasses(find.kind), [
                  .text(HiddenAmounts.mask(context, findAmount(find))),
                ]),
                href: component.findHref(find.latest.id),
                action: GlassIconButton(
                  glyph: BirkaGlyph.close,
                  label: t.schedules.findDismiss(name: find.name),
                  glass: false,
                  onPressed: () => _dismiss(cubit, find),
                ),
              ),
          ],
        ),
        p(classes: 'text-caption schedules__note', [
          .text(t.schedules.findsNote),
        ]),
      ],
    );
  }

  Component _ahead(
    BuildContext context,
    SchedulesView view,
    SpendingPlan? plan,
  ) {
    String mask(String text) => HiddenAmounts.mask(context, text);
    return section(
      classes: 'schedules__section',
      key: const ValueKey('ahead'),
      [
        div(classes: 'schedules__head', [
          SectionLabel(t.schedules.ahead),
          if (plan != null)
            span(classes: 'text-caption schedules__total', [
              .text(
                mask(
                  t.schedules.aheadTotal(
                    date: fullDate(plan.payday ?? plan.end, view.today),
                    amount: formatMoney(-plan.paid),
                  ),
                ),
              ),
            ]),
        ]),
        if (view.ahead.isNotEmpty)
          GlassListGroup(
            children: [
              for (final it in view.ahead)
                GlassListRow(
                  key: ValueKey('${it.schedule.id} ${it.on}'),
                  leading: span(classes: 'schedules__lead', [
                    DateColumn(it.on),
                    ScheduleDot(view, it.schedule),
                  ]),
                  title: occurrenceName(it.schedule, it.on),
                  subtitle: scheduleWhere(view, it.schedule),
                  trailing: span(classes: amountClasses(it.schedule.kind), [
                    .text(mask(occurrenceAmount(it.schedule, it.on))),
                  ]),
                  href: component.hrefOf(it.schedule.id),
                ),
            ],
          ),
        if (plan != null)
          p(classes: 'text-caption schedules__note', [
            .text(mask(leftAfterLabel(plan, view.today))),
          ]),
      ],
    );
  }

  Component _all(BuildContext context, SchedulesView view) {
    return section(classes: 'schedules__section', key: const ValueKey('all'), [
      SectionLabel(
        t.schedules.section(
          title: t.schedules.all,
          count: formatCount(view.schedules.length),
        ),
      ),
      GlassListGroup(
        children: [
          for (final schedule in view.all)
            GlassListRow(
              key: ValueKey(schedule.id),
              leading: ScheduleDot(view, schedule),
              title: schedule.name,
              subtitle:
                  doneLine(schedule, view.today) ??
                  scheduleLine(schedule, view.today),
              // The next time of a payment that went through today must not
              // be cut off by its amount.
              subtitleLines: 2,
              subtitleColor: _doneColor(view, schedule),
              trailing: span(classes: 'schedules__trail', [
                span(classes: amountClasses(schedule.kind), [
                  .text(HiddenAmounts.mask(context, scheduleTotal(schedule))),
                ]),
                const BirkaIcon(BirkaGlyph.chevron),
              ]),
              href: component.hrefOf(schedule.id),
            ),
        ],
      ),
    ]);
  }

  Component _empty() {
    return div(classes: 'schedules__empty', [
      const GlyphBadge(glyph: BirkaGlyph.repeat, color: 'var(--color-accent)'),
      h2(classes: 'text-heading schedules__empty-title', [
        .text(t.schedules.emptyTitle),
      ]),
      p(classes: 'text-body schedules__empty-text', [
        .text(t.schedules.emptyText),
      ]),
      BirkaButton(label: t.schedules.emptyAdd, href: component.addHref),
    ]);
  }

  /// What the days may spend and how a payment works, beside the list on a
  /// wide screen.
  List<Component> _aside(BuildContext context, SchedulesView view) {
    final plan = view.plan;
    String mask(String text) => HiddenAmounts.mask(context, text);
    return [
      if (plan != null && view.schedules.isNotEmpty)
        a(classes: 'glass schedules-day', href: component.paydayHref, [
          span(classes: 'schedules-day__head', [
            span(classes: 'text-label', [.text(t.schedules.perDayTitle)]),
            const BirkaIcon(BirkaGlyph.chevron),
          ]),
          span(classes: 'text-title schedules-day__amount', [
            .text(mask(formatMoney(plan.perDay))),
          ]),
          span(classes: 'text-caption schedules-day__period', [
            .text(planPeriodLabel(plan)),
          ]),
          if (plan.paid.isPositive)
            span(classes: 'text-caption schedules-day__paid', [
              .text(
                mask(
                  plan.until == SpendUntil.payday && plan.payday != null
                      ? t.schedules.paidAheadPayday(
                          amount: formatMoney(-plan.paid),
                        )
                      : t.schedules.paidAheadMonth(
                          amount: formatMoney(-plan.paid),
                        ),
                ),
              ),
            ]),
        ]),
      GlassSteps(title: t.schedules.howTitle, points: t.schedules.how),
    ];
  }
}

/// The color of the line of [schedule] on the day it went through: posted
/// or brought by a statement, but not skipped.
String? _doneColor(SchedulesView view, Schedule schedule) =>
    view.doneToday(schedule) && schedule.last?.done != ScheduleDone.skipped
    ? 'var(--color-positive)'
    : null;
