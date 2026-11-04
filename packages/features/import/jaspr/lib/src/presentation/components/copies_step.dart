import 'package:design_jaspr/design_jaspr.dart';
import 'package:import_common/import_common.dart';
import 'package:import_jaspr/src/presentation/components/import_bits.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The fifth step: the operations that the ledger already has, each against
/// its transaction with the reasons they match, and the rows that cannot go
/// in.
class CopiesStep extends StatelessComponent {
  /// Creates the step of [state].
  const CopiesStep({required this.state, super.key});

  /// The import.
  final ImportState state;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<ImportCubit>();
    final plan = state.plan;
    if (plan == null) return const BirkaPlaceholder();
    final copies = [
      for (final operation in plan.operations)
        if (operation.duplicate != null) operation,
    ];
    final thisYear = state.statement?.to?.year ?? 0;
    final problems = plan.problems;
    return div(classes: 'import-stack', [
      div(classes: 'import-heading', [
        h2(classes: 'text-heading import-heading__title', [
          .text(
            copies.isEmpty
                ? t.imports.noCopies
                : t.imports.copiesTitle(
                    n: copies.length,
                    count: formatCount(copies.length),
                  ),
          ),
        ]),
        p(classes: 'text-body import-heading__line', [
          .text(copies.isEmpty ? t.imports.noCopiesText : t.imports.copiesText),
        ]),
      ]),
      for (final operation in copies)
        _copy(cubit, plan, operation, thisYear: thisYear),
      if (problems.isNotEmpty)
        GlassNotice(
          title: t.imports.leftTitle(
            n: problems.length,
            count: formatCount(problems.length),
          ),
          text: [
            for (final problem in problems.take(3))
              t.imports.problemLine(
                line: problem.line,
                fault: t.imports.planFaults[problem.fault.name] ?? problem.text,
              ),
            if (problems.length > 3)
              t.imports.andMore(count: formatCount(problems.length - 3)),
          ].join('; '),
        ),
    ]);
  }

  Component _copy(
    ImportCubit cubit,
    ImportPlan plan,
    PlannedOperation operation, {
    required int thisYear,
  }) {
    final duplicate = operation.duplicate!;
    final transaction = duplicate.transaction;
    final row = operation.row;
    final kept = plan.choices.keep.contains(row.line);
    final amount = signedMoney(signedAmount(operation));
    final category = transaction.allocations
        .map((it) => it.categoryId)
        .nonNulls
        .map(_categoryName)
        .nonNulls
        .firstOrNull;
    final account = transaction.entries
        .map((it) => _accountName(it.accountId))
        .nonNulls
        .firstOrNull;
    final time = row.date.time;
    return div(key: ValueKey(row.line), classes: 'glass import-copy', [
      div(classes: 'import-copy__pair', [
        div(classes: 'import-copy__side', [
          span(classes: 'text-label import-copy__label', [
            .text(t.imports.fromFile),
          ]),
          div(classes: 'import-copy__line', [
            span(classes: 'text-body-strong import-copy__name', [
              .text(row.description.isEmpty ? '—' : row.description),
            ]),
            AmountText(amount, textClass: 'text-body-strong'),
          ]),
          span(classes: 'text-caption import-copy__detail', [
            .text(
              [
                dayLabel(row.date.day, thisYear: thisYear),
                if (time != null) _clock(time),
                if (row.note.isNotEmpty) row.note,
              ].join(' · '),
            ),
          ]),
        ]),
        const span(classes: 'text-body import-copy__like', [.text('≈')]),
        div(classes: 'import-copy__side import-copy__side--ledger', [
          span(classes: 'text-label import-copy__label', [
            .text(t.imports.inLedger),
          ]),
          div(classes: 'import-copy__line', [
            span(classes: 'text-body-strong import-copy__name', [
              .text(
                transaction.note.isEmpty
                    ? category ?? t.app.noCategory
                    : transaction.note,
              ),
            ]),
            AmountText(amount, textClass: 'text-body-strong'),
          ]),
          span(classes: 'text-caption import-copy__detail', [
            .text(
              [
                dayLabel(transaction.occurredOn, thisYear: thisYear),
                ?category,
                ?account,
              ].join(' · '),
            ),
          ]),
        ]),
      ]),
      div(classes: 'import-copy__foot', [
        ul(classes: 'import-copy__reasons', [
          for (final reason in DuplicateReason.values)
            if (duplicate.reasons.contains(reason))
              li(classes: 'text-caption import-copy__reason', [
                const BirkaIcon(BirkaGlyph.check),
                .text(t.imports.reasons[reason.name] ?? reason.name),
              ]),
        ]),
        div(classes: 'import-copy__choice', [
          GlassSegmented<bool>(
            segments: {false: t.imports.skipCopy, true: t.imports.keepBoth},
            selected: kept,
            onChanged: (keep) => cubit.keep(row.line, keep: keep),
          ),
        ]),
      ]),
    ]);
  }

  static String _clock(Duration time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.inHours)}:${two(time.inMinutes % 60)}';
  }

  String? _categoryName(String id) =>
      state.categories.where((it) => it.id == id).firstOrNull?.name;

  String? _accountName(String id) =>
      state.accounts.where((it) => it.id == id).firstOrNull?.name;

  /// The styles of the step.
  @css
  static List<StyleRule> get styles => [
    css('.import-copy').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.import-copy__pair').styles(
      raw: {
        'align-items': 'center',
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'minmax(0, 1fr) auto minmax(0, 1fr)',
      },
    ),
    css('.import-copy__side').styles(
      raw: {
        'background': 'var(--color-surface)',
        'border': '1px solid var(--color-hairline)',
        'border-radius': 'var(--radius-md)',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
        'padding': 'var(--space-sm)',
      },
    ),
    css('.import-copy__side--ledger').styles(
      raw: {
        'background': 'var(--color-accent-soft)',
        'border-color': 'var(--color-accent-soft)',
      },
    ),
    css('.import-copy__label').styles(
      raw: {'color': 'var(--color-text-subtle)', 'font-size': '11px'},
    ),
    css('.import-copy__side--ledger .import-copy__label').styles(
      raw: {'color': 'var(--color-accent)'},
    ),
    css('.import-copy__line').styles(
      raw: {
        'align-items': 'baseline',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
      },
    ),
    css('.import-copy__name').styles(
      raw: {
        'color': 'var(--color-text)',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.import-copy__detail').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.import-copy__like').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-surface)',
        'border-radius': '50%',
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'height': '28px',
        'justify-content': 'center',
        'width': '28px',
      },
    ),
    css('.import-copy__foot').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
      },
    ),
    css('.import-copy__reasons').styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
        'list-style': 'none',
        'margin': '0',
        'padding': '0',
      },
    ),
    css('.import-copy__reason').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-surface)',
        'border-radius': 'var(--radius-pill)',
        'color': 'var(--color-text-secondary)',
        'display': 'inline-flex',
        'gap': 'var(--space-xxs)',
        'padding': 'var(--space-xxs) var(--space-sm)',
      },
    ),
    css('.import-copy__reason .birka-icon').styles(
      raw: {
        'color': 'var(--color-accent)',
        'height': '14px',
        'width': '14px',
      },
    ),
    css('.import-copy__choice').styles(
      raw: {'flex': '0 1 420px', 'margin-left': 'auto', 'min-width': '0'},
    ),
    // A phone puts the transaction of the ledger under the row of the file.
    css.media(const MediaQuery.raw('(max-width: 640px)'), [
      css('.import-copy__pair').styles(
        raw: {'grid-template-columns': 'minmax(0, 1fr)'},
      ),
      css('.import-copy__like').styles(raw: {'justify-self': 'center'}),
      css('.import-copy__choice').styles(raw: {'flex': '1 1 100%'}),
    ]),
  ];
}
