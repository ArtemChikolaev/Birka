import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:overview_common/overview_common.dart';

/// The first screen: the capital and its history, the accounts and what the
/// month has cost.
///
/// It lives in a tab under the navigation bar, and needs an [OverviewCubit]
/// above it.
class OverviewPage extends StatefulWidget {
  /// Creates the page.
  const OverviewPage({
    required this.onAddAccount,
    required this.onAccounts,
    required this.onOpenAccount,
    super.key,
  });

  /// Called by the button that adds the first account.
  final VoidCallback onAddAccount;

  /// Called by the link to all the accounts.
  final VoidCallback onAccounts;

  /// Called with the id of the account to open.
  final ValueChanged<String> onOpenAccount;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(context.read<OverviewCubit>().calendarChecked()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: BirkaTokens.spaceLg);
    return SafeArea(
      bottom: false,
      // Glass panels share one backdrop, which keeps scrolling smooth.
      child: BackdropGroup(
        child: BlocBuilder<OverviewCubit, OverviewState>(
          builder: (context, state) => ListView(
            padding: EdgeInsets.fromLTRB(
              BirkaTokens.spaceLg,
              BirkaTokens.spaceLg,
              BirkaTokens.spaceLg,
              GlassNavBar.clearance + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              _Header(today: state.today),
              gap,
              ...switch (state.status) {
                OverviewStatus.loading => const <Widget>[],
                OverviewStatus.failed => [const _Failure()],
                OverviewStatus.ready when state.accounts.isEmpty => [
                  _Empty(onAddAccount: widget.onAddAccount),
                ],
                OverviewStatus.ready => [
                  if (state.main != null) ...[
                    _Capital(state: state),
                    const SizedBox(height: BirkaTokens.spaceSm),
                    BirkaLineChart(
                      values: [
                        for (final value in state.history) value.toDouble(),
                      ],
                      label: t.overview.chart,
                    ),
                    const SizedBox(height: BirkaTokens.spaceSm),
                    _Periods(selected: state.period),
                    gap,
                  ],
                  _Accounts(
                    accounts: state.accounts,
                    onAccounts: widget.onAccounts,
                    onOpenAccount: widget.onOpenAccount,
                  ),
                  gap,
                  _SpendingCard(
                    spending: state.spending,
                    today: state.today,
                  ),
                ],
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.today});

  final CivilDate today;

  @override
  Widget build(BuildContext context) {
    final hidden = HiddenAmounts.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            monthTitle(today),
            style: BirkaTextStyles.of(
              context,
            ).title.copyWith(color: BirkaColors.of(context).text),
          ),
        ),
        GlassIconButton(
          glyph: hidden ? BirkaGlyph.hidden : BirkaGlyph.eye,
          label: hidden ? t.overview.showAmounts : t.overview.hideAmounts,
          onPressed: () => HiddenAmounts.toggle(context),
        ),
      ],
    );
  }
}

/// `1 284 560 ₽`, the amounts in other currencies and the change.
class _Capital extends StatelessWidget {
  const _Capital({required this.state});

  final OverviewState state;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final main = state.main!;
    final change = state.change;
    final others = state.others;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          capitalLabel(state.capital.length),
          color: colors.textMuted,
        ),
        const SizedBox(height: BirkaTokens.spaceXxs),
        AmountText(
          formatMoney(main),
          style: styles.display.copyWith(color: colors.text),
        ),
        if (others.isNotEmpty) ...[
          const SizedBox(height: BirkaTokens.spaceXxs),
          AmountText(
            others.map(formatMoney).join(' · '),
            tone: AmountTone.muted,
            style: styles.bodyStrong,
          ),
        ],
        if (change != null && !change.isZero) ...[
          const SizedBox(height: BirkaTokens.spaceXs),
          Row(
            children: [
              Flexible(child: _Change(change: change)),
              const SizedBox(width: BirkaTokens.spaceXs),
              Text(
                changeCaption(state.period, today: state.today),
                style: styles.body.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A pill with the arrow and the amount of a change.
class _Change extends StatelessWidget {
  const _Change({required this.change});

  final Money change;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final rise = change.isPositive;
    final color = rise ? colors.positive : colors.negative;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BirkaTokens.spaceSm,
        vertical: BirkaTokens.spaceXxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusPill),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BirkaIcon(
            rise ? BirkaGlyph.rise : BirkaGlyph.fall,
            size: 14,
            color: color,
          ),
          const SizedBox(width: BirkaTokens.spaceXxs),
          Flexible(
            child: AmountText(
              changeLabel(change),
              tone: rise ? AmountTone.positive : AmountTone.negative,
              style: BirkaTextStyles.of(context).bodyStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _Periods extends StatelessWidget {
  const _Periods({required this.selected});

  final OverviewPeriod selected;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OverviewCubit>();
    return Wrap(
      spacing: BirkaTokens.spaceXs,
      runSpacing: BirkaTokens.spaceXs,
      children: [
        for (final period in OverviewPeriod.values)
          BirkaChip(
            label: periodLabel(period),
            selected: period == selected,
            compact: true,
            onTap: () => cubit.periodChanged(period),
          ),
      ],
    );
  }
}

class _Accounts extends StatelessWidget {
  const _Accounts({
    required this.accounts,
    required this.onAccounts,
    required this.onOpenAccount,
  });

  final List<AccountBalance> accounts;
  final VoidCallback onAccounts;
  final ValueChanged<String> onOpenAccount;

  /// The width of a card in the row, which shows the edge of the next one.
  static const double _cardWidth = 236;

  Widget _card(AccountBalance row) {
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
      onTap: () => onOpenAccount(account.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionLabel(t.overview.accounts, color: colors.text),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAccounts,
                child: SectionLabel(
                  t.overview.allAccounts(n: accounts.length),
                  color: colors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BirkaTokens.spaceSm),
        if (accounts.length == 1)
          _card(accounts.single)
        else
          SizedBox(
            height: AccountCard.compactHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: accounts.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: BirkaTokens.spaceSm),
              itemBuilder: (context, index) =>
                  SizedBox(width: _cardWidth, child: _card(accounts[index])),
            ),
          ),
      ],
    );
  }
}

/// The ring of the month, its total and its biggest categories.
class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.spending, required this.today});

  final Spending spending;
  final CivilDate today;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final title = SectionLabel(spendingTitle(today), color: colors.textMuted);
    final total = spending.total;
    if (total == null) {
      return GlassSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            title,
            const SizedBox(height: BirkaTokens.spaceXs),
            Text(
              t.overview.noSpending,
              style: styles.body.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      );
    }
    return GlassSurface(
      child: Row(
        children: [
          BirkaRing(
            label: t.overview.ring,
            slices: [
              for (final CategoryTotal(:category, total: amount)
                  in spending.categories)
                RingSlice(
                  amount.minorUnits.toDouble(),
                  _colorOf(category, colors),
                ),
            ],
          ),
          const SizedBox(width: BirkaTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: BirkaTokens.spaceXxs),
                AmountText(
                  formatMoney(-total),
                  style: styles.heading.copyWith(color: colors.text),
                ),
                const SizedBox(height: BirkaTokens.spaceXs),
                for (final row in spending.top) _CategoryLine(row: row),
                if (spending.others.isNotEmpty)
                  AmountText(
                    spending.others.map(formatMoney).join(' · '),
                    tone: AmountTone.muted,
                    style: styles.caption,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorOf(Category category, BirkaColors colors) {
  final color = category.color;
  return color == null ? colors.textSubtle : BirkaColors.fromHex(color);
}

class _CategoryLine extends StatelessWidget {
  const _CategoryLine({required this.row});

  final CategoryTotal row;

  static const double _dot = 8;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: BirkaTokens.spaceXxs),
      child: Row(
        children: [
          Container(
            width: _dot,
            height: _dot,
            decoration: BoxDecoration(
              color: _colorOf(row.category, colors),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: BirkaTokens.spaceXs),
          Expanded(
            child: Text(
              row.category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: styles.caption.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: BirkaTokens.spaceXs),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: AmountText(
                formatMoney(row.total),
                style: styles.caption.copyWith(color: colors.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAddAccount});

  final VoidCallback onAddAccount;

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
            t.accounts.emptyTitle,
            style: styles.heading.copyWith(color: colors.text),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            t.accounts.emptyHint,
            style: styles.body.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          BirkaButton(label: t.accounts.add, onPressed: onAddAccount),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(BirkaTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.overview.failed,
            style: BirkaTextStyles.of(
              context,
            ).body.copyWith(color: BirkaColors.of(context).text),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaButton(
            label: t.app.retry,
            onPressed: () => context.read<OverviewCubit>().retry(),
          ),
        ],
      ),
    );
  }
}
