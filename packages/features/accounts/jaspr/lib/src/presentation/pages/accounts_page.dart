import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_jaspr/src/presentation/components/account_row.dart';
import 'package:accounts_jaspr/src/presentation/components/card_art_of.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The list of accounts: the main one as a card, the capital and the rest. A
/// [wide] page shows every account as a card, two in a row, with the capital
/// at the side.
///
/// It needs an [AccountsCubit] above it.
class AccountsPage extends StatelessComponent {
  /// Creates the page.
  const AccountsPage({
    required this.addHref,
    required this.hrefOf,
    this.note,
    this.wide = false,
    super.key,
  });

  /// Where the buttons that add an account lead.
  final String addHref;

  /// Where the account with this id opens.
  final String Function(String id) hrefOf;

  /// A quiet line under the list, such as where the data lives.
  final String? note;

  /// Whether the page is wide.
  final bool wide;

  @override
  Component build(BuildContext context) {
    final note = this.note;
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        // A wide page with accounts says where the data lives at its side.
        final side =
            wide && state is AccountsLoaded && state.overview.active.isNotEmpty;
        return BirkaColumn(
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
              AccountsLoaded(:final overview)
                  when wide && overview.active.isNotEmpty =>
                [_wide(overview)],
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
            if (note != null && state is AccountsLoaded && !side)
              p(classes: 'text-caption accounts__note', [.text(note)]),
          ],
        );
      },
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

  /// Every account as a card, two in a row, with the capital and the way to a
  /// new account at the side.
  Component _wide(AccountsOverview overview) {
    final note = this.note;
    return BirkaSplit(
      asideWidth: 340,
      main: [
        div(classes: 'accounts__cards', [
          for (final row in overview.active) _card(row),
        ]),
        ?_archive(overview),
      ],
      aside: [
        GlassSurface(
          child: div(classes: 'accounts__side', [
            if (overview.totals.isNotEmpty) _Capital(overview: overview),
            BirkaButton(label: t.accounts.form.newTitle, href: addHref),
          ]),
        ),
        if (note != null)
          p(classes: 'text-caption accounts__note', [.text(note)]),
      ],
    );
  }

  Component _card(AccountBalance row) {
    final account = row.account;
    return AccountCard(
      art: cardArtOf(account.art),
      name: account.name,
      subtitle: accountSubtitle(
        currency: account.currency,
        type: account.type,
        lastDigits: account.lastDigits,
      ),
      amount: formatMoney(row.balance),
      href: hrefOf(account.id),
    );
  }

  Component? _archive(AccountsOverview overview) {
    if (overview.archived.isEmpty) return null;
    return div(classes: 'accounts__archive', [
      SectionLabel(t.accounts.archive),
      GlassListGroup(
        children: [
          for (final row in overview.archived)
            AccountRow(row: row, href: hrefOf(row.account.id)),
        ],
      ),
    ]);
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
      ?_archive(overview),
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
    css('.accounts__cards').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-md)',
        'grid-template-columns': 'repeat(2, minmax(0, 1fr))',
      },
    ),
    css('.accounts__side').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
      },
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
