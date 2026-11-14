import 'package:debts_common/debts_common.dart';
import 'package:debts_flutter/src/presentation/widgets/debt_badge.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// The card of a debt (ADR 0029): what is left of what, the bar of what came
/// back, its day, the return and more money, and its steps.
///
/// It needs a [DebtsCubit] above it. A debt that goes takes the page back.
class DebtPage extends StatelessWidget {
  /// Creates the card of debt [id].
  const DebtPage({
    required this.id,
    required this.onBack,
    required this.onEdit,
    required this.onReturn,
    required this.onMore,
    required this.onOpenStep,
    super.key,
  });

  /// The debt.
  final String id;

  /// Called by the way back, and when the debt is gone.
  final VoidCallback onBack;

  /// Opens the form of the terms of the debt.
  final VoidCallback onEdit;

  /// Opens the form of a return.
  final VoidCallback onReturn;

  /// Opens the form of more money on the debt.
  final VoidCallback onMore;

  /// Opens the operation of a step, by its id.
  final ValueChanged<String> onOpenStep;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocConsumer<DebtsCubit, DebtsState>(
            listenWhen: (before, now) =>
                before.debt(id) != null && now.debt(id) == null,
            listener: (context, state) => onBack(),
            builder: (context, state) {
              final debt = state.debt(id);
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  BirkaTokens.spaceLg,
                  BirkaTokens.spaceXs,
                  BirkaTokens.spaceLg,
                  BirkaTokens.spaceXxl,
                ),
                children: [
                  BackHeader(
                    label: t.debts.card.title,
                    backLabel: t.debts.title,
                    onBack: onBack,
                    trailing: debt == null
                        ? null
                        : BirkaChip(
                            label: t.debts.card.edit,
                            selected: false,
                            onTap: onEdit,
                          ),
                  ),
                  const SizedBox(height: BirkaTokens.spaceLg),
                  if (state.status == DebtsStatus.failed)
                    Text(
                      t.debts.failed,
                      textAlign: TextAlign.center,
                      style: BirkaTextStyles.of(
                        context,
                      ).body.copyWith(color: BirkaColors.of(context).negative),
                    ),
                  if (state.status == DebtsStatus.ready && debt == null)
                    Text(
                      t.debts.gone,
                      textAlign: TextAlign.center,
                      style: BirkaTextStyles.of(
                        context,
                      ).body.copyWith(color: BirkaColors.of(context).textMuted),
                    ),
                  if (debt != null) ..._card(context, debt, state.today),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _card(BuildContext context, Debt debt, CivilDate today) {
    const gap = SizedBox(height: BirkaTokens.spaceLg);
    final lent = debt.side == DebtSide.lent;
    return [
      _Summary(debt: debt, today: today),
      gap,
      _Settled(debt: debt, today: today),
      const SizedBox(height: BirkaTokens.spaceMd),
      Row(
        children: [
          Expanded(
            child: GlassActionTile(
              glyph: lent ? BirkaGlyph.download : BirkaGlyph.upload,
              label: lent
                  ? t.debts.card.returnAction
                  : t.debts.card.repayAction,
              accent: !debt.closed,
              onTap: debt.closed ? null : onReturn,
            ),
          ),
          const SizedBox(width: BirkaTokens.spaceSm),
          Expanded(
            child: GlassActionTile(
              glyph: BirkaGlyph.plus,
              label: debt.closed
                  ? t.debts.card.newDebt
                  : lent
                  ? t.debts.card.lendMore
                  : t.debts.card.borrowMore,
              onTap: onMore,
            ),
          ),
        ],
      ),
      gap,
      SectionLabel(t.debts.card.history),
      const SizedBox(height: BirkaTokens.spaceXs),
      GlassListGroup(
        children: [
          for (final step in debt.steps)
            _StepRow(
              key: ValueKey(step.transactionId),
              step: step,
              today: today,
              onTap: () => onOpenStep(step.transactionId),
            ),
        ],
      ),
    ];
  }
}

/// The person, what is left and of what.
class _Summary extends StatelessWidget {
  const _Summary({required this.debt, required this.today});

  final Debt debt;
  final CivilDate today;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final reduced = BirkaMotion.reduced(context);
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            DebtBadge(debt.account, size: 72),
            Positioned(
              right: -6,
              bottom: -6,
              // A settled debt gets a check on the corner of its person.
              child: AnimatedScale(
                scale: debt.closed || reduced ? 1 : 0.4,
                duration: reduced ? Duration.zero : BirkaMotion.slow,
                curve: BirkaMotion.springCurve,
                child: AnimatedOpacity(
                  opacity: debt.closed ? 1 : 0,
                  duration: BirkaMotion.fast,
                  curve: BirkaMotion.fadeCurve,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.background, width: 3),
                    ),
                    alignment: Alignment.center,
                    child: BirkaIcon(
                      BirkaGlyph.check,
                      size: 14,
                      color: colors.onAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BirkaTokens.spaceMd),
        Text(
          debt.name,
          textAlign: TextAlign.center,
          style: styles.heading.copyWith(color: colors.text),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AmountText(
            debtAmount(debt.left),
            value: debt.left.minorUnits,
            style: styles.display.copyWith(color: colors.text),
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        FadingText(
          debtLeftLine(debt, today: today),
          textAlign: TextAlign.center,
          style: styles.body.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

/// What came back, as a bar that grows, and the day of the debt.
class _Settled extends StatelessWidget {
  const _Settled({required this.debt, required this.today});

  final Debt debt;
  final CivilDate today;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final reduced = BirkaMotion.reduced(context);
    final due = debtDueLine(debt, today: today, reminders: true);
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: FadingText(
                  HiddenAmounts.mask(context, debtSettledTitle(debt)),
                  style: styles.bodyStrong.copyWith(color: colors.text),
                ),
              ),
              FadingText(
                debtShare(debt),
                style: styles.caption.copyWith(color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceSm),
          // The bar grows from nothing to its share over duration.roll, and
          // stands at it at once with less motion.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduced ? debt.share : 0, end: debt.share),
            duration: reduced ? Duration.zero : BirkaMotion.roll,
            curve: BirkaMotion.standardCurve,
            builder: (context, share, _) => ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: SizedBox(
                height: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: colors.surfaceRaised),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: share.clamp(0, 1),
                      child: ColoredBox(color: colors.accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceSm),
          Row(
            children: [
              BirkaIcon(
                debt.reminds && !debt.closed
                    ? BirkaGlyph.bell
                    : BirkaGlyph.calendar,
                size: 16,
                color: debtToneColor(context, due.tone),
              ),
              const SizedBox(width: BirkaTokens.spaceXs),
              Expanded(
                child: FadingText(
                  due.text,
                  style: styles.body.copyWith(
                    color: debtToneColor(context, due.tone),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A step of the debt: what it did, its day and account, and what it did to
/// the account of the person.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.today,
    required this.onTap,
    super.key,
  });

  final DebtStep step;
  final CivilDate today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final coming = step.onAccount.isPositive;
    return GlassListRow(
      leading: ExcludeSemantics(
        child: GlyphBadge(
          glyph: coming ? BirkaGlyph.download : BirkaGlyph.upload,
          color: step.move.settles ? colors.accent : colors.textSecondary,
        ),
      ),
      title: debtStepTitle(step),
      subtitle: debtStepLine(step, today: today),
      subtitleLines: 2,
      trailing: AmountText(
        debtStepAmount(step),
        value: step.onAccount.minorUnits,
        tone: step.move.settles ? AmountTone.positive : AmountTone.neutral,
        style: styles.bodyStrong,
      ),
      onTap: onTap,
    );
  }
}
