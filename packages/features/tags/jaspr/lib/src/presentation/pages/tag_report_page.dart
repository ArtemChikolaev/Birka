import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:tags_common/tags_common.dart';

/// What a метка took (ADR 0027): the total in the base currency, a day on
/// the spot of a trip, the currencies, the categories and the operations.
/// Beside the list on a wide page it [closes] with a cross.
///
/// It needs a [TagReportCubit] above it.
class TagReportPage extends StatelessComponent {
  /// Creates the page.
  const TagReportPage({
    required this.onBack,
    required this.editHref,
    this.closes = false,
    this.operations,
    super.key,
  });

  /// Called by the way back, and when the метка is gone.
  final VoidCallback onBack;

  /// Where the form of the метка opens.
  final String editHref;

  /// Whether the way back closes the report, as it does beside the list.
  final bool closes;

  /// The operations that wear the метка, as the host draws them.
  final Component? operations;

  @override
  Component build(BuildContext context) {
    return BlocConsumer<TagReportCubit, TagReportState>(
      listenWhen: (before, now) => before.status != now.status,
      listener: (_, state) {
        if (state.status == TagReportStatus.gone) onBack();
      },
      builder: (context, state) {
        final report = state.report;
        return BirkaColumn(
          children: [
            BackHeader(
              label: report?.tag.isTrip ?? true ? t.tags.trip : t.tags.tag,
              backLabel: closes ? t.tags.close : t.tags.back,
              onBack: onBack,
              closes: closes,
              trailing: report == null
                  ? null
                  : BirkaChip(
                      label: t.tags.edit,
                      selected: false,
                      href: editHref,
                    ),
            ),
            if (state.status == TagReportStatus.failed)
              GlassNotice(text: t.tags.failed),
            if (report != null) ..._report(context, report, state.today),
          ],
        );
      },
    );
  }

  List<Component> _report(
    BuildContext context,
    TagReport report,
    CivilDate today,
  ) {
    final operations = this.operations;
    return [
      _summary(report, today),
      _stats(context, report, today),
      if (report.currencies.length > 1)
        section(classes: 'tag-report__group', [
          SectionLabel(t.tags.report.currencies),
          GlassListGroup(
            children: [
              for (final part in report.currencies)
                _currency(part, report, today),
            ],
          ),
          p(classes: 'text-caption tag-report__note', [
            .text(t.tags.report.ratesNote),
          ]),
        ]),
      if (report.missingRates)
        p(classes: 'text-caption tag-report__note', [
          .text(t.tags.report.noRate),
        ]),
      if (report.categories.isNotEmpty)
        section(classes: 'tag-report__group', [
          SectionLabel(t.tags.report.categories),
          GlassListGroup(
            children: [
              for (final part in report.categories)
                ShareLine(
                  key: ValueKey(part.category?.id),
                  color: part.category?.color ?? 'var(--color-text-subtle)',
                  title: part.category?.name ?? t.tags.report.noCategory,
                  note: span(classes: 'text-caption tag-report__share', [
                    .text('${part.percent}%'),
                  ]),
                  amount: AmountText(
                    formatMoney(part.total),
                    textClass: 'text-body-strong',
                  ),
                  fraction: part.fraction,
                ),
            ],
          ),
        ]),
      if (report.isEmpty)
        p(classes: 'text-body tag-report__nothing', [
          .text(t.tags.report.nothing),
        ])
      else
        ?operations,
    ];
  }

  /// The badge, the name, the total and the days.
  Component _summary(TagReport report, CivilDate today) {
    return div(classes: 'tag-report__summary', [
      GlyphBadge(
        glyph: report.tag.isTrip ? BirkaGlyph.plane : BirkaGlyph.tag,
        color: 'var(--color-accent)',
        size: 72,
      ),
      h1(classes: 'text-heading tag-report__name', [.text(report.tag.name)]),
      AmountText(formatMoney(report.total), textClass: 'text-display'),
      p(classes: 'text-body tag-report__line', [
        .text(reportLine(report, today: today)),
      ]),
    ]);
  }

  /// A day on the spot, or a month of a метка without days, and how many
  /// operations wear it.
  Component _stats(BuildContext context, TagReport report, CivilDate today) {
    final perDay = report.perDay;
    final perMonth = report.perMonth;
    final last = report.last;
    final first = switch ((perDay, perMonth)) {
      (final day?, _) => _stat(
        context,
        label: t.tags.report.perDay,
        value: _about(report.perDayLocal ?? day),
        note: report.perDayLocal == null
            ? t.tags.report.forDays(n: report.elapsed)
            : formatMoney(day.roundedToWhole()),
      ),
      (null, final month?) => _stat(
        context,
        label: t.tags.report.perMonth,
        value: _about(month),
        note: t.tags.report.forDays(n: report.span),
      ),
      _ => null,
    };
    return div(classes: 'tag-report__stats', [
      ?first,
      _stat(
        context,
        label: t.tags.report.count,
        value: '${report.operations.length}',
        note: report.tag.isTrip
            ? _split(report)
            : last == null
            ? ''
            : t.tags.report.last(
                date: dateLabel(
                  year: last.year,
                  month: last.month,
                  day: last.day,
                  thisYear: today.year,
                ),
              ),
      ),
    ]);
  }

  static Component _stat(
    BuildContext context, {
    required String label,
    required String value,
    required String note,
  }) {
    return div(classes: 'glass tag-report__stat', [
      span(classes: 'text-caption tag-report__stat-label', [.text(label)]),
      span(classes: 'text-amount tag-report__stat-value', [
        .text(HiddenAmounts.mask(context, value)),
      ]),
      if (note.isNotEmpty)
        span(classes: 'text-caption tag-report__stat-note', [
          .text(HiddenAmounts.mask(context, note)),
        ]),
    ]);
  }

  static String _about(Money amount) =>
      '≈ ${formatMoney(amount.roundedToWhole())}';

  /// `44 там, 2 заранее`, and nothing when every operation fell on the days.
  static String _split(TagReport report) {
    if (report.before == 0 && report.after == 0) return '';
    return [
      t.tags.report.there(n: report.there),
      if (report.before > 0) t.tags.report.before(n: report.before),
      if (report.after > 0) t.tags.report.after(n: report.after),
    ].join(', ');
  }

  /// What the expenses took in one currency, and in the base one.
  static Component _currency(
    TagCurrencyPart part,
    TagReport report,
    CivilDate today,
  ) {
    final currency = part.amount.currency;
    final inBase = part.inBase;
    final own = AmountText(
      formatMoney(part.amount),
      textClass: currency == report.base || inBase == null
          ? 'text-body-strong'
          : 'text-caption',
      tone: currency == report.base || inBase == null
          ? AmountTone.neutral
          : AmountTone.muted,
    );
    return GlassListRow(
      key: ValueKey(currency.code),
      leading: span(classes: 'text-body-strong tag-report__sign', [
        .text(currencySign(currency)),
      ]),
      title: t.app.currencies[currency.code] ?? currency.code,
      subtitle: _currencyLine(part, report, today),
      trailing: currency == report.base || inBase == null
          ? own
          : span(classes: 'tag-report__amounts', [
              AmountText(formatMoney(inBase), textClass: 'text-body-strong'),
              own,
            ]),
    );
  }

  static String _currencyLine(
    TagCurrencyPart part,
    TagReport report,
    CivilDate today,
  ) {
    final only = part.only;
    if (only != null) {
      final day = only.occurredOn;
      final date = dateLabel(
        year: day.year,
        month: day.month,
        day: day.day,
        thisYear: today.year,
      );
      final note = only.note.trim();
      return note.isEmpty ? date : '$note, $date';
    }
    if (report.tag.isTrip && part.there == part.count) {
      return t.tags.report.onTheSpot(n: part.count);
    }
    return t.tags.operations(n: part.count);
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.tag-report__summary').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'text-align': 'center',
      },
    ),
    css('.tag-report__summary .amount').styles(
      raw: {'overflow-wrap': 'anywhere', 'white-space': 'normal'},
    ),
    css('.tag-report__name').styles(
      raw: {'margin': 'var(--space-xs) 0 0', 'overflow-wrap': 'anywhere'},
    ),
    css('.tag-report__line').styles(
      raw: {'color': 'var(--color-text-muted)', 'margin': '0'},
    ),
    css('.tag-report__stats').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-auto-columns': 'minmax(0, 1fr)',
        'grid-auto-flow': 'column',
      },
    ),
    css('.glass.tag-report__stat').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
      },
    ),
    css('.tag-report__stat-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.tag-report__stat-value').styles(
      raw: {
        'color': 'var(--color-text)',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.tag-report__stat-note').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.tag-report__group').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.tag-report__group .section-label').styles(
      raw: {'padding': '0 var(--space-xs)'},
    ),
    css('.tag-report__note').styles(
      raw: {'color': 'var(--color-text-muted)', 'margin': '0'},
    ),
    css('.tag-report__share').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.tag-report__sign').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-surface-raised)',
        'border-radius': 'var(--radius-sm)',
        'color': 'var(--color-text)',
        'display': 'flex',
        'flex': 'none',
        'height': '36px',
        'justify-content': 'center',
        'width': '36px',
      },
    ),
    css('.tag-report__amounts').styles(
      raw: {
        'align-items': 'flex-end',
        'display': 'flex',
        'flex-direction': 'column',
      },
    ),
    css('.tag-report__nothing').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'margin': '0',
        'text-align': 'center',
      },
    ),
  ];
}
