import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/src/presentation/components/back_header.dart';
import 'package:transactions_jaspr/src/presentation/components/operation_day_group.dart';

/// One account: what it holds, how that changed and what happened on it.
///
/// It needs an [AccountCubit] above it.
class AccountPage extends StatelessComponent {
  /// Creates the page.
  const AccountPage({
    required this.onClose,
    required this.editHref,
    required this.hrefOf,
    super.key,
  });

  /// Called by the way back.
  final VoidCallback onClose;

  /// Where the account opens to be changed.
  final String editHref;

  /// Where the operation with this id opens.
  final String Function(String id) hrefOf;

  @override
  Component build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, state) {
        return BirkaColumn(
          children: [
            _header(state),
            ...switch (state) {
              AccountState(status: AccountStatus.failed) => [
                GlassNotice(
                  text: t.transactions.failedToReadOperations,
                  actions: [
                    BirkaButton(
                      label: t.app.retry,
                      onPressed: () =>
                          unawaited(context.read<AccountCubit>().retry()),
                    ),
                  ],
                ),
              ],
              AccountState(status: AccountStatus.gone) => [
                GlassNotice(text: t.transactions.accountGone),
              ],
              AccountState(status: AccountStatus.ready, :final account?) => [
                _summary(context, state, account),
                _operations(state, accountId: account.account.id),
              ],
              _ => const <Component>[],
            },
          ],
        );
      },
    );
  }

  Component _header(AccountState state) {
    final ready = state.status == AccountStatus.ready && state.account != null;
    return BackHeader(
      label: t.transactions.account,
      onBack: onClose,
      trailing: ready
          ? GlassIconButton(
              glyph: BirkaGlyph.dots,
              label: t.transactions.edit,
              href: editHref,
            )
          : null,
    );
  }

  /// The card of the account, what the period changed, its chart and the
  /// switch of periods.
  Component _summary(
    BuildContext context,
    AccountState state,
    AccountBalance account,
  ) {
    final cubit = context.read<AccountCubit>();
    final AccountBalance(account: details, :balance) = account;
    final change = state.change;
    return div(classes: 'account__summary', [
      AccountCard(
        art: CardArt.values.byName(details.art.name),
        name: details.name,
        subtitle: accountLine(
          currency: details.currency.code,
          type: details.type.name,
          lastDigits: details.lastDigits,
        ),
        amount: formatMoney(balance),
      ),
      if (change != null && !change.isZero)
        div(classes: 'account__change', [
          BirkaChangePill(
            label: signedAmountLabel(change),
            rise: change.isPositive,
          ),
          span(classes: 'text-body account__caption', [
            .text(
              chartPeriodCaption(state.period.name, month: state.today.month),
            ),
          ]),
        ]),
      div(classes: 'account__chart', [
        BirkaLineChart(
          values: [for (final value in state.history) value.toDouble()],
          label: t.transactions.balanceChart,
        ),
        div(classes: 'account__periods', [
          for (final period in ChartPeriod.values)
            BirkaChip(
              label: chartPeriodLabel(period.name),
              selected: period == state.period,
              compact: true,
              onTap: () => cubit.periodChanged(period),
            ),
        ]),
      ]),
    ]);
  }

  Component _operations(AccountState state, {required String accountId}) {
    return section(classes: 'account__operations', [
      SectionLabel(t.app.operations),
      if (state.operations.isEmpty)
        GlassNotice(text: t.transactions.noAccountOperations)
      else
        div(classes: 'account__days', [
          for (final day in state.days)
            OperationDayGroup(
              day: day,
              today: state.today,
              hrefOf: hrefOf,
              accountId: accountId,
            ),
        ]),
    ]);
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.account__summary').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
      },
    ),
    css('.account__change').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.account__caption').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.account__chart').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.account__periods').styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': 'var(--space-xs)'},
    ),
    css('.account__operations').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.account__days').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
  ];
}
