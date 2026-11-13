import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/src/presentation/components/operation_day_group.dart';

/// One account: what it holds, how that changed and what happened on it. A
/// [wide] page has the card of the account and its change at the side.
///
/// It needs an [AccountCubit] above it.
class AccountPage extends StatelessComponent {
  /// Creates the page.
  const AccountPage({
    required this.onClose,
    required this.editHref,
    required this.hrefOf,
    this.wide = false,
    super.key,
  });

  /// Called by the way back.
  final VoidCallback onClose;

  /// Where the account opens to be changed.
  final String editHref;

  /// Where the operation with this id opens.
  final String Function(String id) hrefOf;

  /// Whether the page is wide.
  final bool wide;

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
              AccountState(status: AccountStatus.ready, :final account?)
                  when wide =>
                [
                  BirkaSplit(
                    asideWidth: 380,
                    main: [
                      _chart(context, state),
                      _operations(state, accountId: account.account.id),
                    ],
                    aside: [_card(account), ?_change(state)],
                  ),
                ],
              AccountState(status: AccountStatus.ready, :final account?) => [
                div(classes: 'account__summary', [
                  _card(account),
                  ?_change(state),
                  _chart(context, state),
                ]),
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
      backLabel: t.transactions.back,
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

  /// The card of the account.
  Component _card(AccountBalance account) {
    final AccountBalance(account: details, :balance) = account;
    return AccountCard(
      art: CardArt.values.byName(details.art.name),
      name: details.name,
      subtitle: accountLine(
        currency: details.currency.code,
        type: details.type.name,
        lastDigits: details.lastDigits,
      ),
      amount: formatMoney(balance),
    );
  }

  /// What the period changed, unless nothing.
  Component? _change(AccountState state) {
    final change = state.change;
    if (change == null || change.isZero) return null;
    return div(classes: 'account__change', [
      BirkaChangePill(
        label: signedAmountLabel(change),
        rise: change.isPositive,
      ),
      span(classes: 'text-body account__caption', [
        .text(chartPeriodCaption(state.period.name, month: state.today.month)),
      ]),
    ]);
  }

  /// The chart of the balance and the switch of periods.
  Component _chart(BuildContext context, AccountState state) {
    final cubit = context.read<AccountCubit>();
    return div(classes: 'account__chart', [
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
