import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/src/presentation/components/big_amount.dart';
import 'package:transactions_jaspr/src/presentation/components/operation_badge.dart';
import 'package:transactions_jaspr/src/presentation/components/operation_row.dart';

/// The card of one operation, with what can be done to it.
///
/// It needs an [OperationCubit] above it.
class OperationPage extends StatefulComponent {
  /// Creates the page.
  const OperationPage({
    required this.onClose,
    required this.editHref,
    required this.repeatHref,
    super.key,
  });

  /// Called by the way back, and when the operation is gone.
  final VoidCallback onClose;

  /// Where the operation opens to be changed.
  final String editHref;

  /// Where the operation opens to be recorded once more.
  final String repeatHref;

  @override
  State<OperationPage> createState() => _OperationPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.operation__header').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-muted)',
        'display': 'grid',
        'gap': 'var(--space-xs)',
        'grid-template-columns': '1fr auto 1fr',
      },
    ),
    css('.operation__edit').styles(
      raw: {'display': 'flex', 'justify-content': 'flex-end'},
    ),
    css('.operation__summary').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'text-align': 'center',
      },
    ),
    css('.operation__summary .amount').styles(
      raw: {'overflow-wrap': 'anywhere', 'white-space': 'normal'},
    ),
    css('.operation__title').styles(
      raw: {'margin': 'var(--space-xs) 0 0', 'overflow-wrap': 'anywhere'},
    ),
    css('.operation__when').styles(
      raw: {'color': 'var(--color-text-muted)', 'margin': '0'},
    ),
    css('.operation__fact').styles(
      raw: {
        'display': 'flex',
        'gap': 'var(--space-md)',
        'justify-content': 'space-between',
        'padding': 'var(--space-md)',
        'position': 'relative',
      },
    ),
    css('.operation__fact + .operation__fact::before').styles(
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
    css('.operation__fact-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.operation__fact-value').styles(
      raw: {'overflow-wrap': 'anywhere', 'text-align': 'right'},
    ),
    css('.operation__failure').styles(
      raw: {
        'color': 'var(--color-negative)',
        'margin': '0',
        'text-align': 'center',
      },
    ),
    css('.operation__actions').styles(
      raw: {'display': 'flex', 'gap': 'var(--space-sm)'},
    ),
    css('.glass.operation__action').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text)',
        'cursor': 'pointer',
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'text-decoration': 'none',
      },
    ),
    css('.glass.operation__action--danger').styles(
      raw: {'color': 'var(--color-negative)'},
    ),
  ];
}

class _OperationPageState extends State<OperationPage> {
  /// Whether the card asks if the operation should go.
  var _confirming = false;

  @override
  Component build(BuildContext context) {
    return BlocConsumer<OperationCubit, OperationState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (_, state) {
        if (state.status == OperationStatus.gone) component.onClose();
      },
      builder: (context, state) => BirkaColumn(
        children: [
          _header(state),
          ...switch (state) {
            OperationState(status: OperationStatus.failed) => [
              GlassNotice(
                text: t.transactions.failedToReadOperations,
                actions: [
                  BirkaButton(
                    label: t.app.retry,
                    onPressed: () =>
                        unawaited(context.read<OperationCubit>().retry()),
                  ),
                ],
              ),
            ],
            OperationState(:final operation?) => [
              _summary(operation, today: state.today),
              _facts(operation, today: state.today),
              if (state.deleteFailed)
                p(classes: 'text-caption operation__failure', [
                  .text(t.transactions.failedToDelete),
                ]),
              if (_confirming)
                _confirmation(context, operation)
              else
                _actions(operation),
            ],
            _ => const <Component>[],
          },
        ],
      ),
    );
  }

  Component _header(OperationState state) {
    return div(classes: 'operation__header', [
      GlassIconButton(
        glyph: BirkaGlyph.back,
        label: t.transactions.back,
        onPressed: component.onClose,
      ),
      SectionLabel(t.transactions.operation),
      div(classes: 'operation__edit', [
        if (state.operation?.canChange ?? false)
          BirkaChip(
            label: t.transactions.edit,
            selected: false,
            href: component.editHref,
          ),
      ]),
    ]);
  }

  /// The picture, the amount, the title and when it happened.
  Component _summary(Operation operation, {required CivilDate today}) {
    final at = operation.transaction.occurredAt;
    final day = dayHeading(operation.day, today: today);
    final received = operation.received;
    final twoAmounts =
        received != null && received.currency != operation.amount.currency;
    return div(classes: 'operation__summary', [
      OperationBadge(operation, size: 72),
      BigAmount(
        twoAmounts
            ? '${operationAmount(operation)} → ${formatMoney(received)}'
            : operationAmount(operation),
        tone: operationTone(operation),
      ),
      h1(classes: 'text-heading operation__title', [
        .text(operationTitle(operation)),
      ]),
      p(classes: 'text-body operation__when', [
        .text(
          [
            if (at == null) day else '$day, ${timeLabel(at)}',
            sourceLabel(operation.transaction.source),
          ].join(' · '),
        ),
      ]),
    ]);
  }

  /// The accounts, the category and the date. A note is the title already.
  Component _facts(Operation operation, {required CivilDate today}) {
    final category = operation.category;
    final account = operation.account;
    final toAccount = operation.toAccount;
    final transfer = operation.kind == TransactionKind.transfer;
    return GlassListGroup(
      children: [
        if (account != null)
          _fact(
            transfer ? t.transactions.from : t.transactions.account,
            _accountLine(account),
          ),
        if (toAccount != null)
          _fact(t.transactions.to, _accountLine(toAccount)),
        if (category != null) _fact(t.transactions.category, category.name),
        _fact(t.transactions.date, dayLabel(operation.day, today: today)),
      ],
    );
  }

  static String _accountLine(Account account) {
    final digits = account.lastDigits;
    return digits == null ? account.name : '${account.name} · •• $digits';
  }

  Component _fact(String label, String value) {
    return div(classes: 'operation__fact', [
      span(classes: 'text-body operation__fact-label', [.text(label)]),
      span(classes: 'text-body-strong operation__fact-value', [.text(value)]),
    ]);
  }

  Component _actions(Operation operation) {
    return div(classes: 'operation__actions', [
      if (operation.canChange)
        a(
          classes: 'glass text-body-strong operation__action',
          href: component.repeatHref,
          [
            const BirkaIcon(BirkaGlyph.copy),
            .text(t.transactions.repeat),
          ],
        ),
      button(
        classes:
            'glass text-body-strong operation__action '
            'operation__action--danger',
        type: ButtonType.button,
        onClick: () => setState(() => _confirming = true),
        [
          const BirkaIcon(BirkaGlyph.trash),
          .text(t.transactions.delete),
        ],
      ),
    ]);
  }

  Component _confirmation(BuildContext context, Operation operation) {
    return GlassNotice(
      title: t.transactions.deleteTitle,
      text:
          '${HiddenAmounts.mask(context, operationAmount(operation))} · '
          '${operationTitle(operation)}',
      actions: [
        BirkaButton(
          label: t.transactions.delete,
          danger: true,
          onPressed: () {
            setState(() => _confirming = false);
            unawaited(context.read<OperationCubit>().delete());
          },
        ),
        BirkaButton(
          label: t.transactions.cancel,
          quiet: true,
          onPressed: () => setState(() => _confirming = false),
        ),
      ],
    );
  }
}
