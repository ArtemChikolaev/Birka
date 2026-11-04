import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:inbox_jaspr/src/presentation/components/inbox_bits.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// An operation without a category: the box that picks it, its name, its day
/// and account, its amount, and its hint with a «Да» or any category.
class InboxRow extends StatelessComponent {
  /// Creates the row of [item].
  const InboxRow({
    required this.item,
    required this.state,
    required this.thisYear,
    super.key,
  });

  /// The operation.
  final InboxItem item;

  /// The inbox.
  final InboxState state;

  /// The year of today, which dates of it leave out.
  final int thisYear;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<InboxCubit>();
    final transaction = item.transaction;
    final note = transaction.note.trim();
    final name = note.isEmpty ? '—' : note;
    final busy = state.busy.contains(item.id);
    final hint = item.hint;
    final hinted = hint == null
        ? null
        : state.categories.where((it) => it.id == hint.categoryId).firstOrNull;
    final (:options, :nested) = categoryOptions(
      state,
      [kindOf(transaction)],
      first: hinted == null ? t.inbox.category : t.inbox.other,
    );
    return div(
      classes: busy ? 'inbox-row inbox-row--busy' : 'inbox-row',
      [
        BirkaCheckbox(
          checked: state.selected.contains(item.id),
          label: t.inbox.pick(name: name),
          onChanged: (_) => cubit.toggle(item.id),
        ),
        div(classes: 'inbox-row__text', [
          span(classes: 'text-body-strong inbox-row__name', [.text(name)]),
          span(classes: 'text-caption inbox-row__place', [
            .text(placeLabel(transaction, state, thisYear)),
          ]),
        ]),
        span(classes: 'inbox-row__amount', [
          AmountText(
            amountLabel(transaction),
            tone: toneOf(transaction),
            textClass: 'text-body-strong',
          ),
        ]),
        div(classes: 'inbox-row__choice', [
          if (hint != null && hinted != null)
            div(classes: 'inbox-row__hint', [
              div(classes: 'inbox-row__guess', [
                span(classes: 'text-body-strong inbox-row__category', [
                  span(
                    classes: 'inbox-row__dot',
                    styles: Styles(raw: {'background': colorOf(hinted)}),
                    const [],
                  ),
                  .text('${hinted.name} ?'),
                ]),
                span(classes: 'text-caption inbox-row__why', [
                  .text(hintLabel(hint, thisYear: thisYear)),
                ]),
              ]),
              BirkaButton(
                label: t.inbox.yes,
                compact: true,
                onPressed: busy ? null : () => unawaited(cubit.accept(item.id)),
              ),
            ]),
          BirkaSelect<String>(
            label: t.inbox.categoryFor(name: name),
            pill: true,
            options: options,
            nested: nested,
            selected: '',
            quiet: true,
            onChanged: (categoryId) {
              if (categoryId.isNotEmpty && !busy) {
                unawaited(cubit.choose(item.id, categoryId));
              }
            },
          ),
        ]),
      ],
    );
  }

  /// The styles of the row.
  @css
  static List<StyleRule> get styles => [
    css('.inbox-row').styles(
      raw: {
        'align-items': 'center',
        'animation': 'inbox-in var(--duration-base) var(--easing-fade)',
        'display': 'grid',
        'gap': 'var(--space-sm) var(--space-md)',
        'grid-template-columns': 'auto minmax(0, 1fr) auto minmax(0, auto)',
        'padding': 'var(--space-sm) var(--space-md)',
        'transition': 'opacity var(--duration-fast)',
      },
    ),
    css('.inbox-row + .inbox-row').styles(
      raw: {'border-top': '1px solid var(--color-hairline)'},
    ),
    css('.inbox-row--busy').styles(raw: {'opacity': '0.5'}),
    css('.inbox-row__text').styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'min-width': '0'},
    ),
    css('.inbox-row__name').styles(
      raw: {
        'color': 'var(--color-text)',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.inbox-row__place').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.inbox-row__amount').styles(raw: {'text-align': 'end'}),
    css('.inbox-row__choice').styles(
      raw: {
        'align-items': 'flex-end',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'min-width': '0',
      },
    ),
    css('.inbox-row__hint').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'min-width': '0',
      },
    ),
    css('.inbox-row__guess').styles(
      raw: {
        'align-items': 'flex-end',
        'display': 'flex',
        'flex-direction': 'column',
        'min-width': '0',
        'text-align': 'end',
      },
    ),
    css('.inbox-row__category').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text)',
        'display': 'inline-flex',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.inbox-row__dot').styles(
      raw: {
        'border-radius': '50%',
        'flex': 'none',
        'height': '8px',
        'width': '8px',
      },
    ),
    css('.inbox-row__why').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    // A phone puts the choice under the name and the amount.
    css.media(const MediaQuery.raw('(max-width: 640px)'), [
      css('.inbox-row').styles(
        raw: {'grid-template-columns': 'auto minmax(0, 1fr) auto'},
      ),
      css('.inbox-row__choice').styles(
        raw: {'align-items': 'stretch', 'grid-column': '2 / -1'},
      ),
      css('.inbox-row__hint').styles(
        raw: {'justify-content': 'space-between'},
      ),
      css('.inbox-row__guess').styles(
        raw: {'align-items': 'flex-start', 'text-align': 'start'},
      ),
    ]),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.inbox-row').styles(raw: {'animation': 'none'}),
    ]),
  ];
}
