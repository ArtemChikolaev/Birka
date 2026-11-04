import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:inbox_jaspr/src/presentation/components/inbox_bits.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// A transfer between one's own accounts to link: the money that left one
/// account, the money that reached the other, the rate against that of the
/// bank, and the two answers.
class PairCard extends StatelessComponent {
  /// Creates the card of [pair].
  const PairCard({
    required this.pair,
    required this.state,
    required this.thisYear,
    super.key,
  });

  /// The pair.
  final TransferPair pair;

  /// The inbox.
  final InboxState state;

  /// The year of today, which dates of it leave out.
  final int thisYear;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<InboxCubit>();
    final busy = state.busy.contains(pair.key);
    final rate = rateLabel(pair, state.rates);
    return div(classes: 'glass inbox-pair', [
      div(classes: 'inbox-pair__head', [
        const GlyphBadge(
          glyph: BirkaGlyph.transfer,
          color: 'var(--color-accent)',
        ),
        div(classes: 'inbox-pair__text', [
          span(classes: 'text-body-strong inbox-pair__title', [
            .text(t.inbox.pairTitle),
          ]),
          span(classes: 'text-caption inbox-pair__line', [
            .text(t.inbox.pairText),
          ]),
        ]),
      ]),
      div(classes: 'inbox-pair__sides', [
        _side(pair.out),
        const span(classes: 'inbox-pair__arrow', [
          BirkaIcon(BirkaGlyph.chevron),
        ]),
        _side(pair.into),
      ]),
      div(classes: 'inbox-pair__foot', [
        if (rate != null)
          span(classes: 'text-caption inbox-pair__rate', [.text(rate)]),
        div(classes: 'inbox-pair__actions', [
          BirkaButton(
            label: t.inbox.makeTransfer,
            compact: true,
            onPressed: busy ? null : () => unawaited(cubit.makeTransfer(pair)),
          ),
          BirkaButton(
            label: t.inbox.notTransfer,
            quiet: true,
            compact: true,
            onPressed: busy ? null : () => unawaited(cubit.notTransfer(pair)),
          ),
        ]),
      ]),
    ]);
  }

  Component _side(Transaction transaction) {
    final note = transaction.note.trim();
    return div(classes: 'inbox-pair__side', [
      span(classes: 'text-caption inbox-pair__place', [
        .text(placeLabel(transaction, state, thisYear)),
      ]),
      AmountText(amountLabel(transaction), tone: toneOf(transaction)),
      span(classes: 'text-caption inbox-pair__note', [
        .text(
          [
            if (note.isNotEmpty) note,
            if (transaction.importId != null) t.inbox.fromStatement,
          ].join(' · '),
        ),
      ]),
    ]);
  }

  /// The styles of the card.
  @css
  static List<StyleRule> get styles => [
    css('.inbox-pair').styles(
      raw: {
        'animation': 'inbox-in var(--duration-base) var(--easing-fade)',
        'background':
            'linear-gradient(160deg, var(--color-accent-soft) 0%, '
            'var(--color-glass-fill-bottom) 100%)',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
      },
    ),
    css('.inbox-pair__head').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.inbox-pair__text').styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'min-width': '0'},
    ),
    css('.inbox-pair__title').styles(raw: {'color': 'var(--color-text)'}),
    css('.inbox-pair__line').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.inbox-pair__sides').styles(
      raw: {
        'align-items': 'center',
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'minmax(0, 1fr) auto minmax(0, 1fr)',
      },
    ),
    css('.inbox-pair__side').styles(
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
    css('.inbox-pair__place, .inbox-pair__note').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.inbox-pair__arrow').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-accent-soft)',
        'border-radius': '50%',
        'color': 'var(--color-accent)',
        'display': 'flex',
        'height': '32px',
        'justify-content': 'center',
        'width': '32px',
      },
    ),
    css('.inbox-pair__arrow .birka-icon').styles(
      raw: {'height': '16px', 'width': '16px'},
    ),
    css('.inbox-pair__foot').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
      },
    ),
    css('.inbox-pair__rate').styles(raw: {'color': 'var(--color-text)'}),
    css('.inbox-pair__actions').styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
        'margin-left': 'auto',
      },
    ),
    // A phone puts the money that arrived under the money that left.
    css.media(const MediaQuery.raw('(max-width: 640px)'), [
      css('.inbox-pair__sides').styles(
        raw: {'grid-template-columns': 'minmax(0, 1fr)'},
      ),
      css('.inbox-pair__arrow').styles(
        raw: {'justify-self': 'center', 'transform': 'rotate(90deg)'},
      ),
    ]),
  ];
}
