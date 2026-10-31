import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:reports_common/reports_common.dart';

/// What a month took or brought, by category and against the months before.
///
/// It needs a [ReportsCubit] above it.
class ReportsPage extends StatefulComponent {
  /// Creates the page.
  const ReportsPage({this.note, super.key});

  /// A quiet line under the page, such as where the data lives.
  final String? note;

  @override
  State<ReportsPage> createState() => _ReportsPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.reports__check').styles(raw: {'color': 'var(--color-accent)'}),
    css('.reports__ring').styles(
      raw: {'display': 'flex', 'justify-content': 'center'},
    ),
    css('.reports__middle').styles(
      raw: {
        'align-items': 'center',
        'box-sizing': 'border-box',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'max-width': '100%',
        // The ring takes 18 pixels on each side, and its inside is round.
        'padding': '0 var(--space-xl)',
        'text-align': 'center',
      },
    ),
    css('.reports__middle .amount').styles(
      raw: {'overflow-wrap': 'anywhere', 'white-space': 'normal'},
    ),
    css('.reports__kind').styles(raw: {'color': 'var(--color-text-muted)'}),
    css('.reports__line').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'padding': 'var(--space-md)',
        'position': 'relative',
      },
    ),
    // The thin line between rows, which stops short of the edges.
    css('.reports__line + .reports__line::before').styles(
      raw: {
        'background': 'var(--color-hairline)',
        'content': '""',
        'height': '1px',
        'left': 'var(--space-md)',
        'position': 'absolute',
        'right': 'var(--space-md)',
        'top': '0',
      },
    ),
    // An amount too long for the line takes its own.
    css('.reports__head').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xxs) var(--space-xs)',
      },
    ),
    css('.reports__dot').styles(
      raw: {
        'border-radius': '50%',
        'flex': 'none',
        'height': '10px',
        'width': '10px',
      },
    ),
    css('.reports__name').styles(
      raw: {
        'flex': '1',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.reports__head .text-body-strong.amount').styles(
      raw: {'margin-left': 'auto'},
    ),
    css('.reports__bar').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'border-radius': 'var(--radius-xs)',
        'height': '4px',
        'overflow': 'hidden',
      },
    ),
    css('.reports__fill').styles(raw: {'height': '100%'}),
    css('.reports__others').styles(
      raw: {'margin-top': 'calc(-1 * var(--space-xs))', 'text-align': 'center'},
    ),
    css('.reports__others .amount').styles(
      raw: {'overflow-wrap': 'anywhere', 'white-space': 'normal'},
    ),
    css('.reports__months').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
      },
    ),
    css('.reports__months-heading').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-xs)',
        'justify-content': 'space-between',
      },
    ),
    css('.reports__months-heading .section-label').styles(
      raw: {'flex': 'none'},
    ),
    css('.reports__average').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.reports__note').styles(
      raw: {'color': 'var(--color-text-subtle)', 'margin': '0'},
    ),
  ];
}

class _ReportsPageState extends State<ReportsPage> {
  static const _ringSize = 196;
  static const _ringThickness = 18;

  /// The longest amount that fits the ring in the larger type.
  static const _longestInRing = 11;

  /// The months to choose from, while the choice is open.
  List<CivilDate>? _months;

  Future<void> _toggleMonths() async {
    if (_months != null) {
      setState(() => _months = null);
      return;
    }
    final months = await context.read<ReportsCubit>().months();
    if (mounted) setState(() => _months = months);
  }

  Future<void> _pickMonth(CivilDate month) async {
    setState(() => _months = null);
    await context.read<ReportsCubit>().monthChanged(month);
  }

  @override
  Component build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        final cubit = context.read<ReportsCubit>();
        final report = state.report;
        final note = component.note;
        return BirkaColumn(
          children: [
            GlassPageHeader(
              title: t.app.reports,
              trailing: BirkaChip(
                glyph: BirkaGlyph.calendar,
                label: reportMonthLabel(state.month, today: state.today),
                selected: _months != null,
                onTap: () => unawaited(_toggleMonths()),
              ),
            ),
            ?_monthChoice(state),
            GlassSegmented<CategoryKind>(
              segments: {
                for (final kind in CategoryKind.values) kind: kindLabel(kind),
              },
              selected: state.kind,
              onChanged: (kind) => unawaited(cubit.kindChanged(kind)),
            ),
            ...switch (state.status) {
              ReportsStatus.loading => const <Component>[],
              ReportsStatus.failed => [
                GlassNotice(
                  text: t.reports.failed,
                  actions: [
                    BirkaButton(
                      label: t.app.retry,
                      onPressed: () => unawaited(cubit.retry()),
                    ),
                  ],
                ),
              ],
              ReportsStatus.ready => [
                if (report.isEmpty)
                  GlassNotice(text: emptyLabel(state.kind))
                else ...[
                  _ring(context, state),
                  GlassListGroup(
                    children: [
                      for (final line in report.lines)
                        _line(line, kind: state.kind),
                    ],
                  ),
                ],
                if (report.others.isNotEmpty)
                  div(classes: 'reports__others', [
                    AmountText(
                      report.others.map(formatMoney).join(' · '),
                      tone: AmountTone.muted,
                      textClass: 'text-caption',
                    ),
                  ]),
                if (report.average != null) _byMonth(context, report),
              ],
            },
            if (note != null && state.status == ReportsStatus.ready)
              p(classes: 'text-caption reports__note', [.text(note)]),
          ],
        );
      },
    );
  }

  Component? _monthChoice(ReportsState state) {
    final months = _months;
    if (months == null) return null;
    return GlassListGroup(
      children: [
        for (final month in months)
          GlassListRow(
            title: reportMonthLabel(month, today: state.today),
            trailing: month == state.month
                ? const span(classes: 'reports__check', [
                    BirkaIcon(BirkaGlyph.check),
                  ])
                : null,
            onTap: () => unawaited(_pickMonth(month)),
          ),
      ],
    );
  }

  /// The color of a category, whose color is its own choice.
  static String _colorOf(Category category) =>
      category.color ?? 'var(--color-text-subtle)';

  /// How a change reads: a rise of expenses is bad news, and of income good
  /// news.
  static AmountTone _toneOf(int percent, CategoryKind kind) {
    if (percent == 0) return AmountTone.muted;
    final good = (percent > 0) == (kind == CategoryKind.income);
    return good ? AmountTone.positive : AmountTone.negative;
  }

  /// The big ring with the total of the month in the middle.
  Component _ring(BuildContext context, ReportsState state) {
    final report = state.report;
    final total = formatMoney(report.total!);
    final change = report.change;
    // Hidden digits say nothing of the size, so the type must not either.
    final long = HiddenAmounts.mask(context, total).length > _longestInRing;
    return div(classes: 'reports__ring', [
      BirkaRing(
        size: _ringSize,
        thickness: _ringThickness,
        label: t.reports.ring,
        slices: [
          for (final line in report.lines)
            RingSlice(
              line.total.minorUnits.toDouble(),
              _colorOf(line.category),
            ),
        ],
        child: div(classes: 'reports__middle', [
          div(classes: 'reports__kind', [SectionLabel(kindLabel(state.kind))]),
          AmountText(
            total,
            textClass: long ? 'text-body-strong' : 'text-heading',
          ),
          if (change != null)
            AmountText(
              changeAgainst(change, month: state.month),
              tone: _toneOf(change, state.kind),
              textClass: 'text-caption',
              alwaysShown: true,
            ),
        ]),
      ),
    ]);
  }

  /// A category with its change, its amount and a bar against the biggest one.
  Component _line(ReportLine line, {required CategoryKind kind}) {
    final color = _colorOf(line.category);
    final change = line.change;
    return div(key: ValueKey(line.category.id), classes: 'reports__line', [
      div(classes: 'reports__head', [
        span(
          classes: 'reports__dot',
          styles: Styles(raw: {'background': color}),
          const [],
        ),
        span(classes: 'text-body-strong reports__name', [
          .text(line.category.name),
        ]),
        if (change != null)
          AmountText(
            percentLabel(change),
            tone: _toneOf(change, kind),
            textClass: 'text-caption',
            alwaysShown: true,
          ),
        AmountText(formatMoney(line.total), textClass: 'text-body-strong'),
      ]),
      div(classes: 'reports__bar', [
        div(
          classes: 'reports__fill',
          styles: Styles(
            raw: {'background': color, 'width': '${line.share * 100}%'},
          ),
          const [],
        ),
      ]),
    ]);
  }

  /// The last months as bars.
  Component _byMonth(BuildContext context, Report report) {
    final average = report.average!;
    return GlassSurface(
      child: div(classes: 'reports__months', [
        div(classes: 'reports__months-heading', [
          SectionLabel(t.reports.byMonth),
          span(classes: 'text-caption reports__average', [
            // A compact amount would tell its size by its word.
            .text(
              averageLabel(
                HiddenAmounts.of(context)
                    ? HiddenAmounts.mask(context, formatMoney(average))
                    : formatCompactMoney(average),
              ),
            ),
          ]),
        ]),
        BirkaBars(
          bars: [
            for (final (index, month) in report.months.indexed)
              BirkaBar(
                value: month.total.minorUnits.toDouble(),
                amount: formatCompactFigure(month.total),
                label: shortMonthLabel(month.month),
                highlighted: index == report.months.length - 1,
              ),
          ],
        ),
      ]),
    );
  }
}
