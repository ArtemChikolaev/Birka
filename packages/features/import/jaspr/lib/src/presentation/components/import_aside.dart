import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:import_common/import_common.dart';
import 'package:import_jaspr/src/presentation/components/import_bits.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';

/// What stands beside a step: how the import works on the first step, what
/// enters the ledger with the way on through the next ones, and the ways
/// out after the last.
class ImportAside extends StatelessComponent {
  /// Creates the side of [state].
  const ImportAside({
    required this.state,
    required this.operationsHref,
    required this.inboxHref,
    super.key,
  });

  /// The import.
  final ImportState state;

  /// The page of the operations.
  final String operationsHref;

  /// The inbox.
  final String inboxHref;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<ImportCubit>();
    return switch (state.step) {
      ImportStep.file => div(classes: 'import-side', [
        _howItWorks(),
        div(classes: 'glass import-private', [
          const GlyphBadge(
            glyph: BirkaGlyph.hidden,
            color: 'var(--color-accent)',
          ),
          div(classes: 'import-private__text', [
            span(classes: 'text-body-strong import-private__title', [
              .text(t.imports.privacyTitle),
            ]),
            span(classes: 'text-caption import-private__line', [
              .text(t.imports.privacyText),
            ]),
          ]),
        ]),
      ]),
      ImportStep.done => div(classes: 'import-side', [
        // What waits in the inbox comes first, as long as something does.
        if ((state.plan?.unsorted ?? 0) > 0 && !state.undone) ...[
          BirkaButton(label: t.imports.sortInbox, href: inboxHref),
          BirkaButton(
            label: t.imports.toOperations,
            quiet: true,
            href: operationsHref,
          ),
        ] else
          BirkaButton(label: t.imports.toOperations, href: operationsHref),
        BirkaButton(
          label: t.imports.another,
          quiet: true,
          onPressed: cubit.restart,
        ),
      ]),
      _ => div(classes: 'import-side', [
        div(classes: 'glass import-summary', [
          span(classes: 'text-label import-summary__title', [
            .text(t.imports.summaryTitle),
          ]),
          FileCard(
            state,
            into: state.step == ImportStep.copies ? _into() : null,
          ),
          div(classes: 'import-summary__rows', _rows()),
        ]),
        _action(cubit),
        if (state.step == ImportStep.copies)
          p(classes: 'text-caption import-side__note', [
            .text(t.imports.writeNote),
          ]),
        button(
          classes: 'text-body-strong import-side__back',
          type: ButtonType.button,
          disabled: state.writing,
          onClick: cubit.back,
          [.text(t.imports.back)],
        ),
      ]),
    };
  }

  Component _howItWorks() =>
      GlassSteps(title: t.imports.howTitle, points: t.imports.how);

  /// The names of the accounts that the operations go into.
  String? _into() {
    final names = {
      for (final choice in state.choices?.accounts.values ?? <AccountChoice>[])
        switch (choice) {
          IntoAccount(:final account) => account.name,
          NewAccount(:final name) => name,
          LeaveOut() => null,
        },
    }.nonNulls;
    return names.isEmpty ? null : names.join(', ');
  }

  List<Component> _rows() {
    final statement = state.statement;
    final plan = state.planned ? state.plan : null;
    final from = statement?.from;
    final to = statement?.to;
    final period = from == null || to == null ? '—' : periodLabel(from, to);
    final operations = formatCount(statement?.rows.length ?? 0);
    switch (state.step) {
      case ImportStep.format:
        final format = state.layout?.format;
        final kind = t.imports.fileKinds[state.table?.file.name ?? ''];
        return [
          SummaryRow(
            t.imports.summaryFormat,
            [
              if (format == null) t.imports.own else formatLabel(format),
              ?kind,
            ].join(' · '),
          ),
          SummaryRow(
            t.imports.summaryRows,
            formatCount(state.table?.rows.length ?? 0),
          ),
          SummaryRow(t.imports.summaryPeriod, period),
          SummaryRow(t.imports.summaryAccount, t.imports.accountLater),
        ];
      case ImportStep.columns:
        final (spent, received) = _sums();
        return [
          SummaryRow(t.imports.summaryOperations, operations),
          SummaryRow(
            t.imports.summarySpent,
            moneyLine(spent),
            tone: AmountTone.negative,
          ),
          SummaryRow(
            t.imports.summaryReceived,
            moneyLine(received, signed: true),
            tone: AmountTone.positive,
          ),
          SummaryRow(
            t.imports.summaryUnsorted,
            plan == null
                ? '—'
                : t.imports.toInbox(count: formatCount(plan.unsorted)),
          ),
        ];
      case ImportStep.account:
        final after = plan?.balances.values.toList() ?? const <Money>[];
        return [
          SummaryRow(t.imports.summaryAccount, _into() ?? '—'),
          SummaryRow(t.imports.summaryOperations, operations),
          SummaryRow(t.imports.summaryPeriod, period),
          SummaryRow(t.imports.summaryBalance, moneyLine(after)),
        ];
      case ImportStep.copies:
        return [
          SummaryRow(t.imports.summaryFromFile, operations),
          SummaryRow(
            t.imports.summaryCopies,
            plan == null ? '—' : formatCount(plan.copies.length),
          ),
          SummaryRow(
            t.imports.summaryAdded,
            plan == null ? '—' : formatCount(plan.added.length),
            strong: true,
          ),
        ];
      case ImportStep.file || ImportStep.done:
        return const [];
    }
  }

  /// The money spent and received by the operations of the file, which no
  /// account of the ledger has been chosen for yet.
  (List<Money>, List<Money>) _sums() {
    final spent = <Money>[];
    final received = <Money>[];
    for (final row in state.statement?.rows ?? const <StatementRow>[]) {
      if (row.isTransfer) continue;
      if (row.out case final leg?) {
        final money = moneyOf(
          leg.amount + (row.fee ?? Decimal.zero),
          leg.currency,
          fallback: state.currency,
        );
        if (money != null) spent.add(-money);
      }
      if (row.into case final leg?) {
        final money = moneyOf(
          leg.amount,
          leg.currency,
          fallback: state.currency,
        );
        if (money != null) received.add(money);
      }
    }
    return (spent, received);
  }

  Component _action(ImportCubit cubit) {
    final progress = state.progress;
    if (state.step == ImportStep.copies) {
      final plan = state.plan;
      final count = plan?.added.length ?? 0;
      final label = switch (progress) {
        (:final done, :final total) when state.writing => t.imports.writing(
          done: formatCount(done),
          total: formatCount(total),
        ),
        _ when !state.planned => t.imports.planning,
        _ when count == 0 => t.imports.nothingToWrite,
        _ => t.imports.write(n: count, count: formatCount(count)),
      };
      return BirkaButton(
        label: label,
        onPressed: state.planned && count > 0 && state.open
            ? () => unawaited(cubit.write())
            : null,
      );
    }
    final next = ImportStep.values[state.step.index + 1];
    return BirkaButton(
      label: t.imports.next[next.name] ?? t.imports.steps[next.name] ?? '',
      onPressed: next.index <= state.furthest.index ? cubit.next : null,
    );
  }

  /// The styles of the side.
  @css
  static List<StyleRule> get styles => [
    css('.import-side').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
      },
    ),
    css('.import-summary').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
      },
    ),
    css('.import-summary__title').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.import-summary__rows').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.import-private').styles(
      raw: {
        'align-items': 'flex-start',
        'background':
            'linear-gradient(160deg, var(--color-accent-soft) 0%, '
            'var(--color-glass-fill-bottom) 100%)',
        'display': 'flex',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.import-private__text').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
      },
    ),
    css('.import-private__title').styles(raw: {'color': 'var(--color-text)'}),
    css('.import-private__line').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.import-side__note').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'margin': '0',
        'text-align': 'center',
      },
    ),
    css('.import-side__back').styles(
      raw: {
        'align-self': 'center',
        'background': 'none',
        'border': '0',
        'color': 'var(--color-text)',
        'cursor': 'pointer',
        'padding': 'var(--space-xs) var(--space-md)',
      },
    ),
    css('.import-side__back:disabled').styles(
      raw: {'cursor': 'default', 'opacity': '0.5'},
    ),
  ];
}
