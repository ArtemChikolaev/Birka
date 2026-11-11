import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:reports_common/reports_common.dart';
import 'package:reports_jaspr/src/presentation/components/report_line_row.dart';

/// What a month took or brought, by category and against the months before.
/// A [wide] page has the ring and the months on one half and the categories
/// on the other.
///
/// It needs a [ReportsCubit] above it.
class ReportsPage extends StatefulComponent {
  /// Creates the page.
  const ReportsPage({this.note, this.wide = false, super.key});

  /// A quiet line under the page, such as where the data lives.
  final String? note;

  /// Whether the page is wide.
  final bool wide;

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
    css('.reports__others').styles(
      raw: {'margin-top': 'calc(-1 * var(--space-xs))', 'text-align': 'center'},
    ),
    css('.reports__others .amount').styles(
      raw: {'overflow-wrap': 'anywhere', 'white-space': 'normal'},
    ),
    css('.reports__rate').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'margin': 'calc(-1 * var(--space-xs)) 0 0',
        'text-align': 'center',
      },
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
        final ready = state.status == ReportsStatus.ready;
        final header = GlassPageHeader(
          title: t.app.reports,
          trailing: BirkaChip(
            glyph: BirkaGlyph.calendar,
            label: reportMonthLabel(state.month, today: state.today),
            selected: _months != null,
            onTap: () => unawaited(_toggleMonths()),
          ),
        );
        final kinds = GlassSegmented<CategoryKind>(
          segments: {
            for (final kind in CategoryKind.values) kind: kindLabel(kind),
          },
          selected: state.kind,
          onChanged: (kind) => unawaited(cubit.kindChanged(kind)),
        );
        final failure = state.status == ReportsStatus.failed
            ? GlassNotice(
                text: t.reports.failed,
                actions: [
                  BirkaButton(
                    label: t.app.retry,
                    onPressed: () => unawaited(cubit.retry()),
                  ),
                ],
              )
            : null;
        final empty = ready && report.isEmpty
            ? GlassNotice(text: emptyLabel(state.kind))
            : null;
        final ring = ready && !report.isEmpty ? _ring(context, state) : null;
        final lines = ready && !report.isEmpty
            ? GlassListGroup(
                children: [
                  for (final line in report.lines)
                    ReportLineRow(
                      line,
                      kind: state.kind,
                      key: ValueKey(categoryKey(line.category)),
                    ),
                ],
              )
            : null;
        final after = [
          if (ready && report.others.isNotEmpty)
            div(classes: 'reports__others', [
              AmountText(
                report.others.map(formatMoney).join(' · '),
                tone: AmountTone.muted,
                textClass: 'text-caption',
              ),
            ]),
          if (ready && state.converted)
            p(classes: 'text-caption reports__rate', [
              .text(t.reports.dayRates),
            ]),
          if (ready && report.average != null) _byMonth(context, report),
        ];
        final quiet = note != null && ready
            ? p(classes: 'text-caption reports__note', [.text(note)])
            : null;
        if (!component.wide) {
          return BirkaColumn(
            children: [
              header,
              ?_monthChoice(state),
              kinds,
              ?failure,
              ?empty,
              ?ring,
              ?lines,
              ...after,
              ?quiet,
            ],
          );
        }
        return BirkaColumn(
          children: [
            header,
            ?_monthChoice(state),
            BirkaSplit(
              halves: true,
              main: [kinds, ?failure, ?empty, ?ring, ...after],
              aside: [?lines, ?quiet],
            ),
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
              categoryColor(line.category),
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
              tone: changeTone(change, state.kind),
              textClass: 'text-caption',
              alwaysShown: true,
            ),
        ]),
      ),
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
