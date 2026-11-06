import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_flutter/src/presentation/widgets/schedule_bits.dart';

/// The money until the salary (ADR 0023): how much each day may take, with
/// the sum that gives it in the open, until when it counts, on which
/// accounts and with how much aside.
///
/// It needs a [SchedulesCubit] above it.
class PaydayPage extends StatelessWidget {
  /// Creates the page.
  const PaydayPage({
    required this.onBack,
    required this.onOpenSalary,
    required this.onAddSalary,
    super.key,
  });

  /// Called by the way back.
  final VoidCallback onBack;

  /// Opens the form of the regular income that sets the payday, by its id.
  final ValueChanged<String> onOpenSalary;

  /// Opens the form of a new salary.
  final VoidCallback onAddSalary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<SchedulesCubit, SchedulesState>(
            builder: (context, state) => ListView(
              padding: const EdgeInsets.fromLTRB(
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXs,
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXxl,
              ),
              children: [
                BackHeader(
                  label: t.schedules.paydayTitle,
                  backLabel: t.schedules.back,
                  onBack: onBack,
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                ...switch (state) {
                  SchedulesLoaded(:final view) when view.base != null =>
                    _content(context, view),
                  SchedulesFailed() => [
                    BirkaButton(
                      label: t.app.retry,
                      onPressed: () =>
                          unawaited(context.read<SchedulesCubit>().retry()),
                    ),
                  ],
                  _ => const <Widget>[],
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, SchedulesView view) {
    final cubit = context.read<SchedulesCubit>();
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final base = view.base!;
    final salary = view.salary;
    final aside = Money(view.settings.asideMinor, base);
    return [
      switch (view.plan) {
        final plan? => _Sum(plan: plan),
        null => TintedNotice(
          color: colors.accent,
          title: t.schedules.noPaydayTitle,
          text: t.schedules.noPaydayText,
        ),
      },
      const SizedBox(height: BirkaTokens.spaceLg),
      GlassSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: BirkaTokens.spaceXs),
              child: Text(
                t.schedules.countUntil,
                style: styles.caption.copyWith(color: colors.textMuted),
              ),
            ),
            ChipSwitch<SpendUntil>(
              options: {
                for (final until in SpendUntil.values)
                  until: t.schedules.until[until.name] ?? until.name,
              },
              selected: view.settings.until,
              onChanged: (until) => unawaited(cubit.countUntil(until)),
            ),
            // The payday matters only while the money counts until it.
            AnimatedColumn(
              children: [
                if (view.settings.until == SpendUntil.payday)
                  Padding(
                    key: const ValueKey('payday'),
                    padding: const EdgeInsets.only(top: BirkaTokens.spaceSm),
                    child: GlassListRow(
                      title: t.schedules.payday,
                      subtitle: salary == null
                          ? t.schedules.paydayNone
                          : t.schedules.paydayFrom(name: salary.name),
                      trailing: salary == null
                          ? BirkaIcon(
                              BirkaGlyph.plus,
                              size: 16,
                              color: colors.accent,
                            )
                          : Text(
                              t.schedules.paydayDay(day: salary.day),
                              style: styles.bodyStrong.copyWith(
                                color: colors.text,
                              ),
                            ),
                      onTap: salary == null
                          ? onAddSalary
                          : () => onOpenSalary(salary.id),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: BirkaTokens.spaceLg),
      SectionLabel(t.schedules.accountsTitle, color: colors.textMuted),
      const SizedBox(height: BirkaTokens.spaceXs),
      GlassListGroup(
        children: [
          for (final it in view.countable)
            GlassListRow(
              key: ValueKey(it.row.account.id),
              title: it.row.account.name,
              subtitle: it.locked
                  ? t.schedules.otherCurrency
                  : HiddenAmounts.mask(
                      context,
                      [
                        if (it.row.account.lastDigits case final digits?)
                          '••$digits',
                        formatMoney(it.row.balance),
                      ].join(' · '),
                    ),
              trailing: Semantics(
                label: t.schedules.count(name: it.row.account.name),
                child: Switch(
                  value: it.counted,
                  onChanged: it.locked
                      ? null
                      : (counted) => unawaited(
                          cubit.count(it.row.account.id, counted: counted),
                        ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: BirkaTokens.spaceLg),
      GlassListGroup(
        children: [
          GlassListRow(
            title: t.schedules.asideRow,
            subtitle: t.schedules.asideNote,
            trailing: Text(
              HiddenAmounts.mask(context, formatMoney(aside)),
              style: styles.bodyStrong.copyWith(color: colors.text),
            ),
            onTap: () => unawaited(_keepAside(context, aside)),
          ),
        ],
      ),
    ];
  }

  Future<void> _keepAside(BuildContext context, Money aside) async {
    final cubit = context.read<SchedulesCubit>();
    final typed = await showFieldSheet(
      context,
      label: t.schedules.aside,
      done: t.schedules.done,
      initial: aside.isZero ? '' : typedAmount(aside),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    if (typed == null) return;
    final money = amountTyped(typed, aside.currency);
    if (money != null) await cubit.keepAside(money);
  }
}

/// How much each day may take, and the sum that gives it.
class _Sum extends StatelessWidget {
  const _Sum({required this.plan});

  final SpendingPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final free = plan.free;
    final payday = plan.until == SpendUntil.payday;
    final count = plan.payments.length;
    return TintedBox(
      color: colors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountText(
            free.isPositive
                ? t.schedules.perDay(amount: formatMoney(plan.perDay))
                : t.schedules.notEnough(amount: formatMoney(free.abs())),
            value: free.isPositive ? plan.perDay.minorUnits : free.minorUnits,
            rise: AmountRise.good,
            tone: free.isPositive ? AmountTone.neutral : AmountTone.negative,
            style: styles.hero,
          ),
          FadingText(
            planPeriodLabel(plan),
            style: styles.caption.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          _Line(label: t.schedules.morning, amount: plan.morning),
          _Line(
            label: payday
                ? t.schedules.paymentsUntilPayday(n: count)
                : t.schedules.paymentsUntilMonth(n: count),
            amount: -plan.paid,
          ),
          _Line(label: t.schedules.aside, amount: -plan.aside),
          const SizedBox(height: BirkaTokens.spaceXs),
          SizedBox(height: 1, child: ColoredBox(color: colors.hairline)),
          const SizedBox(height: BirkaTokens.spaceXs),
          _Line(
            label: t.schedules.leftFor(n: plan.days),
            amount: free,
            strong: true,
          ),
        ],
      ),
    );
  }
}

/// A line of the sum: what it is, and its amount, which rolls when it
/// changes.
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.amount, this.strong = false});

  final String label;
  final Money amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final style = strong ? styles.bodyStrong : styles.body;
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          Expanded(
            child: FadingText(
              label,
              style: style.copyWith(
                color: strong ? colors.text : colors.textSecondary,
              ),
            ),
          ),
          AmountText(
            formatMoney(amount),
            value: amount.minorUnits,
            rise: AmountRise.good,
            tone: strong && amount.isNegative
                ? AmountTone.negative
                : AmountTone.neutral,
            style: styles.bodyStrong,
          ),
        ],
      ),
    );
  }
}
