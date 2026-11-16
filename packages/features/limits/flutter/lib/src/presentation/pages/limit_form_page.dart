import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_common/limits_common.dart';
import 'package:limits_flutter/src/presentation/widgets/limit_bits.dart';
import 'package:money/money.dart';

/// The form of a monthly limit, as a sheet (ADR 0033): the category, the
/// sum of a month and its currency, the average to take it from, and
/// whether Birka says so early.
///
/// It needs a [LimitFormCubit] above it. Once saved or taken away, it says
/// so in a toast and calls [onClose].
class LimitFormPage extends StatelessWidget {
  /// Creates the form.
  const LimitFormPage({required this.onClose, super.key});

  /// Closes the form.
  final VoidCallback onClose;

  /// How many categories stand as chips before «Ещё».
  static const _shown = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocBuilder<LimitFormCubit, LimitFormState>(
            builder: (context, state) => switch (state.status) {
              LimitFormStatus.loading => const SizedBox.shrink(),
              _ => _form(context, state),
            },
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, LimitFormState state) {
    final cubit = context.read<LimitFormCubit>();
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final amount = state.amount;
    final spentNow = limitSpentNow(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BirkaTokens.spaceLg,
            BirkaTokens.spaceXs,
            BirkaTokens.spaceLg,
            BirkaTokens.spaceSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: FadingText(
                  limitFormTitle(state),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.heading.copyWith(color: colors.text),
                ),
              ),
              GlassIconButton(
                glyph: BirkaGlyph.close,
                label: t.app.close,
                glass: false,
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Expanded(
          child: ScrollEdgeFade(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: BirkaTokens.spaceLg,
                vertical: BirkaTokens.spaceXs,
              ),
              children: [
                if (state.editing && state.category != null)
                  Row(
                    children: [
                      CategoryBadge(state.category!, size: 44),
                      const SizedBox(width: BirkaTokens.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.category!.name,
                              style: styles.bodyStrong.copyWith(
                                color: colors.text,
                              ),
                            ),
                            if (spentNow != null)
                              Text(
                                HiddenAmounts.mask(context, spentNow),
                                style: styles.caption.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  Text(
                    t.limits.form.category,
                    style: styles.caption.copyWith(color: colors.textMuted),
                  ),
                  const SizedBox(height: BirkaTokens.spaceXs),
                  _Categories(state: state),
                ],
                const SizedBox(height: BirkaTokens.spaceLg),
                GlassListGroup(
                  children: [
                    GlassValueRow(
                      key: const ValueKey('amount'),
                      label: t.limits.form.perMonth,
                      value: amount == null
                          ? t.limits.form.notSet
                          : HiddenAmounts.mask(context, formatMoney(amount)),
                      quiet: amount == null,
                      onTap: () => unawaited(_editAmount(context, state)),
                    ),
                  ],
                ),
                if (state.currencies.length > 1) ...[
                  const SizedBox(height: BirkaTokens.spaceLg),
                  Text(
                    t.limits.form.currency,
                    style: styles.caption.copyWith(color: colors.textMuted),
                  ),
                  const SizedBox(height: BirkaTokens.spaceXs),
                  ChipSwitch<Currency>(
                    options: {
                      for (final currency in state.currencies)
                        currency:
                            t.app.currencies[currency.code] ?? currency.code,
                    },
                    selected: state.currency,
                    onChanged: cubit.currencyPicked,
                    wrap: true,
                  ),
                ],
                const SizedBox(height: BirkaTokens.spaceLg),
                _Average(state: state),
                const SizedBox(height: BirkaTokens.spaceLg),
                GlassListGroup(
                  children: [
                    GlassListRow(
                      key: const ValueKey('warn'),
                      title: t.limits.form.warn,
                      subtitle: HiddenAmounts.mask(
                        context,
                        limitWarnLine(state),
                      ),
                      subtitleLines: 2,
                      trailing: Switch(
                        value: state.warnEarly,
                        onChanged: (on) => cubit.warnChanged(on: on),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BirkaTokens.spaceSm),
                FadingText(
                  limitCaption(state),
                  style: styles.caption.copyWith(color: colors.textMuted),
                ),
                if (state.editing) ...[
                  const SizedBox(height: BirkaTokens.spaceLg),
                  BirkaButton(
                    label: t.limits.form.remove,
                    quiet: true,
                    danger: true,
                    onPressed: state.status == LimitFormStatus.editing
                        ? () => unawaited(cubit.remove())
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BirkaTokens.spaceLg,
            BirkaTokens.spaceXs,
            BirkaTokens.spaceLg,
            BirkaTokens.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.status == LimitFormStatus.failed) ...[
                Text(
                  t.limits.form.failed,
                  textAlign: TextAlign.center,
                  style: styles.caption.copyWith(color: colors.negative),
                ),
                const SizedBox(height: BirkaTokens.spaceXs),
              ],
              // Once saved, the button turns into a check mark, and the
              // toast comes as the sheet goes down.
              BirkaButton(
                label: t.transactions.save,
                onPressed: state.canSave ? () => unawaited(cubit.save()) : null,
                done:
                    state.status == LimitFormStatus.saved ||
                    state.status == LimitFormStatus.removed,
                onDone: () => _done(context, state),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _done(BuildContext context, LimitFormState state) {
    showGlassToast(context, HiddenAmounts.mask(context, limitDone(state)));
    onClose();
  }

  Future<void> _editAmount(BuildContext context, LimitFormState state) async {
    final cubit = context.read<LimitFormCubit>();
    final amount = state.amount;
    final typed = await showFieldSheet(
      context,
      label: t.limits.form.amountHint,
      done: t.limits.form.done,
      initial: amount == null || amount.isZero ? '' : typedAmount(amount),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      suffix: currencySign(state.currency),
    );
    if (typed == null) return;
    cubit.amountChanged(amountTyped(typed, state.currency));
  }
}

/// The categories a new limit can take: the picked one and the first
/// others as chips, and the rest in a sheet behind «Ещё».
class _Categories extends StatelessWidget {
  const _Categories({required this.state});

  final LimitFormState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LimitFormCubit>();
    final picked = state.category;
    final others = [
      for (final category in state.categories)
        if (category.id != picked?.id) category,
    ];
    final shown = (picked == null ? others : [picked, ...others])
        .take(LimitFormPage._shown)
        .toList();
    final rest = state.categories.length - shown.length;
    return Wrap(
      spacing: BirkaTokens.spaceXs,
      runSpacing: BirkaTokens.spaceXs,
      children: [
        for (final category in shown)
          BirkaChip(
            label: category.name,
            selected: category.id == state.categoryId,
            onTap: () => cubit.categoryPicked(category.id),
          ),
        if (rest > 0)
          BirkaChip(
            label: t.limits.form.more(n: rest),
            selected: false,
            dashed: true,
            onTap: () => unawaited(_pickOther(context)),
          ),
      ],
    );
  }

  Future<void> _pickOther(BuildContext context) async {
    final cubit = context.read<LimitFormCubit>();
    final id = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: BirkaColors.of(context).background,
      builder: (context) => ChoiceSheet(
        title: t.limits.form.category,
        children: [
          GlassListGroup(
            children: [
              for (final Category category in state.categories)
                GlassListRow(
                  key: ValueKey(category.id),
                  leading: CategoryBadge(category),
                  title: category.name,
                  onTap: () => Navigator.of(context).pop(category.id),
                ),
            ],
          ),
        ],
      ),
    );
    if (id != null) cubit.categoryPicked(id);
  }
}

/// What the category spent on average, with the button that takes the
/// offered limit, or a note once the sum is the offer.
class _Average extends StatelessWidget {
  const _Average({required this.state});

  final LimitFormState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LimitFormCubit>();
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final suggestion = state.suggestion;
    return GlassSurface(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.limits.form.average,
                  style: styles.caption.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: BirkaTokens.spaceXxs),
                FadingText(
                  suggestion == null
                      ? t.limits.form.noAverage
                      : HiddenAmounts.mask(
                          context,
                          formatMoney(suggestion.average),
                        ),
                  style: styles.bodyStrong.copyWith(color: colors.text),
                ),
              ],
            ),
          ),
          if (suggestion != null)
            AnimatedSwitcher(
              duration: BirkaMotion.reduced(context)
                  ? Duration.zero
                  : BirkaMotion.base,
              child: state.asOffered
                  ? Row(
                      key: const ValueKey('taken'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BirkaIcon(
                          BirkaGlyph.check,
                          size: 16,
                          color: colors.accent,
                        ),
                        const SizedBox(width: BirkaTokens.spaceXxs),
                        Text(
                          state.took ? t.limits.form.taken : t.limits.form.same,
                          style: styles.caption.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    )
                  : BirkaChip(
                      key: const ValueKey('take'),
                      label: HiddenAmounts.mask(
                        context,
                        limitTake(suggestion.offer),
                      ),
                      selected: false,
                      compact: true,
                      onTap: cubit.takeOffer,
                    ),
            ),
        ],
      ),
    );
  }
}
