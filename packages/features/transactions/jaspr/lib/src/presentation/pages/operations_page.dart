import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/src/presentation/components/operation_day_group.dart';
import 'package:transactions_jaspr/src/presentation/components/operations_totals.dart';

/// The operations of a month, day by day, with a search and filters. On a
/// wide page a [side] stands beside the list, such as what the month came to
/// or the card of the [picked] operation, and the totals of the month go to
/// it.
///
/// The operations of an answer of «Спросить» stand alone under a plaque of
/// the question, with their totals under it, until the cross of the plaque
/// takes it off (ADR 0028).
///
/// It needs an [OperationsCubit] above it.
class OperationsPage extends StatefulComponent {
  /// Creates the page.
  const OperationsPage({
    required this.addHref,
    required this.hrefOf,
    this.note,
    this.side,
    this.picked,
    this.answerHref,
    super.key,
  });

  /// Where a new operation opens.
  final String addHref;

  /// Where the operation with this id opens.
  final String Function(String id) hrefOf;

  /// A quiet line under the list, such as where the data lives.
  final String? note;

  /// What stands beside the list on a wide page.
  final Component? side;

  /// The operation whose card is open beside the list.
  final String? picked;

  /// Where «К ответу» leads from the plaque of a question.
  final String? answerHref;

  @override
  State<OperationsPage> createState() => _OperationsPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.operations__tools').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.operations__filters').styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': 'var(--space-xs)'},
    ),
    css('.operations__check').styles(raw: {'color': 'var(--color-accent)'}),
    css('.operations__note').styles(
      raw: {'color': 'var(--color-text-subtle)', 'margin': '0'},
    ),
    css('.operations__focus').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs) var(--space-sm)',
      },
    ),
    css('.operations__focus .section-label').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.operations__answer').styles(
      raw: {
        'color': 'var(--color-accent)',
        'margin-left': 'auto',
        'text-decoration': 'none',
      },
    ),
  ];
}

class _OperationsPageState extends State<OperationsPage> {
  /// The months to choose from, while the choice is open.
  List<CivilDate>? _months;

  /// The plaque of the question, kept while it closes.
  OperationsFocus? _focus;

  Future<void> _toggleMonths() async {
    if (_months != null) {
      setState(() => _months = null);
      return;
    }
    final months = await context.read<OperationsCubit>().months();
    if (mounted) setState(() => _months = months);
  }

  Future<void> _pickMonth(CivilDate month) async {
    setState(() => _months = null);
    await context.read<OperationsCubit>().monthChanged(month);
  }

  @override
  Component build(BuildContext context) {
    return BlocBuilder<OperationsCubit, OperationsState>(
      builder: (context, state) {
        final note = component.note;
        final side = component.side;
        final header = GlassPageHeader(
          title: t.app.operations,
          trailing: BirkaChip(
            glyph: BirkaGlyph.calendar,
            label: monthLabel(state.month, today: state.today),
            selected: _months != null,
            onTap: () => unawaited(_toggleMonths()),
          ),
        );
        final list = [
          ?_monthChoice(state),
          _tools(context, state, totals: side == null || state.focus != null),
          ...switch (state.status) {
            OperationsStatus.loading => const <Component>[],
            OperationsStatus.failed => [
              GlassNotice(
                text: t.transactions.failedToReadOperations,
                actions: [
                  BirkaButton(
                    label: t.app.retry,
                    onPressed: () =>
                        unawaited(context.read<OperationsCubit>().retry()),
                  ),
                ],
              ),
            ],
            OperationsStatus.ready when state.shown.isNotEmpty => [
              for (final day in state.days)
                OperationDayGroup(
                  day: day,
                  today: state.today,
                  hrefOf: component.hrefOf,
                  picked: component.picked,
                ),
            ],
            OperationsStatus.ready when state.isNarrowed => [
              GlassNotice(text: t.transactions.nothingFound),
            ],
            OperationsStatus.ready => [
              GlassNotice(
                title: t.transactions.noOperationsTitle,
                text: t.transactions.noOperationsHint,
                actions: [
                  BirkaButton(
                    label: t.app.newOperation,
                    href: component.addHref,
                  ),
                ],
              ),
            ],
          },
          if (note != null && state.status == OperationsStatus.ready)
            p(classes: 'text-caption operations__note', [.text(note)]),
        ];
        if (side == null) return BirkaColumn(children: [header, ...list]);
        return BirkaColumn(
          children: [
            header,
            BirkaSplit(asideWidth: 420, main: list, aside: [side]),
          ],
        );
      },
    );
  }

  Component? _monthChoice(OperationsState state) {
    final months = _months;
    if (months == null) return null;
    return GlassListGroup(
      children: [
        for (final month in months)
          GlassListRow(
            title: monthLabel(month, today: state.today),
            trailing: month == state.month
                ? const span(classes: 'operations__check', [
                    BirkaIcon(BirkaGlyph.check),
                  ])
                : null,
            onTap: () => unawaited(_pickMonth(month)),
          ),
      ],
    );
  }

  /// The plaque of the question whose operations stand alone: its cross
  /// takes it off, and «К ответу» leads back to the answer. It closes as the
  /// list widens to the month.
  Component? _plaque(OperationsCubit cubit, OperationsFocus? focus) {
    if (focus != null) _focus = focus;
    final shown = _focus;
    if (shown == null) return null;
    final answerHref = component.answerHref;
    return BirkaFold(
      open: focus != null,
      gap: 'var(--space-sm)',
      children: [
        div(classes: 'operations__focus', [
          SectionLabel(t.transactions.fromQuestion),
          BirkaChip(
            label: shown.title,
            selected: true,
            trailingGlyph: BirkaGlyph.close,
            semanticLabel: t.transactions.dropFocus(title: shown.title),
            onTap: () => unawaited(cubit.dropFocus()),
          ),
          if (answerHref != null)
            a(
              classes: 'text-body-strong operations__answer',
              href: answerHref,
              [.text(t.transactions.toAnswer)],
            ),
        ]),
      ],
    );
  }

  /// The search and the filters, and under them the [totals] of the month on a
  /// page without a side, or of the operations of a question.
  Component _tools(
    BuildContext context,
    OperationsState state, {
    required bool totals,
  }) {
    final cubit = context.read<OperationsCubit>();
    return div(classes: 'operations__tools', [
      GlassSearchField(
        label: t.transactions.search,
        clearLabel: t.transactions.clearSearch,
        hint: t.transactions.searchHint,
        value: state.query,
        onChanged: cubit.queryChanged,
      ),
      div(classes: 'operations__filters', [
        for (final filter in OperationsFilter.values)
          BirkaChip(
            label: filterLabel(filter),
            selected: filter == state.filter,
            compact: true,
            onTap: () => cubit.filterChanged(filter),
          ),
      ]),
      ?_plaque(cubit, state.focus),
      if (totals && (state.expenses.isNotEmpty || state.income.isNotEmpty))
        OperationsTotals(state),
    ]);
  }
}
