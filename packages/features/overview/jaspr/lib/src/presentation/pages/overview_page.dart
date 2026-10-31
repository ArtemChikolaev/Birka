import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:overview_common/overview_common.dart';

/// The first screen: the capital and its history, the accounts and what the
/// month has cost.
///
/// It needs an [OverviewCubit] above it.
class OverviewPage extends StatelessComponent {
  /// Creates the page.
  const OverviewPage({
    required this.addAccountHref,
    required this.accountsHref,
    required this.hrefOfAccount,
    this.note,
    super.key,
  });

  /// Where the first account is added.
  final String addAccountHref;

  /// Where all the accounts stand.
  final String accountsHref;

  /// Where the account with this id opens.
  final String Function(String id) hrefOfAccount;

  /// A quiet line under the page, such as where the data lives.
  final String? note;

  @override
  Component build(BuildContext context) {
    final note = this.note;
    return BlocBuilder<OverviewCubit, OverviewState>(
      builder: (context, state) => BirkaColumn(
        children: [
          _header(context, state),
          ...switch (state.status) {
            OverviewStatus.loading => const <Component>[],
            OverviewStatus.failed => [
              GlassNotice(
                text: t.overview.failed,
                actions: [
                  BirkaButton(
                    label: t.app.retry,
                    onPressed: () =>
                        unawaited(context.read<OverviewCubit>().retry()),
                  ),
                ],
              ),
            ],
            OverviewStatus.ready when state.accounts.isEmpty => [
              GlassNotice(
                title: t.accounts.emptyTitle,
                text: t.accounts.emptyHint,
                actions: [
                  BirkaButton(label: t.accounts.add, href: addAccountHref),
                ],
              ),
            ],
            OverviewStatus.ready => [
              if (state.main != null) _capital(context, state),
              _accounts(state.accounts),
              _spending(state.spending, today: state.today),
            ],
          },
          if (note != null && state.status == OverviewStatus.ready)
            p(classes: 'text-caption overview__note', [.text(note)]),
        ],
      ),
    );
  }

  Component _header(BuildContext context, OverviewState state) {
    final hidden = HiddenAmounts.of(context);
    return GlassPageHeader(
      title: monthTitle(state.today),
      trailing: GlassIconButton(
        glyph: hidden ? BirkaGlyph.hidden : BirkaGlyph.eye,
        label: hidden ? t.overview.showAmounts : t.overview.hideAmounts,
        onPressed: () => HiddenAmounts.toggle(context),
      ),
    );
  }

  /// `1 284 560 ₽`, the amounts in other currencies, the change, the chart and
  /// how far back it looks.
  Component _capital(BuildContext context, OverviewState state) {
    final cubit = context.read<OverviewCubit>();
    final change = state.change;
    final others = state.others;
    return div(classes: 'overview__capital', [
      div(classes: 'overview__figures', [
        div(classes: 'overview__label', [
          SectionLabel(capitalLabel(state.capital.length)),
        ]),
        AmountText(formatMoney(state.main!), textClass: 'text-display'),
        if (others.isNotEmpty)
          AmountText(
            others.map(formatMoney).join(' · '),
            tone: AmountTone.muted,
            textClass: 'text-body-strong',
          ),
        if (change != null && !change.isZero)
          div(classes: 'overview__change', [
            _changePill(change),
            span(classes: 'text-body overview__caption', [
              .text(changeCaption(state.period, today: state.today)),
            ]),
          ]),
      ]),
      BirkaLineChart(
        values: [for (final value in state.history) value.toDouble()],
        label: t.overview.chart,
      ),
      div(classes: 'overview__periods', [
        for (final period in OverviewPeriod.values)
          BirkaChip(
            label: periodLabel(period),
            selected: period == state.period,
            compact: true,
            onTap: () => cubit.periodChanged(period),
          ),
      ]),
    ]);
  }

  /// A pill with the arrow and the amount of a change.
  Component _changePill(Money change) {
    final rise = change.isPositive;
    return span(
      classes: rise
          ? 'overview__pill overview__pill--rise'
          : 'overview__pill overview__pill--fall',
      [
        BirkaIcon(rise ? BirkaGlyph.rise : BirkaGlyph.fall),
        AmountText(
          changeLabel(change),
          tone: rise ? AmountTone.positive : AmountTone.negative,
          textClass: 'text-body-strong',
        ),
      ],
    );
  }

  Component _accounts(List<AccountBalance> accounts) {
    return section(classes: 'overview__accounts', [
      div(classes: 'overview__accounts-heading', [
        SectionLabel(t.overview.accounts),
        a(classes: 'text-label overview__all', href: accountsHref, [
          .text(t.overview.allAccounts(n: accounts.length)),
        ]),
      ]),
      if (accounts.length == 1)
        _card(accounts.single)
      else
        div(classes: 'overview__cards', [
          for (final row in accounts)
            div(key: ValueKey(row.account.id), classes: 'overview__card', [
              _card(row),
            ]),
        ]),
    ]);
  }

  Component _card(AccountBalance row) {
    final AccountBalance(:account, :balance) = row;
    return AccountCard(
      compact: true,
      art: CardArt.values.byName(account.art.name),
      name: account.name,
      subtitle: accountLine(
        currency: balance.currency.code,
        type: account.type.name,
        lastDigits: account.lastDigits,
      ),
      amount: formatMoney(balance),
      href: hrefOfAccount(account.id),
    );
  }

  /// The ring of the month, its total and its biggest categories.
  Component _spending(Spending spending, {required CivilDate today}) {
    final title = div(classes: 'overview__label', [
      SectionLabel(spendingTitle(today)),
    ]);
    final total = spending.total;
    if (total == null) {
      return GlassSurface(
        child: div(classes: 'overview__month', [
          title,
          span(classes: 'text-body overview__caption', [
            .text(t.overview.noSpending),
          ]),
        ]),
      );
    }
    return GlassSurface(
      child: div(classes: 'overview__spending', [
        BirkaRing(
          label: t.overview.ring,
          slices: [
            for (final CategoryTotal(:category, total: amount)
                in spending.categories)
              RingSlice(amount.minorUnits.toDouble(), _colorOf(category)),
          ],
        ),
        div(classes: 'overview__month', [
          title,
          AmountText(formatMoney(-total), textClass: 'text-heading'),
          for (final row in spending.top) _categoryLine(row),
          if (spending.others.isNotEmpty)
            AmountText(
              spending.others.map(formatMoney).join(' · '),
              tone: AmountTone.muted,
              textClass: 'text-caption',
            ),
        ]),
      ]),
    );
  }

  static String _colorOf(Category category) =>
      category.color ?? 'var(--color-text-subtle)';

  Component _categoryLine(CategoryTotal row) {
    return div(classes: 'overview__category', [
      span(
        classes: 'overview__dot',
        styles: Styles(raw: {'background': _colorOf(row.category)}),
        const [],
      ),
      span(classes: 'text-caption overview__category-name', [
        .text(row.category.name),
      ]),
      AmountText(formatMoney(row.total), textClass: 'text-caption'),
    ]);
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.overview__capital').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.overview__figures').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
      },
    ),
    css('.overview__figures .amount').styles(
      raw: {'overflow-wrap': 'anywhere', 'white-space': 'normal'},
    ),
    css('.overview__label').styles(raw: {'color': 'var(--color-text-muted)'}),
    css('.overview__change').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
        'margin-top': 'var(--space-xxs)',
      },
    ),
    css('.overview__pill').styles(
      raw: {
        'align-items': 'center',
        'border-radius': 'var(--radius-pill)',
        'display': 'inline-flex',
        'gap': 'var(--space-xxs)',
        'max-width': '100%',
        'padding': 'var(--space-xxs) var(--space-sm)',
      },
    ),
    css('.overview__pill .birka-icon').styles(
      raw: {'height': '14px', 'width': '14px'},
    ),
    css('.overview__pill--rise').styles(
      raw: {
        'background':
            'color-mix(in srgb, var(--color-positive) 16%, transparent)',
        'color': 'var(--color-positive)',
      },
    ),
    css('.overview__pill--fall').styles(
      raw: {
        'background':
            'color-mix(in srgb, var(--color-negative) 16%, transparent)',
        'color': 'var(--color-negative)',
      },
    ),
    css('.overview__caption').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.overview__periods').styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': 'var(--space-xs)'},
    ),
    css('.overview__accounts').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.overview__accounts-heading').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'justify-content': 'space-between',
      },
    ),
    css('.overview__all').styles(
      raw: {'color': 'var(--color-text-muted)', 'text-decoration': 'none'},
    ),
    // The edge of the next card says that the row goes on. It runs to the
    // edges of the page, as in the app.
    css('.overview__cards').styles(
      raw: {
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'margin': '0 calc(-1 * var(--space-lg))',
        'overflow-x': 'auto',
        'padding': '0 var(--space-lg)',
        'scroll-padding': '0 var(--space-lg)',
        'scroll-snap-type': 'x proximity',
        'scrollbar-width': 'none',
      },
    ),
    css('.overview__cards::-webkit-scrollbar').styles(raw: {'display': 'none'}),
    // Beside a wide page the row has no edge of the screen to run to.
    css.media(const MediaQuery.raw('(min-width: 521px)'), [
      css('.overview__cards').styles(
        raw: {
          'mask-image':
              'linear-gradient(to right, transparent, black var(--space-lg), '
              'black calc(100% - var(--space-lg)), transparent)',
        },
      ),
    ]),
    css('.overview__card').styles(
      raw: {
        'flex': '0 0 236px',
        'min-width': '0',
        'scroll-snap-align': 'start',
      },
    ),
    css('.overview__spending').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-md)',
      },
    ),
    css('.overview__month').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
      },
    ),
    css('.overview__month .amount').styles(
      raw: {'overflow-wrap': 'anywhere', 'white-space': 'normal'},
    ),
    css('.overview__category').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.overview__dot').styles(
      raw: {
        'border-radius': '50%',
        'flex': 'none',
        'height': '8px',
        'width': '8px',
      },
    ),
    css('.overview__category-name').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'flex': '1',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.overview__note').styles(
      raw: {'color': 'var(--color-text-subtle)', 'margin': '0'},
    ),
  ];
}
