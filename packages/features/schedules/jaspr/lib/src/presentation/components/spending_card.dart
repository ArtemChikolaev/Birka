import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_jaspr/src/presentation/components/schedule_bits.dart';

/// The card of the overview with the money of the day and the nearest
/// regular payments (ADR 0023), as on the phone: what today may still take,
/// a bar of what it spent, what becomes of the money at the usual pace, and
/// the next three payments. Without a payday it asks for one. It stays away
/// until there is money to count.
///
/// It needs a [SchedulesCubit] above it.
class SpendingCard extends StatelessComponent {
  /// Creates the card.
  const SpendingCard({
    required this.paydayHref,
    required this.listHref,
    super.key,
  });

  /// Where the money until the salary opens.
  final String paydayHref;

  /// Where the list of payments opens.
  final String listHref;

  @override
  Component build(BuildContext context) {
    return BlocBuilder<SchedulesCubit, SchedulesState>(
      builder: (context, state) {
        final view = switch (state) {
          SchedulesLoaded(:final view) when view.base != null => view,
          _ => null,
        };
        if (view == null) return const div([]);
        final plan = view.plan;
        return GlassSurface(
          child: plan == null ? _noPayday() : _plan(context, view, plan),
        );
      },
    );
  }

  Component _plan(BuildContext context, SchedulesView view, SpendingPlan plan) {
    String mask(String text) => HiddenAmounts.mask(context, text);
    final left = plan.leftToday;
    final perDay = plan.perDay.minorUnits;
    final spent = plan.spentToday.minorUnits;
    final share = perDay > 0
        ? (spent / perDay).clamp(0.0, 1.0)
        : (spent > 0 ? 1.0 : 0.0);
    final percent = (share * 100).round();
    final line = switch (view.forecast) {
      final forecast? => switch (forecastLine(forecast)) {
        final text? => (short: forecast.short, text: text),
        null => null,
      },
      null => null,
    };
    return div(classes: 'spending', [
      a(classes: 'spending__top', href: paydayHref, [
        span(classes: 'spending__head', [
          span(classes: 'text-label', [
            .text(plan.over ? t.schedules.overToday : t.schedules.canSpend),
          ]),
          const BirkaIcon(BirkaGlyph.chevron),
        ]),
        span(classes: 'spending__left', [
          AmountText(
            formatMoney(left),
            tone: plan.over ? AmountTone.negative : AmountTone.neutral,
            textClass: 'text-hero',
          ),
          span(classes: 'text-body spending__of', [
            .text(mask(t.schedules.ofPerDay(amount: formatMoney(plan.perDay)))),
          ]),
        ]),
        span(
          classes: 'spending__bar',
          attributes: {
            'role': 'meter',
            'aria-label': t.schedules.canSpend,
            'aria-valuemin': '0',
            'aria-valuemax': '100',
            'aria-valuenow': '$percent',
          },
          [
            span(
              classes: plan.over
                  ? 'spending__fill spending__fill--over'
                  : 'spending__fill',
              styles: Styles(raw: {'width': '$percent%'}),
              const [],
            ),
          ],
        ),
        span(classes: 'text-caption spending__spent', [
          .text(mask(spentLabel(plan))),
        ]),
        if (line != null)
          span(
            classes: line.short
                ? 'text-caption spending__forecast spending__forecast--short'
                : 'text-caption spending__forecast',
            [
              BirkaIcon(line.short ? BirkaGlyph.alert : BirkaGlyph.check),
              span([.text(line.text)]),
            ],
          ),
      ]),
      const div(classes: 'spending__rule', []),
      SectionLabel(t.schedules.upcoming),
      div(classes: 'spending__rows', [
        for (final it in view.upcoming.take(3))
          div(
            key: ValueKey('${it.schedule.id} ${it.on}'),
            classes: 'spending__row',
            [
              span(classes: 'text-caption spending__date', [
                .text(
                  it.on == view.today ? t.schedules.today : shortDate(it.on),
                ),
              ]),
              ScheduleDot(view, it.schedule),
              span(classes: 'text-body-strong spending__name', [
                .text(occurrenceName(it.schedule, it.on)),
              ]),
              span(classes: amountClasses(it.schedule.kind), [
                .text(mask(occurrenceAmount(it.schedule, it.on))),
              ]),
            ],
          ),
      ]),
      a(classes: 'text-body-strong spending__all', href: listHref, [
        span([
          .text(
            view.schedules.isEmpty
                ? t.schedules.emptyAdd
                : t.schedules.section(
                    title: t.schedules.all,
                    count: formatCount(view.schedules.length),
                  ),
          ),
        ]),
        const BirkaIcon(BirkaGlyph.chevron),
      ]),
    ]);
  }

  Component _noPayday() {
    return div(classes: 'spending', [
      SectionLabel(t.schedules.noPaydayLabel),
      h2(classes: 'text-heading spending__title', [
        .text(t.schedules.noPaydayTitle),
      ]),
      p(classes: 'text-body spending__text', [
        .text(t.schedules.noPaydayText),
      ]),
      BirkaButton(label: t.schedules.noPaydayAction, href: paydayHref),
    ]);
  }

  /// The styles of the card.
  @css
  static List<StyleRule> get styles => [
    css('.spending').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.spending .section-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.spending__top').styles(
      raw: {
        'color': 'var(--color-text)',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'text-decoration': 'none',
      },
    ),
    css('.spending__head').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'justify-content': 'space-between',
      },
    ),
    css('.spending__head .birka-icon, .spending__all .birka-icon').styles(
      raw: {'height': '16px', 'width': '16px'},
    ),
    css('.spending__left').styles(
      raw: {
        'align-items': 'baseline',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.spending__of').styles(raw: {'color': 'var(--color-text-muted)'}),
    css('.spending__bar').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'border-radius': '4px',
        'display': 'block',
        'height': '8px',
        'margin': 'var(--space-xxs) 0',
        'overflow': 'hidden',
      },
    ),
    css('.spending__fill').styles(
      raw: {
        'background': 'var(--color-accent)',
        'border-radius': '4px',
        'display': 'block',
        'height': '100%',
        'transition':
            'width var(--duration-roll) var(--easing-standard), '
            'background var(--duration-slow) var(--easing-fade)',
      },
    ),
    css('.spending__fill--over').styles(
      raw: {'background': 'var(--color-negative)'},
    ),
    css('.spending__spent').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.spending__forecast').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.spending__forecast .birka-icon').styles(
      raw: {
        'color': 'var(--color-positive)',
        'flex': 'none',
        'height': '16px',
        'width': '16px',
      },
    ),
    css(
      '.spending__forecast--short, .spending__forecast--short .birka-icon',
    ).styles(raw: {'color': 'var(--color-palette-amber)'}),
    css('.spending__rule').styles(
      raw: {
        'background': 'var(--color-hairline)',
        'height': '1px',
        'margin': 'var(--space-xs) 0',
      },
    ),
    css('.spending__rows').styles(
      raw: {'display': 'flex', 'flex-direction': 'column'},
    ),
    css('.spending__row').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'min-height': '40px',
      },
    ),
    css('.spending__date').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'flex': 'none',
        'width': '52px',
      },
    ),
    css('.spending__name').styles(
      raw: {
        'flex': '1',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.spending__all').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-accent)',
        'display': 'flex',
        'justify-content': 'space-between',
        'min-height': 'var(--size-touch-target)',
        'text-decoration': 'none',
      },
    ),
    css('.spending__title').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.spending__text').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'margin': '0 0 var(--space-xs)',
      },
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.spending__fill').styles(raw: {'transition': 'none'}),
    ]),
  ];
}
