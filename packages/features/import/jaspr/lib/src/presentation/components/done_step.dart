import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:import_common/import_common.dart';
import 'package:import_jaspr/src/presentation/components/import_bits.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// The last step: what went in and what was skipped, the balances against
/// the bank, what waits for a category, and the undo of the whole import.
class DoneStep extends StatelessComponent {
  /// Creates the step of [state].
  const DoneStep({required this.state, required this.inboxHref, super.key});

  /// The import.
  final ImportState state;

  /// The inbox, where what the import leaves waits.
  final String inboxHref;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<ImportCubit>();
    final plan = state.plan!;
    final statement = plan.statement;
    final added = plan.added.toList();
    if (state.undone) {
      return div(classes: 'glass import-done', [
        div(classes: 'import-done__head', [
          const span(classes: 'import-done__mark import-done__mark--undone', [
            BirkaIcon(BirkaGlyph.close),
          ]),
          div(classes: 'import-done__text', [
            h2(classes: 'text-heading import-done__title', [
              .text(t.imports.undoneTitle),
            ]),
            p(classes: 'text-body import-done__line', [
              .text(t.imports.undoneText),
            ]),
          ]),
        ]),
      ]);
    }
    final format = state.layout?.format;
    final accounts = _accountsOf(plan);
    final from = statement.from;
    final to = statement.to;
    return div(classes: 'import-stack', [
      div(classes: 'glass import-done', [
        div(classes: 'import-done__head', [
          const span(classes: 'import-done__mark', [
            BirkaIcon(BirkaGlyph.check),
          ]),
          div(classes: 'import-done__text', [
            h2(classes: 'text-heading import-done__title', [
              .text(
                t.imports.doneTitle(
                  n: added.length,
                  count: formatCount(added.length),
                ),
              ),
            ]),
            if (from != null && to != null)
              p(classes: 'text-body import-done__line', [
                .text(
                  t.imports.doneWhere(
                    format: format == null
                        ? state.fileName ?? ''
                        : formatLabel(format),
                    period: periodLabel(from, to),
                    accounts: accounts.join(', '),
                  ),
                ),
              ]),
          ]),
        ]),
        div(classes: 'import-done__tiles', [
          _tile(
            t.imports.doneIncome,
            AmountText(
              moneyLine([
                for (final operation in added)
                  if (operation.kind == TransactionKind.income)
                    operation.amount,
              ], signed: true),
              tone: AmountTone.positive,
            ),
          ),
          _tile(
            t.imports.doneSpent,
            AmountText(
              moneyLine([
                for (final operation in added) ...[
                  if (operation.kind == TransactionKind.expense)
                    -operation.amount,
                  if (operation.fee case final fee?) -fee,
                ],
              ]),
            ),
          ),
          _tile(
            t.imports.doneSkipped,
            span(classes: 'text-amount', [
              .text(formatCount(plan.copies.length)),
            ]),
          ),
        ]),
        for (final source in statement.accounts) ?_balance(plan, source),
      ]),
      if (plan.unsorted > 0)
        a(classes: 'glass import-note import-note--link', href: inboxHref, [
          const GlyphBadge(
            glyph: BirkaGlyph.list,
            color: 'var(--color-palette-amber)',
          ),
          div(classes: 'import-note__text', [
            span(classes: 'text-body-strong import-note__title', [
              .text(
                t.imports.unsortedTitle(
                  n: plan.unsorted,
                  count: formatCount(plan.unsorted),
                ),
              ),
            ]),
            span(classes: 'text-caption import-note__line', [
              .text(t.imports.unsortedText),
            ]),
          ]),
          const span(classes: 'import-note__chevron', [
            BirkaIcon(BirkaGlyph.chevron),
          ]),
        ]),
      div(classes: 'glass import-note import-note--undo', [
        div(classes: 'import-note__text', [
          span(classes: 'text-body-strong import-note__title', [
            .text(t.imports.undoTitle),
          ]),
          span(classes: 'text-caption import-note__line', [
            .text(
              t.imports.undoText(
                n: added.length,
                count: formatCount(added.length),
              ),
            ),
          ]),
        ]),
        BirkaButton(
          label: t.imports.undoImport,
          danger: true,
          compact: true,
          onPressed: () => unawaited(cubit.undo()),
        ),
      ]),
    ]);
  }

  /// The names of the accounts that the import went into.
  List<String> _accountsOf(ImportPlan plan) => [
    for (final choice in plan.choices.accounts.values)
      switch (choice) {
        IntoAccount(:final account) => account.name,
        NewAccount(:final name) => name,
        LeaveOut() => null,
      },
  ].nonNulls.toSet().toList();

  Component _tile(String label, Component value) {
    return div(classes: 'import-done__tile', [
      span(classes: 'text-caption import-done__label', [.text(label)]),
      value,
    ]);
  }

  /// The balance of [source] after the import, and whether it is that of
  /// the bank.
  Component? _balance(ImportPlan plan, SourceAccount source) {
    final after = plan.balances[source.key];
    if (after == null) return null;
    final bank = bankBalance(source, after);
    final name = switch (plan.choices.accounts[source.key]) {
      IntoAccount(:final account) => account.name,
      NewAccount(:final name) => name,
      _ => null,
    };
    return div(classes: 'import-done__tile import-done__tile--wide', [
      span(classes: 'text-caption import-done__label', [
        .text(
          [t.imports.doneBalance, ?name].join(' · '),
        ),
      ]),
      div(classes: 'import-done__balance', [
        AmountText(formatMoney(after)),
        if (bank == after)
          span(classes: 'text-caption import-done__same', [
            .text(t.imports.asInBank),
          ]),
      ]),
    ]);
  }

  /// The styles of the step.
  @css
  static List<StyleRule> get styles => [
    css('.import-done').styles(
      raw: {
        'background':
            'linear-gradient(160deg, var(--color-accent-soft) 0%, '
            'var(--color-glass-fill-bottom) 100%)',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
        'padding': 'var(--space-lg)',
      },
    ),
    css('.import-done__head').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-md)',
      },
    ),
    css('.import-done__mark').styles(
      raw: {
        'align-items': 'center',
        'animation': 'import-pop var(--duration-spring) var(--easing-spring)',
        'background': 'var(--color-accent)',
        'border-radius': '50%',
        'color': 'var(--color-on-accent)',
        'display': 'flex',
        'flex': 'none',
        'height': '56px',
        'justify-content': 'center',
        'width': '56px',
      },
    ),
    css('.import-done__mark--undone').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'color': 'var(--color-text-muted)',
      },
    ),
    css('.import-done__mark .birka-icon').styles(
      raw: {'height': '26px', 'width': '26px'},
    ),
    css.keyframes('import-pop', {
      'from': const Styles(raw: {'transform': 'scale(0.6)', 'opacity': '0'}),
    }),
    css('.import-done__text').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
      },
    ),
    css('.import-done__title').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.import-done__line').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.import-done__tiles').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'repeat(auto-fit, minmax(160px, 1fr))',
      },
    ),
    css('.import-done__tile').styles(
      raw: {
        'background': 'var(--color-surface)',
        'border-radius': 'var(--radius-md)',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
        'padding': 'var(--space-sm) var(--space-md)',
      },
    ),
    css('.import-done__label').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.import-done__balance').styles(
      raw: {
        'align-items': 'baseline',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.import-done__same').styles(
      raw: {
        'color': 'var(--color-accent)',
        'font-weight': 'var(--font-weight-semibold)',
      },
    ),
    css('.import-note').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-md)',
      },
    ),
    css('.import-note__text').styles(
      raw: {
        'display': 'flex',
        'flex': '1 1 260px',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
      },
    ),
    css('.import-note__title').styles(raw: {'color': 'var(--color-text)'}),
    css('.import-note--link').styles(
      raw: {'color': 'inherit', 'text-decoration': 'none'},
    ),
    css('.import-note__chevron').styles(
      raw: {'color': 'var(--color-text-subtle)', 'display': 'flex'},
    ),
    css('.import-note__chevron .birka-icon').styles(
      raw: {'height': '18px', 'width': '18px'},
    ),
    css('.import-note__line').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.import-done__mark').styles(raw: {'animation': 'none'}),
    ]),
  ];
}
