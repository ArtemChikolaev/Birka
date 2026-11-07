import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_flutter/src/presentation/widgets/schedule_bits.dart';

/// The form of a new or an existing regular payment, as a sheet (ADR 0023).
///
/// It needs a [ScheduleFormCubit] above it.
class ScheduleFormPage extends StatelessWidget {
  /// Creates the page. [onClose] is called when the form is done or
  /// cancelled.
  const ScheduleFormPage({required this.onClose, super.key});

  /// Closes the form.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocConsumer<ScheduleFormCubit, ScheduleFormState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              switch (state.status) {
                case ScheduleFormStatus.deleted:
                  showGlassToast(
                    context,
                    t.schedules.deleted(name: state.name.trim()),
                  );
                  onClose();
                case ScheduleFormStatus.missing:
                  onClose();
                case ScheduleFormStatus.loading ||
                    ScheduleFormStatus.editing ||
                    ScheduleFormStatus.saving ||
                    ScheduleFormStatus.saved:
                  break;
              }
            },
            builder: (context, state) => switch (state.status) {
              ScheduleFormStatus.loading ||
              ScheduleFormStatus.missing => const SizedBox.shrink(),
              _ => _Form(state: state, onClose: onClose),
            },
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state, required this.onClose});

  final ScheduleFormState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ScheduleFormCubit>();
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final transfer = state.kind == TransactionKind.transfer;
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
                child: Text(
                  state.editing ? state.name.trim() : t.schedules.newTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.heading.copyWith(color: colors.text),
                ),
              ),
              GlassIconButton(
                glyph: BirkaGlyph.close,
                label: t.schedules.close,
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
                Semantics(
                  label: t.schedules.kindLabel,
                  child: GlassSegmented<TransactionKind>(
                    segments: {
                      for (final kind in [
                        TransactionKind.expense,
                        TransactionKind.income,
                        TransactionKind.transfer,
                      ])
                        kind: t.schedules.kinds[kind.name] ?? kind.name,
                    },
                    selected: state.kind,
                    onChanged: cubit.kindChanged,
                  ),
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                _Amount(state: state),
                const SizedBox(height: BirkaTokens.spaceLg),
                GlassListGroup(
                  children: [
                    GlassListRow(
                      key: const ValueKey('name'),
                      title: t.schedules.name,
                      trailing: _Value(
                        state.name.trim().isEmpty
                            ? t.schedules.namePlaceholder
                            : state.name.trim(),
                        quiet: state.name.trim().isEmpty,
                      ),
                      onTap: () => unawaited(_editName(context)),
                    ),
                    if (!transfer)
                      GlassListRow(
                        key: const ValueKey('category'),
                        title: t.schedules.category,
                        trailing: _Value(
                          state.category?.name ?? t.schedules.noCategory,
                          dot: state.category?.color,
                          quiet: state.category == null,
                        ),
                        onTap: () => unawaited(_pickCategory(context)),
                      ),
                    GlassListRow(
                      key: const ValueKey('account'),
                      title: switch (state.kind) {
                        TransactionKind.transfer => t.schedules.fromAccount,
                        TransactionKind.income => t.schedules.incomeAccount,
                        _ => t.schedules.account,
                      },
                      trailing: _Value(
                        state.account?.name ?? t.schedules.pickAccount,
                        quiet: state.account == null,
                      ),
                      onTap: () => unawaited(_pickAccount(context)),
                    ),
                    if (transfer)
                      GlassListRow(
                        key: const ValueKey('to'),
                        title: t.schedules.toAccount,
                        trailing: _Value(
                          state.toAccount?.name ?? t.schedules.pickAccount,
                          quiet: state.toAccount == null,
                        ),
                        onTap: () => unawaited(_pickTarget(context)),
                      ),
                  ],
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                GlassSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Caption(t.schedules.every),
                      ChipSwitch<ScheduleEvery>(
                        options: {
                          for (final every in ScheduleEvery.values)
                            every:
                                t.schedules.everyOptions[every.name] ??
                                every.name,
                        },
                        selected: state.every,
                        onChanged: cubit.everyChanged,
                      ),
                      const SizedBox(height: BirkaTokens.spaceSm),
                      _Line(
                        label: switch (state.every) {
                          ScheduleEvery.month => t.schedules.dayOfMonth,
                          ScheduleEvery.week => t.schedules.dayOfWeek,
                          ScheduleEvery.year => t.schedules.dayOfYear,
                        },
                        value: _dayLabel(state),
                      ),
                      _Line(
                        label: t.schedules.next,
                        value:
                            '${fullDate(state.next, state.today)}, '
                            '${weekdayLabel(state.next)}',
                        onTap: () => unawaited(_pickNext(context)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                GlassSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Caption(t.schedules.onDayTitle),
                      ChipSwitch<ScheduleOnDay>(
                        options: {
                          for (final onDay in ScheduleOnDay.values)
                            onDay: t.schedules.onDay[onDay.name] ?? onDay.name,
                        },
                        selected: state.onDay,
                        onChanged: cubit.onDayChanged,
                      ),
                      const SizedBox(height: BirkaTokens.spaceSm),
                      FadingText(
                        state.onDay == ScheduleOnDay.post
                            ? t.schedules.postNote
                            : t.schedules.askNote,
                        style: styles.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.editing) ...[
                  const SizedBox(height: BirkaTokens.spaceLg),
                  GlassListGroup(
                    children: [
                      GlassListRow(
                        title: t.schedules.delete,
                        subtitle: t.schedules.deleteNote,
                        danger: true,
                        onTap: () => unawaited(_delete(context)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: BirkaTokens.spaceMd),
              ],
            ),
          ),
        ),
        BirkaRise(
          start: 0.25,
          child: Padding(
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
                // Once saved, the button turns into a check mark and closes
                // the form.
                BirkaButton(
                  label: t.schedules.save,
                  onPressed:
                      state.valid && state.status == ScheduleFormStatus.editing
                      ? () => unawaited(cubit.save())
                      : null,
                  done: state.status == ScheduleFormStatus.saved,
                  onDone: onClose,
                ),
                const SizedBox(height: BirkaTokens.spaceXs),
                Text(
                  state.editing
                      ? t.schedules.changeNote(
                          date: fullDate(state.next, state.today),
                        )
                      : t.schedules.saveNote,
                  textAlign: TextAlign.center,
                  style: styles.caption.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _dayLabel(ScheduleFormState state) => switch (state.every) {
    ScheduleEvery.month => t.schedules.dayNumber(day: state.day),
    ScheduleEvery.week =>
      t.schedules.on[_weekdays[state.next.weekday - 1]] ?? '',
    ScheduleEvery.year => fullDate(state.next, state.today),
  };

  static const _weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  Future<void> _editName(BuildContext context) async {
    final cubit = context.read<ScheduleFormCubit>();
    final name = await showFieldSheet(
      context,
      label: t.schedules.name,
      hint: t.schedules.namePlaceholder,
      done: t.schedules.done,
      initial: state.name,
    );
    if (name != null) cubit.nameChanged(name);
  }

  Future<void> _pickCategory(BuildContext context) async {
    final cubit = context.read<ScheduleFormCubit>();
    final categories = {for (final it in state.categories) it.id: it};
    final picked = await showChoiceSheet<String?>(
      context,
      title: t.schedules.category,
      choices: [null, ...categories.keys],
      selected: state.categoryId,
      labelOf: (id) => categories[id]?.name ?? t.schedules.noCategory,
      subtitleOf: (id) => id == null ? t.schedules.categoryLater : null,
      leadingOf: (id) => CategoryDot(categories[id]?.color),
    );
    if (picked case (final id,)) cubit.categoryChanged(id);
  }

  Future<void> _pickAccount(BuildContext context) async {
    final cubit = context.read<ScheduleFormCubit>();
    final accounts = {for (final it in state.accounts) it.id: it};
    final picked = await showChoiceSheet<String>(
      context,
      title: t.schedules.account,
      choices: [...accounts.keys],
      selected: state.accountId ?? '',
      labelOf: (id) => accounts[id]?.name ?? '',
      subtitleOf: (id) => accounts[id]?.currency.code,
    );
    if (picked case (final id,)) cubit.accountChanged(id);
  }

  Future<void> _pickTarget(BuildContext context) async {
    final cubit = context.read<ScheduleFormCubit>();
    final targets = {for (final it in state.targets) it.id: it};
    final picked = await showChoiceSheet<String>(
      context,
      title: t.schedules.toAccount,
      choices: [...targets.keys],
      selected: state.toAccountId ?? '',
      labelOf: (id) => targets[id]?.name ?? '',
    );
    if (picked case (final id,)) cubit.toAccountChanged(id);
  }

  Future<void> _pickNext(BuildContext context) async {
    final cubit = context.read<ScheduleFormCubit>();
    final next = state.next;
    final today = state.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(next.year, next.month, next.day),
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (picked != null) cubit.nextChanged(CivilDate.of(picked));
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<ScheduleFormCubit>();
    final sure = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: BirkaColors.of(context).background,
      builder: (context) => ChoiceSheet(
        title: t.schedules.deleteTitle(name: state.name.trim()),
        subtitle: t.schedules.deleteNote,
        children: [
          BirkaButton(
            label: t.schedules.delete,
            danger: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (sure ?? false) await cubit.delete();
  }
}

/// The amount, large, which opens a field with the keyboard of numbers.
class _Amount extends StatelessWidget {
  const _Amount({required this.state});

  final ScheduleFormState state;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final amount = state.amount;
    final text = amount == null
        ? '0'
        : switch (state.kind) {
            TransactionKind.income => '+${formatMoney(amount)}',
            _ => formatMoney(amount),
          };
    return Semantics(
      button: true,
      label: t.schedules.amount,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: amount == null ? null : () => unawaited(_edit(context, amount)),
        child: Column(
          children: [
            SectionLabel(t.schedules.amount, color: colors.textMuted),
            const SizedBox(height: BirkaTokens.spaceXxs),
            AmountText(
              text,
              alwaysShown: true,
              tone: state.kind == TransactionKind.income
                  ? AmountTone.positive
                  : AmountTone.neutral,
              style: styles.display,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, Money amount) async {
    final cubit = context.read<ScheduleFormCubit>();
    final typed = await showFieldSheet(
      context,
      label: t.schedules.amount,
      done: t.schedules.done,
      initial: amount.isZero ? '' : typedAmount(amount),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    if (typed == null) return;
    final money = amountTyped(typed, amount.currency);
    if (money != null) cubit.amountChanged(money.minorUnits);
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text, {this.quiet = false, this.dot});

  final String text;
  final bool quiet;
  final String? dot;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot != null) ...[
          CategoryDot(dot),
          const SizedBox(width: BirkaTokens.spaceXs),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: styles.bodyStrong.copyWith(
              color: quiet ? colors.textMuted : colors.text,
            ),
          ),
        ),
        const SizedBox(width: BirkaTokens.spaceXs),
        BirkaIcon(BirkaGlyph.chevron, size: 16, color: colors.textMuted),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BirkaTokens.spaceXs),
      child: Text(
        text,
        style: BirkaTextStyles.of(
          context,
        ).caption.copyWith(color: BirkaColors.of(context).textMuted),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: styles.caption.copyWith(color: colors.textMuted),
                ),
              ),
              FadingText(
                value,
                style: styles.bodyStrong.copyWith(color: colors.text),
              ),
              if (onTap != null) ...[
                const SizedBox(width: BirkaTokens.spaceXs),
                BirkaIcon(
                  BirkaGlyph.chevron,
                  size: 16,
                  color: colors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
