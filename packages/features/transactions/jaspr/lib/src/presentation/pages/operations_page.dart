import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/src/presentation/components/operation_row.dart';

/// The operations of a month, day by day, with a search and filters.
///
/// It needs an [OperationsCubit] above it.
class OperationsPage extends StatefulComponent {
  /// Creates the page.
  const OperationsPage({
    required this.backHref,
    required this.addHref,
    required this.hrefOf,
    this.note,
    super.key,
  });

  /// Where the button that goes back leads.
  final String backHref;

  /// Where a new operation opens.
  final String addHref;

  /// Where the operation with this id opens.
  final String Function(String id) hrefOf;

  /// A quiet line under the list, such as where the data lives.
  final String? note;

  @override
  State<OperationsPage> createState() => _OperationsPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.operations__title').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-xs)',
        'justify-content': 'space-between',
      },
    ),
    css('.operations__heading').styles(raw: {'margin': '0'}),
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
    css('.operations__totals').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xxs) var(--space-md)',
      },
    ),
    // Amounts in several currencies can take more than a line.
    css('.operations__totals .amount').styles(raw: {'white-space': 'normal'}),
    css('.operations__check').styles(raw: {'color': 'var(--color-accent)'}),
    css('.operations__day').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.operations__day-heading').styles(
      raw: {
        'align-items': 'baseline',
        'color': 'var(--color-text-secondary)',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
        'padding': '0 var(--space-xs)',
      },
    ),
    css('.operations__day-heading .amount').styles(
      raw: {'white-space': 'normal'},
    ),
    css('.operations__note').styles(
      raw: {'color': 'var(--color-text-subtle)', 'margin': '0'},
    ),
  ];
}

class _OperationsPageState extends State<OperationsPage> {
  /// The months to choose from, while the choice is open.
  List<CivilDate>? _months;

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
        return BirkaColumn(
          children: [
            GlassPageHeader(
              backHref: component.backHref,
              backLabel: t.transactions.back,
              addHref: component.addHref,
              addLabel: t.app.newOperation,
            ),
            div(classes: 'operations__title', [
              h1(classes: 'text-title operations__heading', [
                .text(t.app.operations),
              ]),
              BirkaChip(
                glyph: BirkaGlyph.calendar,
                label: monthLabel(state.month, today: state.today),
                selected: _months != null,
                onTap: () => unawaited(_toggleMonths()),
              ),
            ]),
            ?_monthChoice(state),
            _tools(context, state),
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
                for (final day in state.days) _day(day, today: state.today),
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

  Component _tools(BuildContext context, OperationsState state) {
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
      if (state.expenses.isNotEmpty || state.income.isNotEmpty)
        div(classes: 'text-body operations__totals', [
          if (state.expenses.isNotEmpty)
            _total(
              t.transactions.filterExpenses,
              amountsLabel(state.expenses),
              AmountTone.neutral,
            ),
          if (state.income.isNotEmpty)
            _total(
              t.transactions.filterIncome,
              amountsLabel(state.income),
              AmountTone.positive,
            ),
        ]),
    ]);
  }

  /// `Расходы −86 420 ₽`.
  Component _total(String label, String amounts, AmountTone tone) {
    return span([
      .text('$label '),
      AmountText(amounts, tone: tone, textClass: 'text-body-strong'),
    ]);
  }

  Component _day(OperationDay day, {required CivilDate today}) {
    return section(classes: 'operations__day', [
      div(classes: 'operations__day-heading', [
        SectionLabel(dayHeading(day.day, today: today)),
        AmountText(
          amountsLabel(day.total),
          tone: AmountTone.muted,
          textClass: 'text-caption',
        ),
      ]),
      GlassListGroup(
        children: [
          for (final operation in day.operations)
            OperationRow(
              key: ValueKey(operation.id),
              operation: operation,
              href: component.hrefOf(operation.id),
            ),
        ],
      ),
    ]);
  }
}
