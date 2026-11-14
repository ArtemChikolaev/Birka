import 'package:debts_common/debts_common.dart';
import 'package:debts_flutter/src/presentation/widgets/debt_badge.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';

/// The list of debts (ADR 0029): what others owe the person and what the
/// person owes, each added up, and the settled debts in a fold.
///
/// It needs a [DebtsCubit] above it.
class DebtsPage extends StatefulWidget {
  /// Creates the page.
  const DebtsPage({
    required this.onBack,
    required this.onAdd,
    required this.onOpen,
    super.key,
  });

  /// Called by the way back.
  final VoidCallback onBack;

  /// Opens the form of a new debt.
  final VoidCallback onAdd;

  /// Opens the card of a debt, by its id.
  final ValueChanged<String> onOpen;

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  var _closedOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<DebtsCubit, DebtsState>(
            builder: (context, state) => ListView(
              padding: const EdgeInsets.fromLTRB(
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXs,
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXxl,
              ),
              children: [
                BackHeader(
                  label: t.debts.title,
                  backLabel: t.debts.toMore,
                  onBack: widget.onBack,
                  trailing: GlassIconButton(
                    glyph: BirkaGlyph.plus,
                    label: t.debts.newDebt,
                    onPressed: widget.onAdd,
                  ),
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                ...switch (state.status) {
                  DebtsStatus.loading => const <Widget>[],
                  DebtsStatus.failed => [const _Failure()],
                  DebtsStatus.ready when state.isEmpty => [
                    _Empty(onAdd: widget.onAdd),
                  ],
                  DebtsStatus.ready => _sections(context, state),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context, DebtsState state) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    const gap = SizedBox(height: BirkaTokens.spaceLg);
    const small = SizedBox(height: BirkaTokens.spaceXs);
    final closed = state.closed;
    return [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Total(
                label: t.debts.owedToMe,
                amount: state.owedTotal,
                people: state.owed.length,
                tone: AmountTone.positive,
                base: state.base,
              ),
            ),
            const SizedBox(width: BirkaTokens.spaceSm),
            Expanded(
              child: _Total(
                label: t.debts.myDebts,
                amount: state.mineTotal,
                people: state.mine.length,
                tone: AmountTone.neutral,
                base: state.base,
              ),
            ),
          ],
        ),
      ),
      for (final (title, debts, owed) in [
        (t.debts.owedToMe, state.owed, true),
        (t.debts.myDebts, state.mine, false),
      ])
        if (debts.isNotEmpty) ...[
          gap,
          SectionLabel(title),
          small,
          GlassListGroup(
            children: [
              for (final debt in debts)
                _DebtRow(
                  key: ValueKey(debt.id),
                  debt: debt,
                  state: state,
                  tone: owed ? AmountTone.positive : AmountTone.neutral,
                  onTap: () => widget.onOpen(debt.id),
                ),
            ],
          ),
        ],
      if (closed.isNotEmpty) ...[
        gap,
        Semantics(
          button: true,
          expanded: _closedOpen,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _closedOpen = !_closedOpen),
            child: Row(
              children: [
                SectionLabel(t.debts.closed(n: closed.length)),
                const SizedBox(width: BirkaTokens.spaceXxs),
                AnimatedRotation(
                  turns: _closedOpen ? 0.25 : 0,
                  duration: BirkaMotion.reduced(context)
                      ? Duration.zero
                      : BirkaMotion.base,
                  curve: BirkaMotion.standardCurve,
                  child: BirkaIcon(
                    BirkaGlyph.chevron,
                    size: 16,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: BirkaMotion.reduced(context)
              ? Duration.zero
              : BirkaMotion.base,
          curve: BirkaMotion.standardCurve,
          alignment: Alignment.topCenter,
          child: _closedOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: BirkaTokens.spaceXs),
                  child: GlassListGroup(
                    children: [
                      for (final debt in closed)
                        _DebtRow(
                          key: ValueKey(debt.id),
                          debt: debt,
                          state: state,
                          tone: AmountTone.muted,
                          onTap: () => widget.onOpen(debt.id),
                        ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
      gap,
      Text(
        state.hasOtherCurrencies ? t.debts.captionRates : t.debts.caption,
        style: styles.caption.copyWith(color: colors.textMuted),
      ),
    ];
  }
}

/// What others owe, or what the person owes, added up, and how many people.
class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.amount,
    required this.people,
    required this.tone,
    required this.base,
  });

  final String label;
  final Money? amount;
  final int people;
  final AmountTone tone;
  final Currency base;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final shown = amount ?? Money.zero(base);
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: styles.caption.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: BirkaTokens.spaceXxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AmountText(
              amount == null ? '—' : formatMoney(shown),
              value: shown.minorUnits,
              tone: people == 0 ? AmountTone.neutral : tone,
              style: styles.heading,
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceXxs),
          FadingText(
            t.debts.people(n: people),
            style: styles.caption.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// A debt in the list: the person, its day, what is left and of what.
class _DebtRow extends StatelessWidget {
  const _DebtRow({
    required this.debt,
    required this.state,
    required this.tone,
    required this.onTap,
    super.key,
  });

  final Debt debt;
  final DebtsState state;
  final AmountTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final line = debtLine(debt, today: state.today);
    final note = debtAmountNote(debt, state);
    final shown = debt.closed ? debt.total : debt.left;
    return GlassListRow(
      leading: DebtBadge(debt.account),
      title: debt.name,
      subtitle: line.text,
      subtitleColor: debtToneColor(context, line.tone),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              AmountText(
                debtAmount(shown),
                value: shown.minorUnits,
                tone: tone,
                style: styles.bodyStrong,
              ),
              if (note != null)
                Text(
                  HiddenAmounts.mask(context, note),
                  style: styles.caption.copyWith(color: colors.textMuted),
                ),
            ],
          ),
          const SizedBox(width: BirkaTokens.spaceXs),
          BirkaIcon(BirkaGlyph.chevron, size: 16, color: colors.textMuted),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure();

  @override
  Widget build(BuildContext context) => Text(
    t.debts.failed,
    textAlign: TextAlign.center,
    style: BirkaTextStyles.of(
      context,
    ).body.copyWith(color: BirkaColors.of(context).negative),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: BirkaTokens.spaceXxl),
      child: Column(
        children: [
          ExcludeSemantics(
            child: GlyphBadge(
              glyph: BirkaGlyph.people,
              color: colors.accent,
              size: 72,
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          Text(
            t.debts.emptyTitle,
            textAlign: TextAlign.center,
            style: styles.heading.copyWith(color: colors.text),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            t.debts.emptyText,
            textAlign: TextAlign.center,
            style: styles.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          SizedBox(
            width: double.infinity,
            child: BirkaButton(label: t.debts.add, onPressed: onAdd),
          ),
        ],
      ),
    );
  }
}
