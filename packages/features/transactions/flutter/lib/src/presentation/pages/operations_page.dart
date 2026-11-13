import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/src/presentation/widgets/delete_sheet.dart';
import 'package:transactions_flutter/src/presentation/widgets/operation_day_group.dart';

/// The operations of a month, day by day, with a search and filters.
///
/// It lives in a tab under the navigation bar, and needs an [OperationsCubit]
/// above it.
class OperationsPage extends StatefulWidget {
  /// Creates the page.
  const OperationsPage({
    required this.onOpen,
    required this.onRepeat,
    this.onBack,
    super.key,
  });

  /// Called with the id of the operation to open.
  final ValueChanged<String> onOpen;

  /// Called with the id of the operation to record once more.
  final ValueChanged<String> onRepeat;

  /// Goes back, for the list of an answer of «Спросить» opened over it:
  /// the header gets a back button and the plaque a way back to the answer.
  final VoidCallback? onBack;

  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  final _search = TextEditingController();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(context.read<OperationsCubit>().calendarChecked()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(Operation operation) async {
    final cubit = context.read<OperationsCubit>();
    if (await confirmDelete(context, operation)) {
      await cubit.delete(operation.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      // Glass panels share one backdrop, which keeps a long list smooth.
      child: BackdropGroup(
        child: BlocBuilder<OperationsCubit, OperationsState>(
          // A swipe turns to the month before or after, and the month on
          // screen slides away for it, as it does on Отчёты.
          builder: (context, state) => SwipeBetween(
            onPrevious: () =>
                unawaited(context.read<OperationsCubit>().previousMonth()),
            onNext: () =>
                unawaited(context.read<OperationsCubit>().nextMonth()),
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    BirkaTokens.spaceLg,
                    BirkaTokens.spaceLg,
                    BirkaTokens.spaceLg,
                    0,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _Header(state: state, onBack: widget.onBack),
                      const SizedBox(height: BirkaTokens.spaceMd),
                      GlassSearchField(
                        label: t.transactions.search,
                        clearLabel: t.transactions.clearSearch,
                        hint: t.transactions.searchHint,
                        controller: _search,
                        onChanged: context.read<OperationsCubit>().queryChanged,
                      ),
                      const SizedBox(height: BirkaTokens.spaceSm),
                      _Filters(state: state),
                      // The plaque of an answer closes as it is taken off.
                      AnimatedSize(
                        duration: BirkaMotion.reduced(context)
                            ? Duration.zero
                            : BirkaMotion.base,
                        curve: BirkaMotion.standardCurve,
                        alignment: Alignment.topCenter,
                        child: switch (state.focus) {
                          null => const SizedBox(width: double.infinity),
                          final focus => _Plaque(
                            focus: focus,
                            onBack: widget.onBack,
                          ),
                        },
                      ),
                      if (state.deleteFailed) ...[
                        const SizedBox(height: BirkaTokens.spaceSm),
                        Text(
                          t.transactions.failedToDelete,
                          style: BirkaTextStyles.of(context).caption.copyWith(
                            color: BirkaColors.of(context).negative,
                          ),
                        ),
                      ],
                      SlideSwitcher(
                        value: state.month,
                        follow: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (state.expenses.isNotEmpty ||
                                state.income.isNotEmpty) ...[
                              const SizedBox(height: BirkaTokens.spaceSm),
                              // A new month, filter or search starts the
                              // totals anew, so that they roll only when the
                              // money moves.
                              _Totals(
                                key: ValueKey((
                                  state.month,
                                  state.filter,
                                  state.query,
                                  state.focus,
                                )),
                                state: state,
                              ),
                            ],
                            const SizedBox(height: BirkaTokens.spaceMd),
                            ...switch (state.status) {
                              OperationsStatus.loading => const <Widget>[],
                              OperationsStatus.failed => [const _Failure()],
                              OperationsStatus.ready when state.shown.isEmpty =>
                                [_Empty(narrowed: state.isNarrowed)],
                              OperationsStatus.ready => const <Widget>[],
                            },
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    BirkaTokens.spaceLg,
                    0,
                    BirkaTokens.spaceLg,
                    // Each day keeps its room under it.
                    GlassNavBar.clearance -
                        BirkaTokens.spaceLg +
                        MediaQuery.viewPaddingOf(context).bottom +
                        MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  sliver: SlideSwitcher.sliver(
                    value: state.month,
                    follow: true,
                    sliver: state.status == OperationsStatus.ready
                        ? SliverOperationDays(
                            // A new month, filter or search starts the days
                            // anew, so that days and rows open and close only
                            // when operations come and go.
                            key: ValueKey((
                              state.month,
                              state.filter,
                              state.query,
                              state.focus,
                            )),
                            days: state.days,
                            today: state.today,
                            onOpen: widget.onOpen,
                            onRepeat: widget.onRepeat,
                            onDelete: _delete,
                          )
                        : const SliverToBoxAdapter(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, this.onBack});

  final OperationsState state;
  final VoidCallback? onBack;

  Future<void> _pickMonth(BuildContext context) async {
    final cubit = context.read<OperationsCubit>();
    final colors = BirkaColors.of(context);
    final months = await cubit.months();
    if (!context.mounted) return;
    final picked = await showModalBottomSheet<CivilDate>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: colors.background,
      builder: (context) => ChoiceSheet(
        title: t.transactions.pickMonth,
        children: [
          GlassListGroup(
            children: [
              for (final month in months)
                GlassListRow(
                  title: monthLabel(month, today: state.today),
                  trailing: month == state.month
                      ? BirkaIcon(BirkaGlyph.check, color: colors.accent)
                      : null,
                  onTap: () => Navigator.of(context).pop(month),
                ),
            ],
          ),
        ],
      ),
    );
    if (picked != null) await cubit.monthChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final onBack = this.onBack;
    return Row(
      children: [
        if (onBack != null) ...[
          GlassIconButton(
            glyph: BirkaGlyph.back,
            label: t.transactions.back,
            onPressed: onBack,
          ),
          const SizedBox(width: BirkaTokens.spaceSm),
        ],
        Expanded(
          child: Text(
            t.app.operations,
            style: BirkaTextStyles.of(
              context,
            ).title.copyWith(color: BirkaColors.of(context).text),
          ),
        ),
        // Under the plaque of an answer the plaque tells the days.
        if (state.focus == null) ...[
          const SizedBox(width: BirkaTokens.spaceXs),
          BirkaChip(
            glyph: BirkaGlyph.calendar,
            label: monthLabel(state.month, today: state.today),
            selected: false,
            order: state.month,
            onTap: () => _pickMonth(context),
          ),
        ],
      ],
    );
  }
}

/// The plaque of an answer of «Спросить»: the list shows its operations
/// alone until the cross takes it off, and a link leads back to the answer.
class _Plaque extends StatelessWidget {
  const _Plaque({required this.focus, this.onBack});

  final OperationsFocus focus;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final onBack = this.onBack;
    return Padding(
      padding: const EdgeInsets.only(top: BirkaTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SectionLabel(t.transactions.fromQuestion)),
              if (onBack != null)
                AccentLink(
                  label: t.transactions.toAnswer,
                  chevron: false,
                  onTap: onBack,
                ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          Semantics(
            label: t.transactions.dropFocus(title: focus.title),
            excludeSemantics: true,
            button: true,
            child: BirkaChip(
              label: focus.title,
              selected: true,
              trailingGlyph: BirkaGlyph.close,
              onTap: () =>
                  unawaited(context.read<OperationsCubit>().dropFocus()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final OperationsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OperationsCubit>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: ChipSwitch(
        options: {
          for (final filter in OperationsFilter.values)
            filter: filterLabel(filter),
        },
        selected: state.filter,
        onChanged: cubit.filterChanged,
        compact: true,
      ),
    );
  }
}

/// `Расходы −86 420 ₽  Доходы +210 000 ₽` for what the list shows.
class _Totals extends StatelessWidget {
  const _Totals({required this.state, super.key});

  final OperationsState state;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return Wrap(
      spacing: BirkaTokens.spaceMd,
      runSpacing: BirkaTokens.spaceXxs,
      children: [
        if (state.expenses.isNotEmpty)
          _Total(
            label: t.transactions.filterExpenses,
            amounts: amountsLabel(state.expenses),
            value: state.expenses.length == 1
                ? state.expenses.single.minorUnits
                : null,
            color: colors.text,
          ),
        if (state.income.isNotEmpty)
          _Total(
            label: t.transactions.filterIncome,
            amounts: amountsLabel(state.income),
            value: state.income.length == 1
                ? state.income.single.minorUnits
                : null,
            color: colors.positive,
          ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.amounts,
    required this.value,
    required this.color,
  });

  final String label;
  final String amounts;

  /// The amount in minor units when there is one currency, so that it rolls.
  final num? value;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: styles.body.copyWith(color: BirkaColors.of(context).textMuted),
        ),
        Flexible(
          child: AmountText(
            amounts,
            value: value,
            rise: AmountRise.good,
            style: styles.bodyStrong.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.narrowed});

  final bool narrowed;

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
            narrowed
                ? t.transactions.nothingFound
                : t.transactions.noOperationsTitle,
            style: styles.heading.copyWith(color: colors.text),
          ),
          if (!narrowed) ...[
            const SizedBox(height: BirkaTokens.spaceXs),
            Text(
              t.transactions.noOperationsHint,
              style: styles.body.copyWith(color: colors.textMuted),
            ),
          ],
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
            t.transactions.failedToReadOperations,
            style: BirkaTextStyles.of(
              context,
            ).body.copyWith(color: BirkaColors.of(context).text),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaButton(
            label: t.app.retry,
            onPressed: () => context.read<OperationsCubit>().retry(),
          ),
        ],
      ),
    );
  }
}
