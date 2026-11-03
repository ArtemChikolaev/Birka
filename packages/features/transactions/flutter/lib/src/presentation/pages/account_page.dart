import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/src/presentation/widgets/delete_sheet.dart';
import 'package:transactions_flutter/src/presentation/widgets/operation_day_group.dart';

/// One account: what it holds, how that changed and what happened on it.
///
/// It needs an [AccountCubit] above it.
class AccountPage extends StatefulWidget {
  /// Creates the page.
  const AccountPage({
    required this.onBack,
    required this.onEdit,
    required this.onOpen,
    required this.onRepeat,
    super.key,
  });

  /// Called by the button that goes back.
  final VoidCallback onBack;

  /// Called by the button that changes the account.
  final VoidCallback onEdit;

  /// Called with the id of the operation to open.
  final ValueChanged<String> onOpen;

  /// Called with the id of the operation to record once more.
  final ValueChanged<String> onRepeat;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(context.read<AccountCubit>().calendarChecked()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _delete(Operation operation) async {
    final cubit = context.read<AccountCubit>();
    if (await confirmDelete(context, operation)) {
      await cubit.delete(operation.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: BirkaTokens.spaceLg);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          // Glass panels share one backdrop, which keeps a long list smooth.
          child: BackdropGroup(
            child: BlocBuilder<AccountCubit, AccountState>(
              builder: (context, state) {
                final account = state.account;
                final ready =
                    state.status == AccountStatus.ready && account != null;
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        BirkaTokens.spaceLg,
                        BirkaTokens.spaceXs,
                        BirkaTokens.spaceLg,
                        0,
                      ),
                      sliver: SliverList.list(
                        children: [
                          _Header(
                            onBack: widget.onBack,
                            onEdit: ready ? widget.onEdit : null,
                          ),
                          gap,
                          ...switch (state.status) {
                            AccountStatus.loading => const [_Card(null)],
                            AccountStatus.failed => [const _Failure()],
                            AccountStatus.gone => [
                              _Notice(t.transactions.accountGone),
                            ],
                            AccountStatus.ready when account == null =>
                              const <Widget>[],
                            AccountStatus.ready => [
                              _Card(account),
                              _Summary(state),
                              gap,
                              if (state.deleteFailed) ...[
                                Text(
                                  t.transactions.failedToDelete,
                                  style: BirkaTextStyles.of(context).caption
                                      .copyWith(
                                        color: BirkaColors.of(context).negative,
                                      ),
                                ),
                                const SizedBox(height: BirkaTokens.spaceSm),
                              ],
                              SectionLabel(
                                t.app.operations,
                                color: BirkaColors.of(context).text,
                              ),
                              const SizedBox(height: BirkaTokens.spaceSm),
                              if (state.operations.isEmpty)
                                _Notice(t.transactions.noAccountOperations),
                            ],
                          },
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        BirkaTokens.spaceLg,
                        0,
                        BirkaTokens.spaceLg,
                        BirkaTokens.spaceXxl +
                            MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      sliver: ready
                          ? SliverList.separated(
                              itemCount: state.days.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: BirkaTokens.spaceLg),
                              itemBuilder: (context, index) =>
                                  OperationDayGroup(
                                    key: ValueKey(state.days[index].day),
                                    day: state.days[index],
                                    today: state.today,
                                    accountId: account.account.id,
                                    onOpen: widget.onOpen,
                                    onRepeat: widget.onRepeat,
                                    onDelete: _delete,
                                  ),
                            )
                          : const SliverToBoxAdapter(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onEdit});

  final VoidCallback onBack;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final onEdit = this.onEdit;
    return Row(
      children: [
        GlassIconButton(
          glyph: BirkaGlyph.back,
          label: t.transactions.back,
          onPressed: onBack,
        ),
        Expanded(
          child: Center(
            child: SectionLabel(
              t.transactions.account,
              color: BirkaColors.of(context).textMuted,
            ),
          ),
        ),
        // Keeps the label in the middle when the other side stays empty.
        if (onEdit == null)
          const SizedBox(width: BirkaTokens.sizeTouchTarget)
        else
          GlassIconButton(
            glyph: BirkaGlyph.dots,
            label: t.transactions.edit,
            onPressed: onEdit,
          ),
      ],
    );
  }
}

/// The card of the account. While the page loads, its place stays empty at
/// the size of the card: the card of the screen below lands there as the page
/// opens.
class _Card extends StatelessWidget {
  const _Card(this.account);

  final AccountBalance? account;

  @override
  Widget build(BuildContext context) {
    final account = this.account;
    if (account == null) {
      return const BirkaZoomTarget(child: SizedBox(height: AccountCard.height));
    }
    final AccountBalance(account: details, :balance) = account;
    return BirkaZoomTarget(
      child: AccountCard(
        art: CardArt.values.byName(details.art.name),
        name: details.name,
        subtitle: accountLine(
          currency: details.currency.code,
          type: details.type.name,
          lastDigits: details.lastDigits,
        ),
        amount: formatMoney(balance),
        value: balance.minorUnits,
      ),
    );
  }
}

/// How the account changed, its chart and the switch of periods.
class _Summary extends StatelessWidget {
  const _Summary(this.state);

  final AccountState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AccountCubit>();
    final change = state.change;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (change != null && !change.isZero) ...[
          const SizedBox(height: BirkaTokens.spaceMd),
          Row(
            children: [
              Flexible(
                child: BirkaChangePill(
                  label: signedAmountLabel(change),
                  rise: change.isPositive,
                  value: change.minorUnits,
                ),
              ),
              const SizedBox(width: BirkaTokens.spaceXs),
              _FadingCaption(
                chartPeriodCaption(
                  state.period.name,
                  month: state.today.month,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: BirkaTokens.spaceMd),
        BirkaLineChart(
          values: [for (final value in state.history) value.toDouble()],
          label: t.transactions.balanceChart,
          series: state.period,
        ),
        const SizedBox(height: BirkaTokens.spaceSm),
        ChipSwitch(
          options: {
            for (final period in ChartPeriod.values)
              period: chartPeriodLabel(period.name),
          },
          selected: state.period,
          onChanged: cubit.periodChanged,
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(BirkaTokens.spaceLg),
      child: Text(
        text,
        style: BirkaTextStyles.of(
          context,
        ).body.copyWith(color: BirkaColors.of(context).textMuted),
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
            t.transactions.failedToReadOperations,
            style: BirkaTextStyles.of(
              context,
            ).body.copyWith(color: BirkaColors.of(context).text),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaButton(
            label: t.app.retry,
            onPressed: () => context.read<AccountCubit>().retry(),
          ),
        ],
      ),
    );
  }
}

/// [text] that cross-fades into a new one, such as the period of a change.
class _FadingCaption extends StatelessWidget {
  const _FadingCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return AnimatedSwitcher(
      duration: BirkaMotion.reduced(context) ? Duration.zero : BirkaMotion.base,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [...previous, ?current],
      ),
      child: Text(
        text,
        key: ValueKey(text),
        style: styles.body.copyWith(color: colors.textMuted),
      ),
    );
  }
}
