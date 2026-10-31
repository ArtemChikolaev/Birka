import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_jaspr/src/presentation/components/account_row.dart';
import 'package:accounts_jaspr/src/presentation/components/card_art_of.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The list of accounts: the main one as a card, the capital and the rest.
///
/// It needs an [AccountsCubit] above it.
class AccountsPage extends StatelessComponent {
  /// Creates the page.
  const AccountsPage({
    required this.addHref,
    required this.hrefOf,
    this.note,
    super.key,
  });

  /// Where the buttons that add an account lead.
  final String addHref;

  /// Where the account with this id opens.
  final String Function(String id) hrefOf;

  /// A quiet line under the list, such as where the data lives.
  final String? note;

  @override
  Component build(BuildContext context) {
    final note = this.note;
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) => BirkaColumn(
        children: [
          GlassPageHeader(
            title: t.accounts.title,
            trailing: GlassIconButton(
              glyph: BirkaGlyph.plus,
              label: t.accounts.add,
              href: addHref,
            ),
          ),
          ...switch (state) {
            AccountsLoading() => const <Component>[],
            AccountsFailed() => [
              GlassNotice(
                text: t.accounts.failed,
                actions: [
                  BirkaButton(
                    label: t.app.retry,
                    onPressed: () => context.read<AccountsCubit>().retry(),
                  ),
                ],
              ),
            ],
            AccountsLoaded(:final overview) =>
              overview.active.isEmpty && overview.archived.isEmpty
                  ? _empty()
                  : _content(overview),
          },
          if (note != null && state is AccountsLoaded)
            p(classes: 'text-caption accounts__note', [.text(note)]),
        ],
      ),
    );
  }

  List<Component> _empty() {
    return [
      GlassNotice(
        title: t.accounts.emptyTitle,
        text: t.accounts.emptyHint,
        actions: [BirkaButton(label: t.accounts.add, href: addHref)],
      ),
    ];
  }

  List<Component> _content(AccountsOverview overview) {
    final first = overview.active.firstOrNull;
    return [
      if (overview.totals.isNotEmpty) _Capital(overview: overview),
      if (first != null) ...[
        AccountCard(
          art: cardArtOf(first.account.art),
          name: first.account.name,
          subtitle: accountSubtitle(
            currency: first.account.currency,
            type: first.account.type,
            lastDigits: first.account.lastDigits,
          ),
          amount: formatMoney(first.balance),
          href: hrefOf(first.account.id),
        ),
        GlassListGroup(
          children: [
            for (final (index, row) in overview.active.indexed)
              AccountRow(
                row: row,
                main: index == 0,
                href: hrefOf(row.account.id),
              ),
          ],
        ),
      ],
      if (overview.archived.isNotEmpty)
        div(classes: 'accounts__archive', [
          SectionLabel(t.accounts.archive),
          GlassListGroup(
            children: [
              for (final row in overview.archived)
                AccountRow(row: row, href: hrefOf(row.account.id)),
            ],
          ),
        ]),
    ];
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.accounts__capital').styles(
      raw: {'color': 'var(--color-text-muted)', 'margin': '0'},
    ),
    css('.accounts__capital strong').styles(
      raw: {'color': 'var(--color-text)'},
    ),
    css('.accounts__archive').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.accounts__note').styles(
      raw: {'color': 'var(--color-text-subtle)', 'margin': '0'},
    ),
  ];
}

/// `Капитал 1 070 800 ₽ и 2 140 € в 4 счетах`. Amounts in different
/// currencies stay apart until exchange rates can add them up.
class _Capital extends StatelessComponent {
  const _Capital({required this.overview});

  final AccountsOverview overview;

  @override
  Component build(BuildContext context) {
    return p(classes: 'accounts__capital', [
      .text('${t.accounts.capital} '),
      for (final (index, total) in overview.totals.indexed) ...[
        if (index > 0) .text(' ${t.accounts.and} '),
        strong(classes: 'text-body-strong', [
          .text(HiddenAmounts.mask(context, formatMoney(total))),
        ]),
      ],
      .text(' ${t.accounts.inAccounts(n: overview.countedAccounts)}'),
    ]);
  }
}
