import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:schedules_common/schedules_common.dart';

/// The money until the salary on the site (ADR 0023), as the boards «Деньги
/// до зарплаты на сайте» draw it: how much each day may take, with the sum
/// that gives it in the open, and what becomes of it at the usual pace; on a
/// wide screen beside them, and under them on a narrow one, until when it
/// counts, on which accounts and with how much aside.
///
/// It needs a [SchedulesCubit] above it.
class PaydayPage extends StatefulComponent {
  /// Creates the page.
  const PaydayPage({
    required this.backHref,
    required this.salaryHref,
    required this.addSalaryHref,
    super.key,
  });

  /// Where the way back leads.
  final String backHref;

  /// Where the form of the income that sets the payday opens, by its id.
  final String Function(String id) salaryHref;

  /// Where the form of a new salary opens.
  final String addSalaryHref;

  @override
  State<PaydayPage> createState() => _PaydayPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.payday').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
    css('.payday__sum').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.payday__period').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'margin-bottom': 'var(--space-xs)',
      },
    ),
    css('.payday__line').styles(
      raw: {
        'align-items': 'baseline',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
      },
    ),
    css('.payday__line-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.payday__line--strong .payday__line-label').styles(
      raw: {'color': 'var(--color-text)'},
    ),
    css('.payday__rule').styles(
      raw: {
        'background': 'var(--color-hairline)',
        'height': '1px',
        'margin': 'var(--space-xxs) 0',
      },
    ),
    css('.payday__near').styles(raw: {'color': 'var(--color-text-muted)'}),
    css('.payday__forecast').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.payday__forecast .section-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.payday__verdict').styles(
      raw: {'margin': '0', 'transition': 'color var(--duration-base)'},
    ),
    css('.payday__verdict--good').styles(
      raw: {'color': 'var(--color-positive)'},
    ),
    css('.payday__verdict--bad').styles(
      raw: {'color': 'var(--color-negative)'},
    ),
    css('.payday__words').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.payday__note').styles(
      raw: {'color': 'var(--color-text-subtle)', 'margin': '0'},
    ),
    css('.payday__group').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.payday__group .section-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.payday__until').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.payday__locked').styles(
      raw: {'opacity': '0.4', 'pointer-events': 'none'},
    ),
    css('.payday__add').styles(
      raw: {
        'color': 'var(--color-accent)',
        'display': 'flex',
        'height': '16px',
        'width': '16px',
      },
    ),
  ];
}

class _PaydayPageState extends State<PaydayPage> {
  /// What is typed as the money aside, which the cubit gets once it reads.
  String? _aside;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<SchedulesCubit>();
    return BlocBuilder<SchedulesCubit, SchedulesState>(
      builder: (context, state) => div(classes: 'payday', [
        GlassPageHeader(
          leading: GlassIconButton(
            glyph: BirkaGlyph.back,
            label: t.schedules.back,
            href: component.backHref,
          ),
          title: t.schedules.paydayTitle,
        ),
        switch (state) {
          SchedulesLoaded(:final view) when view.base != null => BirkaSplit(
            asideWidth: 340,
            main: [
              switch (view.plan) {
                final plan? => _Sum(plan: plan),
                null => TintedNotice(
                  color: 'var(--color-accent)',
                  title: t.schedules.noPaydayTitle,
                  text: t.schedules.noPaydayText,
                ),
              },
              if (view.forecast case final forecast?)
                _Forecast(forecast: forecast),
            ],
            aside: [
              _until(cubit, view),
              _accounts(context, cubit, view),
              _keptAside(cubit, view),
            ],
          ),
          // With no account yet there is no money to count.
          SchedulesLoaded() => TintedNotice(
            color: 'var(--color-accent)',
            title: t.schedules.noPaydayTitle,
            text: t.schedules.noPaydayText,
          ),
          SchedulesFailed() => GlassNotice(
            text: t.schedules.failed,
            actions: [
              BirkaButton(
                label: t.app.retry,
                onPressed: () => unawaited(cubit.retry()),
              ),
            ],
          ),
          _ => const BirkaPlaceholder(),
        },
      ]),
    );
  }

  /// Until when the money counts, and the day of the salary while it counts
  /// until that.
  Component _until(SchedulesCubit cubit, SchedulesView view) {
    final salary = view.salary;
    return GlassSurface(
      child: div(classes: 'payday__until', [
        BirkaChoice(
          label: t.schedules.countUntil,
          children: [
            for (final until in SpendUntil.values)
              BirkaChip(
                label: t.schedules.until[until.name] ?? until.name,
                selected: view.settings.until == until,
                onTap: () => unawaited(cubit.countUntil(until)),
              ),
          ],
        ),
        // The payday matters only while the money counts until it.
        BirkaFold(
          open: view.settings.until == SpendUntil.payday,
          gap: 'var(--space-sm)',
          children: [
            GlassListGroup(
              children: [
                GlassListRow(
                  title: salary?.advanceDay == null
                      ? t.schedules.payday
                      : t.schedules.paydayTwice,
                  subtitle: salary == null
                      ? t.schedules.paydayNone
                      : t.schedules.paydayFrom(name: salary.name),
                  trailing: salary == null
                      ? const span(classes: 'payday__add', [
                          BirkaIcon(BirkaGlyph.plus),
                        ])
                      : span(classes: 'text-body-strong', [
                          .text(switch (salary.advanceDay) {
                            final advance? => t.schedules.paydayTwiceDays(
                              advance: advance,
                              day: salary.day,
                            ),
                            null => t.schedules.paydayDay(day: salary.day),
                          }),
                        ]),
                  href: salary == null
                      ? component.addSalaryHref
                      : component.salaryHref(salary.id),
                ),
              ],
            ),
          ],
        ),
      ]),
    );
  }

  Component _accounts(
    BuildContext context,
    SchedulesCubit cubit,
    SchedulesView view,
  ) {
    return section(classes: 'payday__group', [
      SectionLabel(t.schedules.accountsTitle),
      GlassListGroup(
        children: [
          for (final it in view.countable)
            GlassListRow(
              key: ValueKey(it.row.account.id),
              title: it.row.account.name,
              subtitle: it.locked
                  ? t.schedules.otherCurrency
                  : HiddenAmounts.mask(
                      context,
                      [
                        if (it.row.account.lastDigits case final digits?)
                          '••$digits',
                        formatMoney(it.row.balance),
                      ].join(' · '),
                    ),
              trailing: span(classes: it.locked ? 'payday__locked' : null, [
                BirkaSwitch(
                  value: it.counted,
                  label: t.schedules.count(name: it.row.account.name),
                  onChanged: (counted) {
                    if (it.locked) return;
                    unawaited(
                      cubit.count(it.row.account.id, counted: counted),
                    );
                  },
                ),
              ]),
            ),
        ],
      ),
    ]);
  }

  /// What stays aside until the salary, typed in place.
  Component _keptAside(SchedulesCubit cubit, SchedulesView view) {
    final base = view.base!;
    final aside = Money(view.settings.asideMinor, base);
    return GlassSurface(
      child: div(classes: 'payday__group', [
        BirkaTextField(
          label: t.schedules.asideRow,
          value: _aside ?? (aside.isZero ? '' : typedAmount(aside)),
          hint: '0',
          inputMode: 'decimal',
          suffix: currencySign(base),
          onChanged: (typed) {
            setState(() => _aside = typed);
            final money = amountTyped(typed, base);
            if (money != null) unawaited(cubit.keepAside(money));
          },
        ),
        p(classes: 'text-caption payday__note', [.text(t.schedules.asideNote)]),
      ]),
    );
  }
}

/// How much each day may take, and the sum that gives it.
class _Sum extends StatelessComponent {
  const _Sum({required this.plan});

  final SpendingPlan plan;

  @override
  Component build(BuildContext context) {
    final short = plan.short;
    final payday = plan.until == SpendUntil.payday;
    final count = plan.payments.length;
    final advance = plan.advances.firstOrNull?.on;
    final near = plan.near;
    return TintedBox(
      color: 'var(--color-accent)',
      children: [
        div(
          classes: 'payday__sum',
          attributes: const {'aria-live': 'polite'},
          [
            AmountText(
              short == null
                  ? t.schedules.perDay(amount: formatMoney(plan.perDay))
                  : t.schedules.notEnough(amount: formatMoney(short)),
              tone: short == null ? AmountTone.neutral : AmountTone.negative,
              textClass: 'text-hero',
            ),
            span(classes: 'text-caption payday__period', [
              .text(planPeriodLabel(plan)),
            ]),
            _line(t.schedules.morning, plan.morning),
            // The advance of the salary comes before the end, in the open.
            if (advance != null)
              _line(
                t.schedules.advanceOn(date: fullDate(advance, plan.today)),
                plan.advanced,
                income: true,
              ),
            _line(
              payday
                  ? t.schedules.paymentsUntilPayday(n: count)
                  : t.schedules.paymentsUntilMonth(n: count),
              -plan.paid,
            ),
            _line(t.schedules.aside, -plan.aside),
            const div(classes: 'payday__rule', []),
            _line(t.schedules.leftFor(n: plan.days), plan.free, strong: true),
            if (near != null && advance != null)
              span(classes: 'text-caption payday__near', [
                .text(
                  HiddenAmounts.mask(
                    context,
                    near.money.isNegative
                        ? t.schedules.nearShort(
                            date: fullDate(advance, plan.today),
                            amount: formatMoney(-near.money),
                          )
                        : t.schedules.nearEnough(
                            date: fullDate(advance, plan.today),
                            amount: formatMoney(near.money),
                            days: t.schedules.days(n: near.days),
                          ),
                  ),
                ),
              ]),
          ],
        ),
      ],
    );
  }

  static Component _line(
    String label,
    Money amount, {
    bool income = false,
    bool strong = false,
  }) {
    return div(
      classes: strong ? 'payday__line payday__line--strong' : 'payday__line',
      [
        span(
          classes: strong
              ? 'text-body-strong payday__line-label'
              : 'text-body payday__line-label',
          [.text(label)],
        ),
        AmountText(
          income ? '+${formatMoney(amount)}' : formatMoney(amount),
          tone: income
              ? AmountTone.positive
              : (strong && amount.isNegative
                    ? AmountTone.negative
                    : AmountTone.neutral),
          textClass: 'text-body-strong',
        ),
      ],
    );
  }
}

/// What becomes of the money of the days at the usual pace, in words and on
/// a chart (ADR 0023, point 24).
class _Forecast extends StatelessComponent {
  const _Forecast({required this.forecast});

  final SpendingForecast forecast;

  @override
  Component build(BuildContext context) {
    final plan = forecast.plan;
    final title = forecastTitle(forecast);
    final text = HiddenAmounts.mask(context, forecastText(forecast));
    final bad = forecast.runsDry;
    return GlassSurface(
      child: section(
        classes: 'payday__forecast',
        attributes: const {'aria-live': 'polite'},
        [
          SectionLabel(t.schedules.forecast),
          h2(
            classes: bad
                ? 'text-heading payday__verdict payday__verdict--bad'
                : 'text-heading payday__verdict payday__verdict--good',
            [.text(title)],
          ),
          p(classes: 'text-caption payday__words', [.text(text)]),
          ForecastChart(
            start: forecast.before.minorUnits.toDouble(),
            pace: forecast.usual.minorUnits.toDouble(),
            days: plan.days,
            stepDay: forecast.advanceDay,
            stepAmount: forecast.lift.minorUnits.toDouble(),
            planPace: plan.perDay.minorUnits.toDouble(),
            stepLabel: forecastAdvance(plan),
            label: '$title. $text',
            from: t.schedules.forecastToday,
            to: forecastEnd(plan),
            usual: t.schedules.forecastUsual,
            planned: HiddenAmounts.mask(context, forecastPlan(plan)),
          ),
          p(classes: 'text-caption payday__note', [
            .text(t.schedules.forecastNote),
          ]),
        ],
      ),
    );
  }
}
