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
  const ScheduleFormPage({
    required this.onClose,
    this.onEnableReminders,
    super.key,
  });

  /// Closes the form.
  final VoidCallback onClose;

  /// Turns the reminders of Birka on, when they are off and the payment is
  /// to remind (ADR 0025).
  final VoidCallback? onEnableReminders;

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
              _ => _Form(
                state: state,
                onClose: onClose,
                onEnableReminders: onEnableReminders,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.state,
    required this.onClose,
    required this.onEnableReminders,
  });

  final ScheduleFormState state;
  final VoidCallback onClose;
  final VoidCallback? onEnableReminders;

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
                if (state.madeFrom case final made?) ...[
                  _MadeFrom(made: made, state: state),
                  const SizedBox(height: BirkaTokens.spaceLg),
                ],
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
                AnimatedColumn(
                  children: [
                    if (state.kind == TransactionKind.income)
                      Padding(
                        key: const ValueKey('parts'),
                        padding: const EdgeInsets.only(
                          top: BirkaTokens.spaceLg,
                        ),
                        child: _Parts(state: state),
                      ),
                  ],
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                GlassSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // A salary in halves comes every month, on two days.
                      AnimatedColumn(
                        children: [
                          if (!state.halves)
                            Column(
                              key: const ValueKey('every'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Caption(t.schedules.every),
                                ChipSwitch<ScheduleEvery>(
                                  options: {
                                    for (final every in ScheduleEvery.values)
                                      every:
                                          t.schedules.everyOptions[every
                                              .name] ??
                                          every.name,
                                  },
                                  selected: state.every,
                                  onChanged: cubit.everyChanged,
                                ),
                                const SizedBox(height: BirkaTokens.spaceSm),
                              ],
                            ),
                          if (state.advanceDay case final advance?
                              when state.halves)
                            _Line(
                              key: const ValueKey('advance'),
                              label: t.schedules.advanceDay,
                              value: t.schedules.dayNumber(day: advance),
                              onTap: () => unawaited(
                                _pickDay(context, advance: true),
                              ),
                            ),
                          if (state.halves)
                            _AdvanceAmount(
                              key: const ValueKey('advanceAmount'),
                              state: state,
                            ),
                        ],
                      ),
                      _Line(
                        label: state.halves
                            ? t.schedules.restDay
                            : switch (state.every) {
                                ScheduleEvery.month => t.schedules.dayOfMonth,
                                ScheduleEvery.week => t.schedules.dayOfWeek,
                                ScheduleEvery.year => t.schedules.dayOfYear,
                              },
                        value: _dayLabel(state),
                        onTap: state.halves
                            ? () => unawaited(_pickDay(context, advance: false))
                            : null,
                      ),
                      _Line(
                        label: t.schedules.next,
                        value: _nextLabel(state),
                        onTap: state.halves
                            ? null
                            : () => unawaited(_pickNext(context)),
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
                const SizedBox(height: BirkaTokens.spaceLg),
                SectionLabel(
                  t.schedules.remindSection,
                  color: colors.textMuted,
                ),
                const SizedBox(height: BirkaTokens.spaceXs),
                ChipSwitch<ScheduleReminder>(
                  options: {
                    for (final reminder in ScheduleReminder.values)
                      reminder:
                          t.schedules.reminder[reminder.name] ?? reminder.name,
                  },
                  selected: state.reminder,
                  onChanged: cubit.reminderChanged,
                ),
                const SizedBox(height: BirkaTokens.spaceXs),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BirkaTokens.spaceXxs,
                  ),
                  child: FadingText(
                    reminderLine(
                      schedule: state.schedule,
                      settings: state.reminders,
                      now: _now(state.today),
                    ),
                    style: styles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                // A payment that is to remind while the reminders are off
                // offers to turn them on.
                AnimatedColumn(
                  children: [
                    if (onEnableReminders case final enable?
                        when state.reminder != ScheduleReminder.none &&
                            !(state.reminders?.any ?? true))
                      Align(
                        key: const ValueKey('enable'),
                        alignment: Alignment.centerLeft,
                        child: AccentLink(
                          label: t.schedules.remindEnable,
                          onTap: enable,
                        ),
                      ),
                  ],
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
                          date: state.nextIsAdvance
                              ? t.schedules.nextAdvance(
                                  date: fullDate(state.next, state.today),
                                )
                              : fullDate(state.next, state.today),
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

  /// `аванс, 20 ноября, пт` or `5 декабря, сб`.
  static String _nextLabel(ScheduleFormState state) {
    final date =
        '${fullDate(state.next, state.today)}, ${weekdayLabel(state.next)}';
    return state.nextIsAdvance ? t.schedules.nextAdvance(date: date) : date;
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

  /// Picks the day of the advance, or of the rest, of a salary in halves
  /// from a date of the month.
  Future<void> _pickDay(BuildContext context, {required bool advance}) async {
    final cubit = context.read<ScheduleFormCubit>();
    final today = state.today;
    final day = advance ? state.advanceDay ?? state.day : state.day;
    final initial = CivilDate.onDay(today.year, today.month, day);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(today.year, today.month),
      lastDate: DateTime(today.year, today.month + 2, 0),
    );
    if (picked == null) return;
    advance
        ? cubit.advanceDayChanged(picked.day)
        : cubit.nextChanged(CivilDate.of(picked));
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
    final part = state.part;
    final advance = state.advanceAmount;
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
            FadingText(
              (state.halves ? t.schedules.amountMonthly : t.schedules.amount)
                  .toUpperCase(),
              style: styles.label.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: BirkaTokens.spaceXxs),
            AmountText(
              text,
              alwaysShown: true,
              tone: state.kind == TransactionKind.income
                  ? AmountTone.positive
                  : AmountTone.neutral,
              style: styles.display,
            ),
            AnimatedColumn(
              children: [
                if (state.halves && state.amountMinor > 0)
                  Center(
                    key: const ValueKey('halves'),
                    child: FadingText(
                      switch ((part, advance)) {
                        (final part?, final advance?) when state.ownAdvance =>
                          HiddenAmounts.mask(
                            context,
                            t.schedules.halvesOwn(
                              advance: formatMoney(advance),
                              rest: formatMoney(part),
                            ),
                          ),
                        (final part?, _) => HiddenAmounts.mask(
                          context,
                          t.schedules.halves(amount: formatMoney(part)),
                        ),
                        _ => t.schedules.halvesUneven,
                      },
                      textAlign: TextAlign.center,
                      style: styles.caption.copyWith(
                        color: part == null
                            ? colors.negative
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                if (_range(state) case final range?)
                  Center(
                    key: const ValueKey('range'),
                    child: Text(
                      HiddenAmounts.mask(context, range),
                      textAlign: TextAlign.center,
                      style: styles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
              ],
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
      label: state.halves ? t.schedules.amountMonthly : t.schedules.amount,
      done: t.schedules.done,
      initial: amount.isZero ? '' : typedAmount(amount),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    if (typed == null) return;
    final money = amountTyped(typed, amount.currency);
    if (money != null) cubit.amountChanged(money.minorUnits);
  }
}

/// What the amount of a payment made from the operations that came every
/// month says while it is the last of their amounts, which changed:
/// `последняя сумма · бывало от 6 410 ₽ до 7 120 ₽`.
String? _range(ScheduleFormState state) {
  final found = state.found;
  if (found == null || !found.varies) return null;
  if (state.amountMinor != found.amounts.last.minorUnits) return null;
  final range = found.range;
  return t.schedules.amountRange(
    min: formatMoney(range.min),
    max: formatMoney(range.max),
  );
}

/// The operation that a new payment is made from, over the form, as the
/// board draws it: its day, what it was called, its amount and category. The
/// latest of the operations that came every month gives their days instead.
class _MadeFrom extends StatelessWidget {
  const _MadeFrom({required this.made, required this.state});

  final Transaction made;
  final ScheduleFormState state;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final categoryId = made.allocations.firstOrNull?.categoryId;
    final category = [
      ...state.expenses,
      ...state.incomes,
    ].where((it) => it.id == categoryId).firstOrNull;
    final found = state.found;
    return GlassSurface(
      child: Row(
        children: [
          GlyphBadge(glyph: BirkaGlyph.repeat, color: colors.accent),
          const SizedBox(width: BirkaTokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (found) {
                    final found? => t.schedules.foundIn(
                      n: found.times.length,
                      count: formatCount(found.times.length),
                    ),
                    null => t.schedules.fromOperation(
                      date: fullDate(made.occurredOn, state.today),
                    ),
                  },
                  style: styles.bodyStrong.copyWith(color: colors.text),
                ),
                Text(
                  switch (found) {
                    final found? => findDaysLine(
                      found,
                      category: category?.name,
                    ),
                    null => HiddenAmounts.mask(
                      context,
                      madeFromLine(made, category: category?.name),
                    ),
                  },
                  maxLines: found == null ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: styles.caption.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How an income comes: in one sum, or in halves, an advance and the rest.
class _Parts extends StatelessWidget {
  const _Parts({required this.state});

  final ScheduleFormState state;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final advance = state.advanceDay;
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Caption(t.schedules.partsTitle),
          ChipSwitch<bool>(
            options: {
              false: t.schedules.parts['one'] ?? '',
              true: t.schedules.parts['two'] ?? '',
            },
            selected: state.halves,
            onChanged: (halves) =>
                context.read<ScheduleFormCubit>().halvesChanged(halves: halves),
          ),
          const SizedBox(height: BirkaTokens.spaceSm),
          FadingText(
            switch ((advance, state.advanceAmount, state.part)) {
              (final advance?, final own?, final rest?) when state.ownAdvance =>
                HiddenAmounts.mask(
                  context,
                  t.schedules.partsOwn(
                    advanceAmount: formatMoney(own),
                    advance: advance,
                    restAmount: formatMoney(rest),
                    day: state.day,
                  ),
                ),
              (final advance?, _, _) when state.halves => t.schedules.partsTwo(
                advance: advance,
                day: state.day,
              ),
              _ => t.schedules.partsOne,
            },
            style: styles.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
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
  const _Line({
    required this.label,
    required this.value,
    this.onTap,
    this.quiet = false,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  /// Whether the value is a default rather than what the person set, such
  /// as «половина» of an advance.
  final bool quiet;

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
              // The old value and the new one share the width while they
              // cross-fade, so neither may push the row past its edge.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: FadingText(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.bodyStrong.copyWith(
                    color: quiet ? colors.textMuted : colors.text,
                  ),
                ),
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

/// The sum of the advance of a salary in halves, as the board of the advance
/// draws it: «половина» until the person gives it a sum of its own in a
/// sheet, which says what the salary brings then and offers the half back.
class _AdvanceAmount extends StatelessWidget {
  const _AdvanceAmount({required this.state, super.key});

  final ScheduleFormState state;

  @override
  Widget build(BuildContext context) {
    final advance = state.advanceAmount;
    final value = state.ownAdvance && advance != null
        ? HiddenAmounts.mask(context, formatMoney(advance))
        : t.schedules.advanceHalf;
    return _Lit(
      value: value,
      child: _Line(
        label: t.schedules.advanceAmount,
        value: value,
        quiet: !state.ownAdvance,
        onTap: state.amount == null ? null : () => unawaited(_edit(context)),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<ScheduleFormCubit>();
    final month = state.amount;
    if (month == null) return;
    final half = state.half;
    final own = state.ownAdvance ? state.advanceAmount : null;
    String mask(String text) => HiddenAmounts.mask(context, text);
    final typed = await showFieldSheet(
      context,
      label: t.schedules.advanceAmount,
      done: t.schedules.done,
      initial: own == null ? '' : typedAmount(own),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      suffix: currencySign(month.currency),
      // What the salary brings after the advance that is typed, or after half.
      note: (text) {
        final typed = amountTyped(text, month.currency);
        final advance = typed == null || typed.isZero ? half : typed;
        final rest = advance == null ? null : month - advance;
        return rest == null || !rest.isPositive
            ? ''
            : mask(
                t.schedules.advanceRest(
                  amount: formatMoney(rest),
                  day: state.day,
                ),
              );
      },
      suggestion: half == null
          ? null
          : (
              label: mask(
                t.schedules.advanceHalfChip(amount: formatMoney(half)),
              ),
              value: typedAmount(half),
            ),
    );
    if (typed == null) return;
    final money = amountTyped(typed, month.currency);
    if (money == null) return;
    cubit.advanceAmountChanged(money.isZero ? null : money.minorUnits);
  }
}

/// Lights its row up for a moment when [value] changes, as an edited row of
/// a list does, so that the row says the sheet changed it.
class _Lit extends StatefulWidget {
  const _Lit({required this.value, required this.child});

  final String value;
  final Widget child;

  @override
  State<_Lit> createState() => _LitState();
}

class _LitState extends State<_Lit> {
  bool _lit = false;
  Timer? _timer;

  @override
  void didUpdateWidget(_Lit old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value || BirkaMotion.reduced(context)) return;
    _timer?.cancel();
    setState(() => _lit = true);
    _timer = Timer(BirkaMotion.slow * 2, () {
      if (mounted) setState(() => _lit = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = BirkaColors.of(context).accent;
    return AnimatedContainer(
      duration: BirkaMotion.slow,
      curve: BirkaMotion.fadeCurve,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: _lit ? 0.10 : 0),
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusSm),
        ),
      ),
      child: widget.child,
    );
  }
}

/// This moment of the day, on [today] of the form, which a test may set.
DateTime _now(CivilDate today) {
  final clock = DateTime.now();
  return DateTime(today.year, today.month, today.day, clock.hour, clock.minute);
}
