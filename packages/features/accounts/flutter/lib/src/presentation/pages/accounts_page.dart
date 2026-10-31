import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_flutter/src/presentation/widgets/account_hero_card.dart';
import 'package:accounts_flutter/src/presentation/widgets/account_labels.dart';
import 'package:accounts_flutter/src/presentation/widgets/account_row.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

/// The list of accounts: the main one as a card, the capital and the rest.
///
/// It needs an [AccountsCubit] above it.
class AccountsPage extends StatelessWidget {
  /// Creates the page.
  const AccountsPage({
    required this.onBack,
    required this.onAdd,
    required this.onOpen,
    super.key,
  });

  /// Called by the button that goes back.
  final VoidCallback onBack;

  /// Called by the button that adds an account.
  final VoidCallback onAdd;

  /// Called with the id of the account to open.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<AccountsCubit, AccountsState>(
            builder: (context, state) => CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    BirkaTokens.spaceLg,
                    BirkaTokens.spaceXs,
                    BirkaTokens.spaceLg,
                    BirkaTokens.spaceXxl,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _Header(onBack: onBack, onAdd: onAdd),
                      const SizedBox(height: BirkaTokens.spaceLg),
                      ...switch (state) {
                        AccountsLoading() => const <Widget>[],
                        AccountsFailed() => [const _Failure()],
                        AccountsLoaded(:final overview) =>
                          overview.active.isEmpty && overview.archived.isEmpty
                              ? [_Empty(onAdd: onAdd)]
                              : _content(context, overview),
                      },
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, AccountsOverview overview) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final first = overview.active.firstOrNull;
    return [
      Text(
        t.accounts.title,
        style: styles.title.copyWith(color: colors.text),
      ),
      if (overview.totals.isNotEmpty) ...[
        const SizedBox(height: BirkaTokens.spaceXxs),
        _Capital(overview: overview),
      ],
      const SizedBox(height: BirkaTokens.spaceLg),
      if (first != null) ...[
        AccountHeroCard(
          art: cardArtOf(first.account.art),
          name: first.account.name,
          subtitle: accountSubtitle(
            currency: first.account.currency,
            type: first.account.type,
            lastDigits: first.account.lastDigits,
          ),
          amount: formatMoney(first.balance),
          onTap: () => onOpen(first.account.id),
        ),
        const SizedBox(height: BirkaTokens.spaceMd),
        GlassListGroup(
          children: [
            for (final (index, row) in overview.active.indexed)
              AccountRow(
                row: row,
                main: index == 0,
                onTap: () => onOpen(row.account.id),
              ),
          ],
        ),
      ],
      if (overview.archived.isNotEmpty) ...[
        const SizedBox(height: BirkaTokens.spaceLg),
        SectionLabel(t.accounts.archive, color: colors.textSubtle),
        const SizedBox(height: BirkaTokens.spaceXs),
        GlassListGroup(
          children: [
            for (final row in overview.archived)
              AccountRow(row: row, onTap: () => onOpen(row.account.id)),
          ],
        ),
      ],
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onAdd});

  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GlassIconButton(
          glyph: BirkaGlyph.back,
          label: t.accounts.back,
          onPressed: onBack,
        ),
        GlassIconButton(
          glyph: BirkaGlyph.plus,
          label: t.accounts.add,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

/// `Капитал 1 070 800 ₽ и 2 140 € в 4 счетах`. Amounts in different
/// currencies stay apart until exchange rates can add them up.
class _Capital extends StatelessWidget {
  const _Capital({required this.overview});

  final AccountsOverview overview;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final strong = styles.bodyStrong.copyWith(color: colors.text);
    return Text.rich(
      TextSpan(
        style: styles.body.copyWith(color: colors.textMuted),
        children: [
          TextSpan(text: '${t.accounts.capital} '),
          for (final (index, total) in overview.totals.indexed) ...[
            if (index > 0) TextSpan(text: ' ${t.accounts.and} '),
            TextSpan(text: formatMoney(total), style: strong),
          ],
          TextSpan(
            text: ' ${t.accounts.inAccounts(n: overview.countedAccounts)}',
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.accounts.title,
          style: styles.title.copyWith(color: colors.text),
        ),
        const SizedBox(height: BirkaTokens.spaceLg),
        GlassSurface(
          padding: const EdgeInsets.all(BirkaTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.accounts.emptyTitle,
                style: styles.heading.copyWith(color: colors.text),
              ),
              const SizedBox(height: BirkaTokens.spaceXs),
              Text(
                t.accounts.emptyHint,
                style: styles.body.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: BirkaTokens.spaceLg),
              BirkaButton(label: t.accounts.add, onPressed: onAdd),
            ],
          ),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure();

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return GlassSurface(
      padding: const EdgeInsets.all(BirkaTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.accounts.failed,
            style: styles.body.copyWith(color: colors.text),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaButton(
            label: t.app.retry,
            onPressed: () => context.read<AccountsCubit>().retry(),
          ),
        ],
      ),
    );
  }
}
